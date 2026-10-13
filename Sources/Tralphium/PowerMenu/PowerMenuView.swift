import SwiftUI
import TralphiumCore

/// Centered modal power actions dialog matching Tralphium's PowerMenu.qml.
struct PowerMenuView: View {
    var onClose: () -> Void

    var body: some View {
        let p = ThemeStore.shared.palette

        ZStack {
            // Dimmed backdrop, clicking closes
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            // Centered Card
            HStack(spacing: 6) {
                PowerOptionButton(
                    symbol: "power",
                    label: "Shut down",
                    action: {
                        onClose()
                        SessionService.powerOff()
                    }
                )

                PowerOptionButton(
                    symbol: "arrow.clockwise",
                    label: "Restart",
                    action: {
                        onClose()
                        SessionService.reboot()
                    }
                )

                PowerOptionButton(
                    symbol: "moon.zzz.fill",
                    label: "Sleep",
                    action: {
                        onClose()
                        SessionService.sleep()
                    }
                )

                PowerOptionButton(
                    symbol: "rectangle.portrait.and.arrow.right",
                    label: "Sign out",
                    action: {
                        onClose()
                        SessionService.signOut()
                    }
                )

                PowerOptionButton(
                    symbol: "lock.fill",
                    label: "Lock",
                    action: {
                        onClose()
                        SessionService.lock()
                    }
                )
            }
            .padding(16)
            .background(Color(p.panelBackground))
            .background(
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: p.panelRadius))
            )
            .clipShape(RoundedRectangle(cornerRadius: p.panelRadius))
            .overlay {
                RoundedRectangle(cornerRadius: p.panelRadius)
                    .strokeBorder(Color(p.panelBorder), lineWidth: p.panelBorderWidth)
            }
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
}

private struct PowerOptionButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette

        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isHovered ? Color(p.accent) : Color(p.iconColor))

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(p.textForeground))
            }
            .frame(width: 82, height: 80)
            .background(isHovered ? Color(p.hover).opacity(0.8) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
