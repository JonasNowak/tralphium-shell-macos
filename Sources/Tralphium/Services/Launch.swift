import AppKit
import Darwin
import TralphiumCore

/// Opening apps, URLs and running the system tools the shell relies on.
@MainActor
enum Launch {
    /// Opens (or activates) an application.
    static func app(at path: String) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: configuration)
    }

    static func app(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        app(at: url.path)
    }

    /// Opens an app by name, like `open -a`.
    static func app(named name: String) {
        run("/usr/bin/open", ["-a", name])
    }

    static func url(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// Starts a tool and does not wait for it.
    static func run(_ path: String, _ arguments: [String], onExit: (@Sendable (Int32) -> Void)? = nil) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        if let onExit {
            process.terminationHandler = { onExit($0.terminationStatus) }
        }
        try? process.run()
    }
}

/// Power and session actions.
@MainActor
enum SessionService {
    static func powerOff() { systemEvents("shut down") }
    static func reboot() { systemEvents("restart") }
    static func signOut() { systemEvents("log out") }

    static func sleep() {
        Launch.run("/usr/bin/pmset", ["sleepnow"])
    }

    /// Locks the screen. Uses the login window's own call when it exists,
    /// otherwise puts the display to sleep (which locks if "require password"
    /// is set to immediately).
    static func lock() {
        typealias Lock = @convention(c) () -> Int32
        let path = "/System/Library/PrivateFrameworks/login.framework/login"
        if let handle = dlopen(path, RTLD_LAZY), let symbol = dlsym(handle, "SACLockScreenImmediate") {
            _ = unsafeBitCast(symbol, to: Lock.self)()
        } else {
            Launch.run("/usr/bin/pmset", ["displaysleepnow"])
        }
    }

    /// Needs the Automation permission for System Events (asked on first use).
    private static func systemEvents(_ verb: String) {
        Launch.run("/usr/bin/osascript", ["-e", "tell application \"System Events\" to \(verb)"])
    }
}

/// Interactive area screenshot: saved to ~/Pictures and copied to the clipboard.
@MainActor
enum ScreenshotService {
    static func take() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        let file = pictures.appendingPathComponent("Screenshot \(formatter.string(from: Date())).png")
        // The selection runs after the control panel has closed.
        Launch.run("/usr/sbin/screencapture", ["-i", file.path]) { _ in
            Task { @MainActor in finish(file) }
        }
    }

    /// Escape in the selection leaves no file, which means nothing to do.
    private static func finish(_ file: URL) {
        guard let image = NSImage(contentsOf: file) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        ToastCenter.shared.show(ToastContent(
            symbol: "camera.viewfinder", title: "Screenshot", message: "Saved and copied to the clipboard."))
    }
}
