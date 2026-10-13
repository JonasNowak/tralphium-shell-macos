import SwiftUI
import TralphiumCore

/// Right-hand status area: Wi-Fi, Audio, Battery, and Clock.
struct StatusAreaView: View {
    private let wifi = WiFiService.shared
    private let audio = AudioService.shared
    private let battery = BatteryService.shared
    private let clock = ClockService.shared

    var body: some View {
        HStack(spacing: 8) {
            // Wi-Fi
            StatusIconButton(
                symbol: wifi.symbolName,
                tooltip: wifi.subtitle,
                action: { wifi.togglePower() }
            )

            // Audio / Mute
            StatusIconButton(
                symbol: audioSymbol,
                tooltip: audioTooltip,
                action: { audio.toggleMute() }
            )

            // Battery (hidden on desktops without internal battery)
            if let status = battery.status {
                StatusBatteryButton(status: status)
            }

            // Clock
            StatusClockButton(
                time: clock.timeString,
                date: clock.dateString
            )
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

private struct StatusIconButton: View {
    let symbol: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(p.iconColor))
                .frame(width: 28, height: 28)
                .background(isHovered ? Color(p.hover) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tooltip)
    }
}

private struct StatusBatteryButton: View {
    let status: BatteryStatus
    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        HStack(spacing: 4) {
            Image(systemName: status.symbolName)
                .font(.system(size: 13))
            Text("\(status.capacity)%")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(Color(p.iconColor))
        .padding(.horizontal, 6)
        .frame(height: 28)
        .background(isHovered ? Color(p.hover) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
        .help(status.description)
    }
}

private struct StatusClockButton: View {
    let time: String
    let date: String
    @State private var isHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        Text(time.isEmpty ? "--:--" : time)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(Color(p.textForeground))
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(isHovered ? Color(p.hover) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onHover { isHovered = $0 }
            .help(date)
    }
}
