import AppKit
import Carbon.HIToolbox
import TralphiumCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelf: ShelfController?
    private var launchpadHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance: a second copy would stack on top.
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            NSApp.terminate(nil)
            return
        }

        // Initialize Shelf
        let shelf = ShelfController {
            LaunchpadController.shared.toggle()
        }
        shelf.show()
        self.shelf = shelf

        // Initialize global hotkey for Launchpad (⌥Space)
        setupHotKey()

        // Apply wallpaper if configured
        if !ConfigStore.shared.config.wallpaper.isEmpty {
            WallpaperService.apply(ConfigStore.shared.config.wallpaper)
        }

        // Reconfigure hotkey if config changes
        ConfigStore.shared.observe { [weak self] in
            self?.setupHotKey()
        }
    }

    private var lastEventTime: Date = .distantPast

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURL(url)
        }
    }

    private func handleURL(_ url: URL) {
        let now = Date()
        guard now.timeIntervalSince(lastEventTime) > 0.2 else { return }
        lastEventTime = now

        guard let command = ShellCommand(url: url) else { return }
        switch command {
        case .toggleLaunchpad:
            LaunchpadController.shared.toggle()
        case .openLaunchpad:
            LaunchpadController.shared.show()
        case .closeLaunchpad:
            LaunchpadController.shared.hide()
        case .reloadConfig:
            ConfigStore.shared.reload()
        default:
            break
        }
    }

    private func setupHotKey() {
        launchpadHotKey?.unregister()
        launchpadHotKey = nil

        guard ConfigStore.shared.config.launchpadHotkey else { return }
        // ⌥Space: kVK_Space = 49, optionKey = 0x0800
        launchpadHotKey = HotKey(keyCode: kVK_Space, modifiers: optionKey) {
            LaunchpadController.shared.toggle()
        }
    }
}
