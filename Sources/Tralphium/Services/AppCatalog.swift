import AppKit
import Observation
import TralphiumCore

/// Installed applications, for the launchpad and for resolving taskbar entries.
@MainActor
@Observable
final class AppCatalog {
    static let shared = AppCatalog()

    private(set) var apps: [AppEntry] = []
    @ObservationIgnored private var scanning = false
    @ObservationIgnored private let icons = NSCache<NSString, NSImage>()

    private init() { refresh() }

    /// Scans the application folders off the main thread. Called at start and
    /// whenever the launchpad opens, so new installs show up without watching
    /// the file system.
    func refresh() {
        guard !scanning else { return }
        scanning = true
        Task.detached(priority: .utility) {
            let found = Self.scan()
            await MainActor.run {
                AppCatalog.shared.apps = found
                AppCatalog.shared.scanning = false
            }
        }
    }

    func entry(for bundleID: String) -> AppEntry? {
        apps.first { $0.id.caseInsensitiveCompare(bundleID) == .orderedSame }
            ?? Self.resolve(bundleID: bundleID)
    }

    /// App icon, cached by path.
    func icon(forPath path: String) -> NSImage {
        if let cached = icons.object(forKey: path as NSString) { return cached }
        let image = NSWorkspace.shared.icon(forFile: path)
        image.size = NSSize(width: 64, height: 64)
        icons.setObject(image, forKey: path as NSString)
        return image
    }

    /// App icon resolved by bundle ID.
    func icon(forBundleID bundleID: String) -> NSImage {
        if let entry = entry(for: bundleID) {
            return icon(forPath: entry.path)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return icon(forPath: url.path)
        }
        return NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app")
    }

    /// App display name resolved by bundle ID.
    func name(forBundleID bundleID: String) -> String {
        if let entry = entry(for: bundleID) {
            return entry.name
        }
        if let running = RunningApps.shared.running.first(where: { $0.id.caseInsensitiveCompare(bundleID) == .orderedSame }) {
            return running.name
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            var name = FileManager.default.displayName(atPath: url.path)
            if name.hasSuffix(".app") { name.removeLast(4) }
            return name
        }
        return bundleID
    }

    nonisolated private static let roots: [String] = [
        "/Applications",
        "/System/Applications",
        "/System/Cryptexes/App/System/Applications",
        NSHomeDirectory() + "/Applications",
    ]

    /// `.app` bundles up to two folders deep (Utilities and similar).
    nonisolated private static func scan() -> [AppEntry] {
        let fm = FileManager.default
        var byID: [String: AppEntry] = [:]
        for root in roots {
            guard let walker = fm.enumerator(
                at: URL(fileURLWithPath: root), includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in walker {
                if walker.level > 2 { walker.skipDescendants(); continue }
                guard url.pathExtension == "app", let entry = makeEntry(url) else { continue }
                let key = entry.id.lowercased()
                if byID[key] == nil { byID[key] = entry }
            }
        }
        return Array(byID.values)
    }

    nonisolated private static func makeEntry(_ url: URL) -> AppEntry? {
        guard let id = Bundle(url: url)?.bundleIdentifier else { return nil }
        // Background-only helpers (LSUIElement / LSBackgroundOnly) are not launchable apps.
        let info = Bundle(url: url)?.infoDictionary
        if info?["LSBackgroundOnly"] as? Bool == true { return nil }
        var name = FileManager.default.displayName(atPath: url.path)
        if name.hasSuffix(".app") { name.removeLast(4) }
        return AppEntry(id: id, name: name, path: url.path)
    }

    nonisolated private static func resolve(bundleID: String) -> AppEntry? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return makeEntry(url)
    }
}
