import AppKit
import SwiftUI

/// The bottom shelf. Skeleton for phase 2: themed bar docked to the bottom
/// edge of the main screen. Content (launcher button, taskbar, status area)
/// follows in phase 4.
@MainActor
final class ShelfController {
    static let height: CGFloat = 48

    private let panel = ShellPanel(
        level: .statusBar,
        behavior: [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    )

    init() {
        panel.contentView = NSHostingView(rootView: ShelfView())
        reposition()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reposition() }
        }
    }

    func show() { panel.orderFrontRegardless() }

    private func reposition() {
        guard let screen = NSScreen.main else { return }
        let f = screen.frame
        panel.setFrame(NSRect(x: f.minX, y: f.minY, width: f.width, height: Self.height), display: true)
    }
}

struct ShelfView: View {
    private let theme = ThemeStore.shared

    var body: some View {
        let p = theme.palette
        // Corners touching the screen edge stay square.
        UnevenRoundedRectangle(topLeadingRadius: p.panelRadius, topTrailingRadius: p.panelRadius)
            .fill(Color(p.panelBackground))
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: p.panelRadius, topTrailingRadius: p.panelRadius)
                    .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
            }
            .ignoresSafeArea()
    }
}
