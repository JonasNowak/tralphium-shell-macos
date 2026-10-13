import AppKit
import Observation
import SwiftUI
import TralphiumCore

@MainActor
@Observable
final class LaunchpadState {
    static let shared = LaunchpadState()
    var query: String = ""
    var sessionID = UUID()

    func reset() {
        query = ""
        sessionID = UUID()
    }
}

/// Controller for the fullscreen Launchpad overlay window.
@MainActor
final class LaunchpadController {
    static let shared = LaunchpadController()

    private let panel: ShellPanel
    private(set) var isVisible = false

    private init() {
        panel = ShellPanel(
            level: .popUpMenu,
            behavior: [.canJoinAllSpaces, .fullScreenAuxiliary],
            takesKeyboard: true,
            mayLeaveScreen: false
        )

        let wrapperView = LaunchpadWrapperView { [weak self] in
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
        panel.setFrame(screen.frame, display: true)
        LaunchpadState.shared.reset()
        AppCatalog.shared.refresh()
        isVisible = true
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        isVisible = false
        panel.orderOut(nil)
    }
}

private struct LaunchpadWrapperView: View {
    var onClose: () -> Void
    private let state = LaunchpadState.shared

    var body: some View {
        @Bindable var boundState = state
        LaunchpadView(query: $boundState.query, onClose: onClose)
            .id(state.sessionID)
    }
}
