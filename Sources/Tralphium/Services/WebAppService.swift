import AppKit
import Foundation
import TralphiumCore

/// Service to create and manage standalone Chrome OS-style Web Applications powered by Helium.
public enum WebAppService {

    /// Finds the installed path of Helium.app.
    public static func findHeliumPath() -> String? {
        let candidates = [
            "/Applications/Helium.app",
            NSHomeDirectory() + "/Applications/Helium.app"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "net.imput.helium") {
            return url.path
        }
        return nil
    }

    /// Derives a clean application display name from a URL or domain.
    public static func deriveName(from urlString: String) -> String {
        guard let url = URL(string: urlString.contains("://") ? urlString : "https://" + urlString),
              let host = url.host else {
            return "WebApp"
        }
        var parts = host.lowercased().split(separator: ".")
        if parts.count > 2 && ["www", "web", "app", "mail", "m"].contains(parts.first!) {
            parts.removeFirst()
        }
        let raw = String(parts.first ?? "WebApp")
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    /// Creates a native macOS `.app` bundle in `~/Applications` configured as a standalone Helium webapp.
    @discardableResult
    public static func create(
        url rawURL: String,
        name customName: String? = nil,
        launchAfterCreation: Bool = true
    ) async -> URL? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedURL = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let targetURL = URL(string: normalizedURL),
              let host = targetURL.host, !host.isEmpty else {
            return nil
        }

        // Determine application name
        var appName = customName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if appName.isEmpty {
            appName = await fetchPageTitle(for: targetURL) ?? deriveName(from: normalizedURL)
        }
        // Sanitize name for filesystem
        let cleanName = appName.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let fm = FileManager.default
        let userApps = NSHomeDirectory() + "/Applications"
        try? fm.createDirectory(atPath: userApps, withIntermediateDirectories: true)

        let appPath = "\(userApps)/\(cleanName).app"
        let contentsPath = "\(appPath)/Contents"
        let macosPath = "\(contentsPath)/MacOS"
        let resourcesPath = "\(contentsPath)/Resources"

        do {
            try fm.createDirectory(atPath: macosPath, withIntermediateDirectories: true)
            try fm.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        // Determine Helium executable path
        let heliumPath = findHeliumPath() ?? "/Applications/Helium.app"

        // Create executable launcher
        let launcherPath = "\(macosPath)/launcher"
        let launcherScript = """
        #!/bin/bash
        exec "\(heliumPath)/Contents/MacOS/Helium" --app="\(normalizedURL)" "$@"
        """
        try? launcherScript.write(toFile: launcherPath, atomically: true, encoding: .utf8)
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcherPath)

        // Generate bundle identifier
        let safeIdentifierSuffix = cleanName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let bundleID = "net.imput.helium.webapp.\(safeIdentifierSuffix.isEmpty ? "app" : safeIdentifierSuffix)"

        // Generate Info.plist
        let plistDict: [String: Any] = [
            "CFBundleDevelopmentRegion": "en",
            "CFBundleDisplayName": cleanName,
            "CFBundleExecutable": "launcher",
            "CFBundleIconFile": "AppIcon",
            "CFBundleIdentifier": bundleID,
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleName": cleanName,
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "LSMinimumSystemVersion": "14.0"
        ]
        if let plistData = try? PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0) {
            try? plistData.write(to: URL(fileURLWithPath: "\(contentsPath)/Info.plist"))
        }

        // Fetch and install icon
        let iconDest = "\(resourcesPath)/AppIcon.icns"
        await installIcon(for: host, destination: iconDest, fallbackHelium: heliumPath)

        // Ad-hoc codesign
        let codesignProcess = Process()
        codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesignProcess.arguments = ["-f", "-s", "-", appPath]
        try? codesignProcess.run()
        codesignProcess.waitUntilExit()

        // Notify AppCatalog to refresh and launch if requested
        await MainActor.run {
            AppCatalog.shared.refresh()
            if launchAfterCreation {
                Launch.app(at: appPath)
            }
        }

        return URL(fileURLWithPath: appPath)
    }

    private static func fetchPageTitle(for url: URL) async -> String? {
        var req = URLRequest(url: url)
        req.timeoutInterval = 2.5
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data.prefix(16384), encoding: .utf8) else {
            return nil
        }

        if let range = html.range(of: "(?i)<title>([^<]+)</title>", options: .regularExpression) {
            let tag = String(html[range])
            let title = tag.replacingOccurrences(of: "(?i)</?title>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let clean = title.components(separatedBy: " - ").first?
                .components(separatedBy: " | ").first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let clean, !clean.isEmpty, clean.count <= 28 {
                return clean
            }
        }
        return nil
    }

    private static func installIcon(for domain: String, destination: String, fallbackHelium: String) async {
        let sources = [
            "https://www.google.com/s2/favicons?domain=\(domain)&sz=256",
            "https://icon.horse/icon/\(domain)"
        ]

        var downloadedData: Data?
        for src in sources {
            guard let url = URL(string: src) else { continue }
            var req = URLRequest(url: url)
            req.timeoutInterval = 3
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               (resp as? HTTPURLResponse)?.statusCode == 200,
               data.count > 400 {
                downloadedData = data
                break
            }
        }

        if let data = downloadedData {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let pngFile = tempDir.appendingPathComponent("icon.png")
            let iconsetDir = tempDir.appendingPathComponent("icon.iconset")

            do {
                try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
                try data.write(to: pngFile)

                // Render Apple standard iconset sizes
                let sizes: [(Int, String)] = [
                    (16, "icon_16x16.png"),
                    (32, "icon_16x16@2x.png"),
                    (32, "icon_32x32.png"),
                    (64, "icon_32x32@2x.png"),
                    (128, "icon_128x128.png"),
                    (256, "icon_128x128@2x.png"),
                    (256, "icon_256x256.png"),
                    (512, "icon_256x256@2x.png"),
                    (512, "icon_512x512.png"),
                    (1024, "icon_512x512@2x.png")
                ]

                for (sz, filename) in sizes {
                    let outPath = iconsetDir.appendingPathComponent(filename).path
                    let sips = Process()
                    sips.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
                    sips.arguments = ["-z", "\(sz)", "\(sz)", pngFile.path, "--out", outPath]
                    try? sips.run()
                    sips.waitUntilExit()
                }

                let iconutil = Process()
                iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
                iconutil.arguments = ["-c", "icns", iconsetDir.path, "-o", destination]
                try? iconutil.run()
                iconutil.waitUntilExit()

                try? FileManager.default.removeItem(at: tempDir)
                return
            } catch {
                try? FileManager.default.removeItem(at: tempDir)
            }
        }

        // Fallback: Copy Helium's own app icon
        let heliumIcon = "\(fallbackHelium)/Contents/Resources/app.icns"
        if FileManager.default.fileExists(atPath: heliumIcon) {
            try? FileManager.default.copyItem(atPath: heliumIcon, toPath: destination)
        }
    }
}
