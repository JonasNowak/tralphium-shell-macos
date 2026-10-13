import AppKit
import SwiftUI
import TralphiumCore

/// Controller for the bottom desktop shelf.
@MainActor
final class ShelfController {
    static let height: CGFloat = 48

    private let panel = ShellPanel(
        level: .statusBar,
        behavior: [.canJoinAllSpaces, .stationary, .ignoresCycle],
        takesKeyboard: false,
        mayLeaveScreen: true
    )

    private var isHidden = false
    private var isAppFullscreen = false
    var onLauncherClick: (() -> Void)?

    init(onLauncherClick: (() -> Void)? = nil) {
        self.onLauncherClick = onLauncherClick

        let hostingView = ShelfHostingView(rootView: ShelfView(onLauncherClick: { [weak self] in
            self?.onLauncherClick?()
        }))

        hostingView.onMouseEnter = { [weak self] in
            self?.handleMouseEnter()
        }
        hostingView.onMouseExit = { [weak self] in
            self?.handleMouseExit()
        }

        panel.contentView = hostingView
        reposition()

        // Handle screen resolution/layout changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkFullscreenState()
                self?.reposition()
            }
        }

        // Handle config changes (e.g. autoHide toggled)
        ConfigStore.shared.observe { [weak self] in
            self?.reposition()
        }

        // Handle space and active app changes to detect fullscreen apps
        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkFullscreenState() }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkFullscreenState() }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkFullscreenState() }
        }
    }

    func show() {
        guard !isAppFullscreen else { return }
        panel.orderFrontRegardless()
    }

    private func handleMouseEnter() {
        guard !isAppFullscreen, ConfigStore.shared.config.shelfAutoHide, isHidden else { return }
        reveal()
    }

    private func handleMouseExit() {
        guard !isAppFullscreen, ConfigStore.shared.config.shelfAutoHide, !isHidden else { return }
        hideToSliver()
    }

    private func reveal() {
        guard !isAppFullscreen, let screen = NSScreen.main else { return }
        isHidden = false
        let f = screen.frame
        let targetFrame = NSRect(x: f.minX, y: f.minY, width: f.width, height: Self.height)
        animateFrame(to: targetFrame)
    }

    private func hideToSliver() {
        guard !isAppFullscreen, let screen = NSScreen.main else { return }
        isHidden = true
        let f = screen.frame
        let targetFrame = NSRect(x: f.minX, y: f.minY - Self.height + 4, width: f.width, height: Self.height)
        animateFrame(to: targetFrame)
    }

    private func animateFrame(to frame: NSRect) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func checkFullscreenState() {
        let isFS = isFrontmostAppFullscreen()
        guard isFS != isAppFullscreen else { return }
        isAppFullscreen = isFS
        reposition()
    }

    private func isFrontmostAppFullscreen() -> Bool {
        if NSApp.currentSystemPresentationOptions.contains(.fullScreen) {
            return true
        }
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
        let pid = frontApp.processIdentifier
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]],
              let screen = NSScreen.main else {
            return false
        }
        for win in windowList {
            guard let winPID = win[kCGWindowOwnerPID as String] as? pid_t, winPID == pid else { continue }
            guard let layer = win[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            if let bounds = win[kCGWindowBounds as String] as? [String: CGFloat],
               let w = bounds["Width"], let h = bounds["Height"],
               w >= screen.frame.width - 2 && h >= screen.frame.height - 2 {
                return true
            }
        }
        return false
    }

    private func reposition() {
        guard let screen = NSScreen.main else { return }
        if isAppFullscreen {
            panel.orderOut(nil)
            return
        } else if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        let f = screen.frame
        let autoHide = ConfigStore.shared.config.shelfAutoHide
        if !autoHide { isHidden = false }
        let y = (autoHide && isHidden) ? (f.minY - Self.height + 4) : f.minY
        panel.setFrame(NSRect(x: f.minX, y: y, width: f.width, height: Self.height), display: true)
    }
}

/// Hosting view for the shelf that receives mouse clicks immediately and tracks hover.
final class ShelfHostingView<Content: View>: NSHostingView<Content> {
    var onMouseEnter: (() -> Void)?
    var onMouseExit: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExit?()
    }
}
