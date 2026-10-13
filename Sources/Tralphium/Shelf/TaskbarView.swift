import AppKit
import SwiftUI
import TralphiumCore

/// Centered taskbar with pinned and running applications.
/// Supports moveable/reorderable icons via drag-and-drop and unhiding apps in background.
struct TaskbarView: View {
    private let pins = ListStore.pins
    private let runningApps = RunningApps.shared
    private let catalog = AppCatalog.shared

    @State private var draggingID: String? = nil
    @State private var dragOffset: CGFloat = 0

    private let pitch: CGFloat = 48.0 // 42 pt item width + 6 pt spacing

    var body: some View {
        let items = TaskbarModel.items(
            pinned: pins.list,
            running: runningApps.running.map(\.id)
        )
        let totalPinned = pins.list.ids.count

        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isDragging = (draggingID == item.id)
                let isRunning = runningApps.running.contains { $0.id.caseInsensitiveCompare(item.id) == .orderedSame }
                let isHidden = runningApps.isHidden(bundleID: item.id)
                let isFrontmost = runningApps.frontmostID?.caseInsensitiveCompare(item.id) == .orderedSame
                let shift = computeShift(for: index, items: items, totalPinned: totalPinned)

                TaskbarItemView(
                    item: item,
                    isRunning: isRunning,
                    isHidden: isHidden,
                    isFrontmost: isFrontmost,
                    isDragging: isDragging,
                    isAnyDragging: draggingID != nil
                )
                .offset(x: isDragging ? dragOffset : shift)
                .zIndex(isDragging ? 20 : 0)
                .scaleEffect(isDragging ? 1.08 : 1.0)
                .shadow(
                    color: isDragging ? Color.black.opacity(0.35) : Color.clear,
                    radius: 6,
                    x: 0,
                    y: 3
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            if draggingID == nil && abs(val.translation.width) > 4 {
                                draggingID = item.id
                            }
                            if draggingID == item.id {
                                dragOffset = val.translation.width
                            }
                        }
                        .onEnded { val in
                            if let curID = draggingID, curID == item.id {
                                let offsetSlots = Int(round(val.translation.width / pitch))
                                let maxTarget = item.isPinned ? max(0, totalPinned - 1) : totalPinned
                                let targetIndex = max(0, min(maxTarget, index + offsetSlots))
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    pins.insert(item.id, at: targetIndex)
                                }
                                draggingID = nil
                                dragOffset = 0
                            } else {
                                handleClick(item: item, isRunning: isRunning, isHidden: isHidden)
                            }
                        }
                )
            }
        }
        .animation(.snappy(duration: 0.2), value: dragOffset)
        .animation(.snappy(duration: 0.2), value: draggingID)
    }

    private func computeShift(for index: Int, items: [TaskbarModel.Item], totalPinned: Int) -> CGFloat {
        guard let draggingID,
              let sourceIndex = items.firstIndex(where: { $0.id.caseInsensitiveCompare(draggingID) == .orderedSame }),
              sourceIndex != index else { return 0 }

        let offsetSlots = Int(round(dragOffset / pitch))
        let isSourcePinned = items[sourceIndex].isPinned
        let maxTarget = isSourcePinned ? max(0, totalPinned - 1) : totalPinned
        let targetIndex = max(0, min(maxTarget, sourceIndex + offsetSlots))

        if sourceIndex < targetIndex {
            if index > sourceIndex && index <= targetIndex {
                return -pitch
            }
        } else if sourceIndex > targetIndex {
            if index >= targetIndex && index < sourceIndex {
                return pitch
            }
        }
        return 0
    }

    private func handleClick(item: TaskbarModel.Item, isRunning: Bool, isHidden: Bool) {
        let isOption = NSEvent.modifierFlags.contains(.option)
        if isRunning {
            if isHidden {
                // If hidden, Option-click unhides in background, regular click unhides & activates
                RunningApps.shared.unhide(bundleID: item.id, inBackground: isOption)
            } else if isOption {
                // Option-click on running app hides it
                RunningApps.shared.hide(bundleID: item.id)
            } else {
                if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: item.id).first {
                    runningApp.activate()
                }
            }
        } else {
            Launch.app(bundleID: item.id)
        }
    }
}

private struct TaskbarItemView: View {
    let item: TaskbarModel.Item
    let isRunning: Bool
    let isHidden: Bool
    let isFrontmost: Bool
    let isDragging: Bool
    let isAnyDragging: Bool

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        let appName = AppCatalog.shared.name(forBundleID: item.id)
        let iconImage = AppCatalog.shared.icon(forBundleID: item.id)

        ZStack(alignment: .bottom) {
            // Centered App Icon (dimmed if hidden in background)
            Image(nsImage: iconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 32, height: 32)
                .opacity(isRunning && isHidden ? 0.55 : 1.0)
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
        .background((isHovered && !isAnyDragging) ? Color(p.hover) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .help(helpText(appName: appName))
        .contextMenu {
            Button(item.isPinned ? "Unpin from Shelf" : "Pin to Shelf") {
                ListStore.pins.toggle(item.id)
            }
            if isRunning {
                Divider()
                if isHidden {
                    Button("Unhide in Background") {
                        RunningApps.shared.unhide(bundleID: item.id, inBackground: true)
                    }
                    Button("Unhide") {
                        RunningApps.shared.unhide(bundleID: item.id, inBackground: false)
                    }
                    if RunningApps.shared.hiddenApps.count > 1 {
                        Button("Unhide All in Background") {
                            RunningApps.shared.unhideAll(inBackground: true)
                        }
                    }
                } else {
                    Button("Hide") {
                        RunningApps.shared.hide(bundleID: item.id)
                    }
                }
                Divider()
                Button("Quit \(appName)") {
                    NSRunningApplication.runningApplications(withBundleIdentifier: item.id).first?.terminate()
                }
            }
        }
    }

    private func helpText(appName: String) -> String {
        if isRunning && isHidden {
            return "\(appName) (Hidden — ⌥Click or menu to unhide in background)"
        }
        return appName
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
