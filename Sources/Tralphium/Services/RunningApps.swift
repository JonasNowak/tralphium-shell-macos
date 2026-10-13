import AppKit
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

    func unhide(bundleID: String, inBackground: Bool = true) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        for app in apps {
            _ = app.unhide()
            if !inBackground {
                app.activate()
            }
        }
        reload()
    }

    func hide(bundleID: String) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        for app in apps {
            _ = app.hide()
        }
        reload()
    }

    func unhideAll(inBackground: Bool = true) {
        for item in running where item.isHidden {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: item.id)
            for app in apps {
                _ = app.unhide()
                if !inBackground {
                    app.activate()
                }
            }
        }
        reload()
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
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if front != frontmostID { frontmostID = front }
    }
}
