import AppKit

/// Base window of every shell surface: borderless, transparent, never steals
/// focus from the app you are working in, stays put when another app becomes
/// active. Each surface only states what differs: level, Spaces behaviour and
/// whether it takes keyboard input.
class ShellPanel: NSPanel {
    private let takesKeyboard: Bool

    init(level: NSWindow.Level, behavior: NSWindow.CollectionBehavior, takesKeyboard: Bool = false) {
        self.takesKeyboard = takesKeyboard
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        self.level = level
        collectionBehavior = behavior
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovable = false
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { takesKeyboard }
    override var canBecomeMain: Bool { false }
}
