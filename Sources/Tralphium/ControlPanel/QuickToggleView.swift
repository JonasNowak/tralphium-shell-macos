import SwiftUI
import TralphiumCore

/// Shape that draws the classic Bluetooth bind-rune.
struct BluetoothShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        let topY = rect.minY + 2
        let botY = rect.maxY - 2
        let wingX = rect.midX + rect.width * 0.42
        let leftX = rect.midX - rect.width * 0.35
        let upperY = rect.minY + rect.height * 0.32
        let lowerY = rect.maxY - rect.height * 0.32

        p.move(to: CGPoint(x: leftX, y: upperY))
        p.addLine(to: CGPoint(x: wingX, y: lowerY))
        p.addLine(to: CGPoint(x: midX, y: botY))
        p.addLine(to: CGPoint(x: midX, y: topY))
        p.addLine(to: CGPoint(x: wingX, y: upperY))
        p.addLine(to: CGPoint(x: leftX, y: lowerY))
        return p
    }
}

/// Circular quick settings toggle tile matching Tralphium's design:
/// 52px circle with icon and title/subtitle labels underneath.
struct QuickToggleView: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    let action: () -> Void
    let icon: AnyView

    @State private var isHovered = false

    init<I: View>(
        title: String,
        subtitle: String,
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> I
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.action = action
        self.icon = AnyView(icon())
    }

    init(
        symbolName: String,
        title: String,
        subtitle: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.action = action
        self.icon = AnyView(
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .medium))
        )
    }

    var body: some View {
        let p = ThemeStore.shared.palette

        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color(p.accent) : Color(p.hover).opacity(0.35))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Circle()
                                .strokeBorder(Color(p.panelBorder).opacity(0.5), lineWidth: 1)
                        }
                        .overlay {
                            if isHovered {
                                Circle()
                                    .fill(Color(p.hover).opacity(0.2))
                            }
                        }

                    icon
                        .foregroundColor(isActive ? Color(p.shelfBackground) : Color(p.iconColor))
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(p.textForeground))
                        .lineLimit(1)

                    Text(subtitle.isEmpty ? " " : subtitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color(p.textSecondary))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
