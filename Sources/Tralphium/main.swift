import AppKit

// Tralphium is an accessory app: no Dock icon, no menu bar. The shelf and the
// other panels are plain windows owned by `AppDelegate`.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
