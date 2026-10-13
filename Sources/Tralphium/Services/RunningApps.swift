import AppKit
import ApplicationServices
import Observation

/// Running regular apps and the frontmost one, driven by NSWorkspace
/// notifications (no polling).
@MainActor
@Observable
final class RunningApps {
    static let shared = RunningApps()

    struct Running: Equatable {
        let id: String
        let name: String
        let path: String
        let isHidden: Bool
    }

    private(set) var running: [Running] = []
    private(set) var frontmostID: String?

    var hiddenApps: [Running] {
        running.filter(\.isHidden)
    }

    private init() {
        reload()
        let center = NSWorkspace.shared.notificationCenter
        let notifications = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification,
        ]
        for name in notifications {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { RunningApps.shared.reload() }
            }
        }
    }

    func isHidden(bundleID: String) -> Bool {
        running.first { $0.id.caseInsensitiveCompare(bundleID) == .orderedSame }?.isHidden ?? false
    }

    func activate(bundleID: String) {
        var apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if apps.isEmpty {
            apps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier?.caseInsensitiveCompare(bundleID) == .orderedSame
            }
        }
        for app in apps {
            app.activate()
            if let bundleURL = app.bundleURL {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
            }
            let pid = app.processIdentifier
            runAppleScript("tell application \"System Events\" to set frontmost of (first process whose unix id is \(pid)) to true")
        }
    }

    func unhide(bundleID: String, inBackground: Bool = true) {
        var apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if apps.isEmpty {
            apps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier?.caseInsensitiveCompare(bundleID) == .orderedSame
            }
        }
        for app in apps {
            let pid = app.processIdentifier
            let axApp = AXUIElementCreateApplication(pid)
            AXUIElementSetAttributeValue(axApp, kAXHiddenAttribute as CFString, kCFBooleanFalse)
            _ = app.unhide()
            runAppleScript("tell application \"System Events\" to set visible of (first process whose unix id is \(pid)) to true")
        }
        if !inBackground {
            activate(bundleID: bundleID)
        }
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.reload()
        }
    }

    func hide(bundleID: String) {
        var apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if apps.isEmpty {
            apps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier?.caseInsensitiveCompare(bundleID) == .orderedSame
            }
        }
        for app in apps {
            let pid = app.processIdentifier
            let axApp = AXUIElementCreateApplication(pid)
            AXUIElementSetAttributeValue(axApp, kAXHiddenAttribute as CFString, kCFBooleanTrue)
            _ = app.hide()
            runAppleScript("tell application \"System Events\" to set visible of (first process whose unix id is \(pid)) to false")
        }
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.reload()
        }
    }

    func unhideAll(inBackground: Bool = true) {
        for item in running where item.isHidden {
            unhide(bundleID: item.id, inBackground: inBackground)
        }
        runAppleScript("tell application \"System Events\" to set visible of every process whose visible is false to true")
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.reload()
        }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> Bool {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        script?.executeAndReturnError(&error)
        if let error {
            NSLog("[RunningApps] AppleScript error: %@", error)
            return false
        }
        return true
    }

    private func reload() {
        let own = Bundle.main.bundleIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != nil && $0.bundleIdentifier != own
        }
        let list = apps.map {
            Running(
                id: $0.bundleIdentifier ?? "",
                name: $0.localizedName ?? "",
                path: $0.bundleURL?.path ?? "",
                isHidden: $0.isHidden
            )
        }
        if list != running { running = list }
        if let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier, front != own {
            if front != frontmostID { frontmostID = front }
        }
    }
}
