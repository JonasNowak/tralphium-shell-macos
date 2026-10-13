import AppKit
import SwiftUI
import TralphiumCore

/// Centered taskbar with pinned and running applications.
struct TaskbarView: View {
    private let pins = ListStore.pins
    private let runningApps = RunningApps.shared
    private let catalog = AppCatalog.shared

    var body: some View {
        let items = TaskbarModel.items(
            pinned: pins.list,
            running: runningApps.running.map(\.id)
        )

        HStack(spacing: 6) {
            ForEach(items, id: \.id) { item in
                TaskbarItemView(
                    item: item,
                    isRunning: runningApps.running.contains { $0.id.caseInsensitiveCompare(item.id) == .orderedSame },
                    isFrontmost: runningApps.frontmostID?.caseInsensitiveCompare(item.id) == .orderedSame
                )
            }
        }
    }
}

private struct TaskbarItemView: View {
    let item: TaskbarModel.Item
    let isRunning: Bool
    let isFrontmost: Bool

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        let appName = AppCatalog.shared.name(forBundleID: item.id)
        let iconImage = AppCatalog.shared.icon(forBundleID: item.id)

        Button {
            handleClick()
        } label: {
            ZStack(alignment: .bottom) {
                // Centered App Icon
                Image(nsImage: iconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Running indicator pill at bottom
                if isRunning {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(indicatorColor(palette: p))
                        .frame(width: isFrontmost ? 14 : 5, height: 2.5)
                        .padding(.bottom, 2)
                }
            }
            .frame(width: 42, height: 42)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(appName)
        .contextMenu {
            Button(item.isPinned ? "Unpin from Shelf" : "Pin to Shelf") {
                ListStore.pins.toggle(item.id)
            }
            if isRunning {
                Divider()
                Button("Quit \(appName)") {
                    NSRunningApplication.runningApplications(withBundleIdentifier: item.id).first?.terminate()
                }
            }
        }
    }

    private func handleClick() {
        if isRunning,
           let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: item.id).first {
            runningApp.activate()
        } else {
            Launch.app(bundleID: item.id)
        }
    }

    private func indicatorColor(palette: ThemePalette) -> Color {
        if isFrontmost {
            return Color(palette.indicatorActive)
        } else if isRunning {
            return Color(palette.indicatorInactive)
        } else {
            return Color.clear
        }
    }
}
