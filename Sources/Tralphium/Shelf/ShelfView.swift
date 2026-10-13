import SwiftUI
import TralphiumCore

/// The main content of the bottom shelf.
struct ShelfView: View {
    var onLauncherClick: () -> Void

    var body: some View {
        let p = ThemeStore.shared.palette
        let config = ConfigStore.shared.config

        ZStack {
            // Background with rounded top corners, flat bottom edge touching screen
            UnevenRoundedRectangle(
                topLeadingRadius: p.panelRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: p.panelRadius
            )
            .fill(Color(p.panelBackground))
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: p.panelRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: p.panelRadius
                )
                .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
            }

            // Shelf content
            HStack(spacing: 12) {
                // Left: Launcher Button
                LauncherButtonView(action: onLauncherClick)

                Spacer()

                // Center: Taskbar
                TaskbarView()

                Spacer()

                // Right: Status Area
                StatusAreaView()
            }
            .padding(.horizontal, 14)
        }
        .frame(height: ShelfController.height)
        .ignoresSafeArea()
        .contextMenu {
            Button("Terminal") {
                Launch.app(named: config.apps.terminal)
            }
            Button("Files") {
                Launch.app(named: config.apps.fileManager)
            }
            Button("Activity Monitor") {
                Launch.app(named: config.apps.taskManager)
            }
            Divider()
            Button("Open config.json") {
                Launch.url(ShellFiles.config)
            }
        }
    }
}
