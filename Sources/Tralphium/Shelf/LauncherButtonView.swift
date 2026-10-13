import SwiftUI
import TralphiumCore

/// Tralphium launcher button: ring with a dot in the center.
struct LauncherButtonView: View {
    var action: () -> Void
    @State private var isHovered = false
    private let state = LaunchpadState.shared

    var body: some View {
        let p = ThemeStore.shared.palette
        let isActive = state.isVisible

        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(isActive ? Color(p.accent) : Color(p.iconColor), lineWidth: 2)
                    .frame(width: 15, height: 15)

                // Inner dot
                Circle()
                    .fill(isActive ? Color(p.accent) : Color(p.iconColor))
                    .frame(width: 5, height: 5)
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(LauncherButtonStyle(isActive: isActive, isHovered: isHovered, palette: p))
        .onHover { isHovered = $0 }
        .help("Launchpad (⌥Space)")
    }
}

private struct LauncherButtonStyle: ButtonStyle {
    let isActive: Bool
    let isHovered: Bool
    let palette: ThemePalette

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let isHighlighted = isPressed || isActive

        configuration.label
            .background(
                isHighlighted
                    ? Color(palette.hover)
                    : (isHovered ? Color(palette.hover).opacity(0.6) : Color.clear)
            )
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(palette.accent).opacity(0.7), lineWidth: 1.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .animation(.easeOut(duration: 0.15), value: isHighlighted)
            .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
