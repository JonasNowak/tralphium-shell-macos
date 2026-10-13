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
    }

    private(set) var running: [Running] = []
    private(set) var frontmostID: String?

    private init() {
        reload()
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification,
                     NSWorkspace.didActivateApplicationNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { RunningApps.shared.reload() }
            }
        }
    }

    private func reload() {
        let own = Bundle.main.bundleIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.bundleIdentifier != nil && $0.bundleIdentifier != own
        }
        let list = apps.map {
            Running(id: $0.bundleIdentifier ?? "", name: $0.localizedName ?? "", path: $0.bundleURL?.path ?? "")
        }
        if list != running { running = list }
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if front != frontmostID { frontmostID = front }
    }
}
