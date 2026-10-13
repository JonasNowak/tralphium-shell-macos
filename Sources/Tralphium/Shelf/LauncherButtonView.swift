import SwiftUI
import TralphiumCore

/// Tralphium launcher button: ring with a dot in the center.
struct LauncherButtonView: View {
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(Color(p.iconColor), lineWidth: 2)
                    .frame(width: 14, height: 14)

                // Inner dot
                Circle()
                    .fill(Color(p.iconColor))
                    .frame(width: 4, height: 4)
            }
            .frame(width: 34, height: 34)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Launchpad (⌥Space)")
    }
}
