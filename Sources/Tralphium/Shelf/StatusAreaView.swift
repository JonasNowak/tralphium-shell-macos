import SwiftUI
import TralphiumCore

/// Right-hand status area: compact pill-shaped date and system status.
struct StatusAreaView: View {
    private let wifi = WiFiService.shared
    private let audio = AudioService.shared
    private let battery = BatteryService.shared
    private let clock = ClockService.shared

    @State private var isDateHovered = false
    @State private var isMainHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette

        HStack(spacing: 3.5) {
            // Left Pill: Date
            Button {
                Launch.app(named: "Calendar")
            } label: {
                Text(clock.shortDateString.isEmpty ? "--" : clock.shortDateString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(p.textForeground))
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(isDateHovered ? Color(p.hover).opacity(0.75) : Color(p.hover).opacity(0.35))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 4
                        )
                    )
                    .overlay {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 4
                        )
                        .strokeBorder(Color(p.panelBorder).opacity(0.5), lineWidth: 1)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isDateHovered = $0 }
            .help(clock.dateString)

            // Right Pill: Time, Wi-Fi, Audio, Battery
            HStack(spacing: 8) {
                // Clock Time
                Text(clock.timeString.isEmpty ? "--:--" : clock.timeString)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(p.textForeground))

                // Wi-Fi
                StatusAreaIconButton(
                    symbol: wifi.symbolName,
                    tooltip: wifi.subtitle,
                    action: { wifi.togglePower() }
                )

                // Audio
                StatusAreaIconButton(
                    symbol: audioSymbol,
                    tooltip: audioTooltip,
                    action: { audio.toggleMute() }
                )

                // Battery (hidden on desktop systems without internal battery)
                if let status = battery.status {
                    HStack(spacing: 3) {
                        Image(systemName: status.symbolName)
                            .font(.system(size: 11))
                        Text("\(status.capacity)%")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(p.iconColor))
                    .help(status.description)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(isMainHovered ? Color(p.hover).opacity(0.75) : Color(p.hover).opacity(0.35))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 14,
                    topTrailingRadius: 14
                )
            )
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 14,
                    topTrailingRadius: 14
                )
                .strokeBorder(Color(p.panelBorder).opacity(0.5), lineWidth: 1)
            }
            .onHover { isMainHovered = $0 }
        }
    }

    private var audioSymbol: String {
        if audio.isMuted {
            return "speaker.slash.fill"
        } else if audio.volume > 0.5 {
            return "speaker.wave.3.fill"
        } else if audio.volume > 0.05 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.fill"
        }
    }

    private var audioTooltip: String {
        if audio.isMuted {
            return "Audio Muted"
        } else {
            return "Volume: \(Int((audio.volume * 100).rounded()))%"
        }
    }
}

private struct StatusAreaIconButton: View {
    let symbol: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isHovered ? Color(p.accent) : Color(p.iconColor))
                .frame(width: 18, height: 18)
                .background(isHovered ? Color(p.hover).opacity(0.8) : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tooltip)
    }
}
