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
            VStack(spacing: 2) {
                Image(nsImage: iconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 26, height: 26)

                // Running indicator dot
                Circle()
                    .fill(indicatorColor(palette: p))
                    .frame(width: 4, height: 4)
            }
            .frame(width: 36, height: 38)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
