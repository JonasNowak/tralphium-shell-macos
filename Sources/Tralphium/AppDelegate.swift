import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelf: ShelfController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second copy would stack another shelf on top of the first one.
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            NSApp.terminate(nil)
            return
        }
        let shelf = ShelfController()
        shelf.show()
        self.shelf = shelf
    }
}
