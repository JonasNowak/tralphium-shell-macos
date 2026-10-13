import AppKit
import Carbon.HIToolbox
import TralphiumCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelf: ShelfController?
    private var launchpadHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance: only terminate if a prior instance was launched earlier.
        if let id = Bundle.main.bundleIdentifier {
            let myPID = getpid()
            let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
                .filter { $0.processIdentifier != myPID }
            if !others.isEmpty {
                let myApp = NSRunningApplication(processIdentifier: myPID)
                let myDate = myApp?.launchDate ?? Date()
                if others.contains(where: { ($0.launchDate ?? .distantPast) < myDate }) {
                    NSApp.terminate(nil)
                    return
                }
            }
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
        case .toggleControlPanel:
            ControlPanelController.shared.toggle()
        case .openPowerMenu:
            PowerMenuController.shared.toggle()
        case .takeScreenshot:
            ScreenshotService.take()
        case .reloadConfig:
            ConfigStore.shared.reload()
        case .toggleTheme:
            ConfigStore.shared.update { $0.theme = ThemePalette.next(after: $0.theme).name }
        case .setTheme(let name):
            ConfigStore.shared.update { $0.theme = name }
        case .unhide(let id):
            RunningApps.shared.unhide(bundleID: id, inBackground: false)
        case .unhideInBackground(let id):
            RunningApps.shared.unhide(bundleID: id, inBackground: true)
        case .unhideAll:
            RunningApps.shared.unhideAll(inBackground: true)
        case .hide(let id):
            RunningApps.shared.hide(bundleID: id)
        case .refreshApps:
            AppCatalog.shared.refresh()
        case .addWebApp(let targetURL, let name):
            Task {
                await WebAppService.create(url: targetURL, name: name, launchAfterCreation: true)
            }
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
