import AppKit
import Observation
import SwiftUI
import TralphiumCore

@MainActor
@Observable
final class ControlPanelState {
    static let shared = ControlPanelState()
    var isVisible: Bool = false
}

/// Controller for the Control Panel (Quick Settings) pop-up window docked above the status area.
@MainActor
final class ControlPanelController {
    static let shared = ControlPanelController()

    private let panel: ShellPanel
    var isVisible: Bool { ControlPanelState.shared.isVisible }

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

        panel.contentView = ShellHostingView(rootView: ControlPanelView())
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

        // Close Launchpad if it was open
        LaunchpadController.shared.hide()

        // Refresh underlying services
        WiFiService.shared.refresh()
        BluetoothService.shared.refresh()
        NightShiftService.shared.refresh()
        BrightnessService.shared.refresh()
        AudioService.shared.refresh()

        let padX: CGFloat = 12
        let shelfHeight: CGFloat = ShelfController.height
        let gap: CGFloat = 10
        let panelWidth: CGFloat = 380

        // Calculate fitting size for content
        let fittingSize = panel.contentView?.fittingSize ?? NSSize(width: panelWidth, height: 440)
        let panelHeight = min(fittingSize.height > 0 ? fittingSize.height : 440, screen.frame.height - shelfHeight - gap - 20)

        let frame = NSRect(
            x: screen.frame.maxX - panelWidth - padX,
            y: screen.frame.minY + shelfHeight + gap,
            width: panelWidth,
            height: panelHeight
        )

        panel.setFrame(frame, display: true)
        panel.invalidateShadow()

        ControlPanelState.shared.isVisible = true
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        installEventMonitors()
    }

    func hide() {
        guard isVisible else { return }
        ControlPanelState.shared.isVisible = false
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
            if self.isPointInStatusArea(mouseLocation) {
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

    private func isPointInStatusArea(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.main else { return false }
        let statusAreaRect = NSRect(
            x: screen.frame.maxX - 240,
            y: screen.frame.minY,
            width: 240,
            height: ShelfController.height + 4
        )
        return statusAreaRect.contains(point)
    }
}
