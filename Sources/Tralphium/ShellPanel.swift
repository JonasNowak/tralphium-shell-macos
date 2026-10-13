import AppKit
import SwiftUI

/// Base window of every shell surface: borderless, transparent, never steals
/// focus from the app you are working in, stays put when another app becomes
/// active. Each surface only states what differs: level, Spaces behaviour and
/// whether it takes keyboard input.
class ShellPanel: NSPanel {
    private let takesKeyboard: Bool
    private let mayLeaveScreen: Bool
    /// Called for Escape.
    var onCancel: (() -> Void)?

    /// `mayLeaveScreen`: macOS pushes windows back onto the screen otherwise,
    /// but an auto-hidden shelf has to slide mostly off it.
    init(level: NSWindow.Level, behavior: NSWindow.CollectionBehavior,
         takesKeyboard: Bool = false, mayLeaveScreen: Bool = false) {
        self.takesKeyboard = takesKeyboard
        self.mayLeaveScreen = mayLeaveScreen
        var mask: NSWindow.StyleMask = [.borderless]
        if !takesKeyboard {
            mask.insert(.nonactivatingPanel)
        }
        super.init(
            contentRect: .zero,
            styleMask: mask,
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
    override var canBecomeMain: Bool { takesKeyboard }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        mayLeaveScreen ? frameRect : super.constrainFrameRect(frameRect, to: screen)
    }

    override func cancelOperation(_ sender: Any?) {
        if let onCancel { onCancel() } else { super.cancelOperation(sender) }
    }
}

/// Hosting view for panels that are not key: the first click must reach the
/// buttons instead of only focusing the window.
final class ShellHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Visual effect view providing native translucent blurred glass backgrounds.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
