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
            .background(
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: p.panelRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: p.panelRadius
                        )
                    )
            )
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: p.panelRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: p.panelRadius
                )
                .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
            }

            // Shelf content: Left and Right at the edges, Taskbar strictly centered
            ZStack {
                HStack {
                    // Left: Launcher Button
                    LauncherButtonView(action: onLauncherClick)

                    Spacer()

                    // Right: Status Area
                    StatusAreaView()
                }
                .padding(.horizontal, 12)

                // Center: Taskbar strictly centered on the shelf and screen
                TaskbarView()
            }
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
            if !RunningApps.shared.hiddenApps.isEmpty {
                Divider()
                Button("Unhide All in Background") {
                    RunningApps.shared.unhideAll(inBackground: true)
                }
            }
            Divider()
            Button("Open config.json") {
                Launch.url(ShellFiles.config)
            }
        }
    }
}
