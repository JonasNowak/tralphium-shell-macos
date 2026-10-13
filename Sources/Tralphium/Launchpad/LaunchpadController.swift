import AppKit
import Observation
import SwiftUI
import TralphiumCore

@MainActor
@Observable
final class LaunchpadState {
    static let shared = LaunchpadState()
    var isVisible: Bool = false
    var query: String = ""
    var sessionID = UUID()

    func reset() {
        query = ""
        sessionID = UUID()
    }
}

/// Controller for the Launchpad overlay window docked above the launcher button.
@MainActor
final class LaunchpadController {
    static let shared = LaunchpadController()

    private let panel: ShellPanel
    var isVisible: Bool { LaunchpadState.shared.isVisible }

    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    private init() {
        panel = ShellPanel(
            level: .popUpMenu,
            behavior: [.canJoinAllSpaces, .fullScreenAuxiliary],
            takesKeyboard: true,
            mayLeaveScreen: false
        )
        panel.hasShadow = true

        let wrapperView = LaunchpadWrapperView { [weak self] in
            self?.hide()
        }

        panel.contentView = ShellHostingView(rootView: wrapperView)
        panel.onCancel = { [weak self] in
            self?.hide()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hide()
            }
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
        let padX: CGFloat = 12
        let shelfHeight: CGFloat = ShelfController.height
        let gap: CGFloat = 10
        let cardWidth: CGFloat = min(590, screen.frame.width - padX * 2)
        let cardHeight: CGFloat = min(520, screen.frame.height - shelfHeight - gap - 20)

        let frame = NSRect(
            x: screen.frame.minX + padX,
            y: screen.frame.minY + shelfHeight + gap,
            width: cardWidth,
            height: cardHeight
        )
        panel.setFrame(frame, display: true)
        panel.invalidateShadow()

        LaunchpadState.shared.reset()
        LaunchpadState.shared.isVisible = true
        AppCatalog.shared.refresh()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        installEventMonitors()
    }

    func hide() {
        guard isVisible else { return }
        LaunchpadState.shared.isVisible = false
        panel.orderOut(nil)
        removeEventMonitors()
    }

    private func installEventMonitors() {
        removeEventMonitors()

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hide()
            }
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, self.isVisible else { return event }

            if event.window == self.panel {
                return event
            }

            let mouseLocation = NSEvent.mouseLocation
            if self.isPointInLauncherButton(mouseLocation) {
                return event
            }

            self.hide()
            return event
        }
    }

    private func removeEventMonitors() {
        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
    }

    private func isPointInLauncherButton(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.main else { return false }
        let buttonRect = NSRect(
            x: screen.frame.minX + 6,
            y: screen.frame.minY + 2,
            width: 52,
            height: ShelfController.height - 4
        )
        return buttonRect.contains(point)
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
