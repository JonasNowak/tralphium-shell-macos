import AppKit
import SwiftUI
import TralphiumCore

/// Controller for the full-screen modal Power Menu.
@MainActor
final class PowerMenuController {
    static let shared = PowerMenuController()

    private let panel: ShellPanel
    private(set) var isVisible = false

    private init() {
        panel = ShellPanel(
            level: .popUpMenu,
            behavior: [.canJoinAllSpaces, .fullScreenAuxiliary],
            takesKeyboard: true,
            mayLeaveScreen: false
        )

        let wrapperView = PowerMenuView { [weak self] in
            self?.hide()
        }
        panel.contentView = ShellHostingView(rootView: wrapperView)
        panel.onCancel = { [weak self] in
            self?.hide()
        }
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let screen = NSScreen.main else { return }

        // Close other panels
        ControlPanelController.shared.hide()
        LaunchpadController.shared.hide()

        panel.setFrame(screen.frame, display: true)
        isVisible = true
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        panel.orderOut(nil)
    }
}
