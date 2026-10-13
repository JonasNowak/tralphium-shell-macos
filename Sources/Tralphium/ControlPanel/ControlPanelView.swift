import SwiftUI
import TralphiumCore

/// Main content of the Tralphium Control Panel (Quick Settings).
struct ControlPanelView: View {
    private let wifi = WiFiService.shared
    private let bluetooth = BluetoothService.shared
    private let nightShift = NightShiftService.shared
    private let brightness = BrightnessService.shared
    private let audio = AudioService.shared
    private let battery = BatteryService.shared
    private let clock = ClockService.shared

    @State private var volumeValue: Double = 0
    @State private var brightnessValue: Double = 0
    @State private var isAudioOutputsExpanded = false

    @State private var isSignOutHovered = false
    @State private var isPowerHovered = false
    @State private var isLockHovered = false
    @State private var isSettingsHovered = false
    @State private var isShareHovered = false

    var body: some View {
        let p = ThemeStore.shared.palette
        let config = ConfigStore.shared.config

        VStack(spacing: 14) {
            // MARK: - Header: User profile, Sign out, and session actions
            HStack(spacing: 8) {
                // User avatar & display name
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(p.iconColor))

                    Text(userName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(p.textForeground))
                        .lineLimit(1)
                }

                Spacer()

                // Sign out button
                Button {
                    ControlPanelController.shared.hide()
                    SessionService.signOut()
                } label: {
                    Text("Sign out")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(p.textForeground))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSignOutHovered ? Color(p.hover).opacity(0.8) : Color(p.hover).opacity(0.35))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().strokeBorder(Color(p.panelBorder).opacity(0.5), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .onHover { isSignOutHovered = $0 }
                .help("Sign out")

                // Power button
                HeaderIconButton(
                    symbol: "power",
                    isHovered: isPowerHovered,
                    onHover: { isPowerHovered = $0 }
                ) {
                    ControlPanelController.shared.hide()
                    PowerMenuController.shared.show()
                }
                .help("Power Menu")

                // Lock button
                HeaderIconButton(
                    symbol: "lock.fill",
                    isHovered: isLockHovered,
                    onHover: { isLockHovered = $0 }
                ) {
                    ControlPanelController.shared.hide()
                    SessionService.lock()
                }
                .help("Lock Screen")

                // Open config.json button (Settings)
                HeaderIconButton(
                    symbol: "gearshape.fill",
                    isHovered: isSettingsHovered,
                    onHover: { isSettingsHovered = $0 }
                ) {
                    ControlPanelController.shared.hide()
                    Launch.url(ShellFiles.config)
                }
                .help("Open config.json")
            }

            DividerLine()

            // MARK: - Quick Toggles Grid (3 columns)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 12
            ) {
                // 1. Network / Wi-Fi
                QuickToggleView(
                    symbolName: wifi.symbolName,
                    title: "Network",
                    subtitle: wifi.subtitle,
                    isActive: wifi.isConnected
                ) {
                    wifi.togglePower()
                }

                // 2. Bluetooth
                QuickToggleView(
                    title: "Bluetooth",
                    subtitle: bluetooth.isOn ? "On" : "Off",
                    isActive: bluetooth.isOn,
                    action: { bluetooth.toggle() }
                ) {
                    BluetoothShape()
                        .stroke(
                            bluetooth.isOn ? Color(p.shelfBackground) : Color(p.iconColor),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 14, height: 20)
                }

                // 3. Do Not Disturb
                QuickToggleView(
                    symbolName: config.notificationsEnabled ? "bell.fill" : "moon.fill",
                    title: "Do Not Disturb",
                    subtitle: config.notificationsEnabled ? "Off" : "On",
                    isActive: !config.notificationsEnabled
                ) {
                    ConfigStore.shared.update { $0.notificationsEnabled.toggle() }
                    if !config.dndShortcut.isEmpty {
                        Launch.run("/usr/bin/shortcuts", ["run", config.dndShortcut])
                    }
                }

                // 4. Night Shift
                QuickToggleView(
                    symbolName: nightShift.isOn ? "sun.max.fill" : "moon.stars.fill",
                    title: "Night Shift",
                    subtitle: nightShift.isOn ? "On" : "Off",
                    isActive: nightShift.isOn
                ) {
                    nightShift.toggle()
                }

                // 5. Theme
                QuickToggleView(
                    symbolName: "paintpalette.fill",
                    title: "Theme",
                    subtitle: config.theme.capitalized,
                    isActive: true
                ) {
                    ConfigStore.shared.update { $0.theme = ThemePalette.next(after: $0.theme).name }
                }

                // 6. Screen Capture
                QuickToggleView(
                    symbolName: "camera.viewfinder",
                    title: "Capture",
                    subtitle: "Area",
                    isActive: false
                ) {
                    ControlPanelController.shared.hide()
                    Task {
                        try? await Task.sleep(for: .milliseconds(250))
                        ScreenshotService.take()
                    }
                }
            }

            DividerLine()

            // MARK: - Sliders: Volume & Brightness
            VStack(spacing: 10) {
                // Volume slider
                SliderRowView(
                    icon: audioSymbol,
                    trailingIcon: isAudioOutputsExpanded ? "chevron.down" : "chevron.right",
                    value: $volumeValue,
                    onMoved: { audio.setVolume($0) },
                    onIconClicked: { audio.toggleMute() },
                    onTrailingClicked: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isAudioOutputsExpanded.toggle()
                        }
                    }
                )

                // Expandable Audio Output selector
                if isAudioOutputsExpanded && !audio.outputs.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Audio Output")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(p.textSecondary))
                            .padding(.horizontal, 6)
                            .padding(.top, 2)

                        ForEach(audio.outputs) { device in
                            Button {
                                audio.setDefaultOutput(device.id)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: device.isDefault ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(device.isDefault ? Color(p.accent) : Color(p.textSecondary))

                                    Text(device.name)
                                        .font(.system(size: 11.5, weight: device.isDefault ? .semibold : .regular))
                                        .foregroundColor(Color(p.textForeground))
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(device.isDefault ? Color(p.hover).opacity(0.6) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(p.hover).opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color(p.panelBorder).opacity(0.4), lineWidth: 1)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Brightness slider (built-in display)
                if brightness.isAvailable {
                    SliderRowView(
                        icon: "sun.max.fill",
                        value: $brightnessValue,
                        onMoved: { brightness.set($0) }
                    )
                }
            }

            DividerLine()

            // MARK: - Footer: Date, Battery, and AirDrop
            HStack(spacing: 6) {
                // Short date
                Text(clock.shortDateString.isEmpty ? "--" : clock.shortDateString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(p.textForeground))

                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(Color(p.textSecondary))

                // Battery status
                if let status = battery.status {
                    HStack(spacing: 4) {
                        Image(systemName: status.symbolName)
                            .font(.system(size: 11))
                        Text(status.description)
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundColor(Color(p.textForeground))
                } else {
                    Text("AC Power")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(p.textSecondary))
                }

                Spacer()

                // AirDrop button
                Button {
                    ControlPanelController.shared.hide()
                    Launch.app(at: "/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isShareHovered ? Color(p.accent) : Color(p.iconColor))
                        .frame(width: 24, height: 24)
                        .background(isShareHovered ? Color(p.hover).opacity(0.7) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .onHover { isShareHovered = $0 }
                .help("AirDrop")
            }
        }
        .padding(16)
        .frame(width: 380)
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
        .onAppear {
            volumeValue = audio.volume
            brightnessValue = brightness.value
        }
        .onChange(of: audio.volume) { _, newVolume in
            volumeValue = newVolume
        }
        .onChange(of: brightness.value) { _, newBrightness in
            brightnessValue = newBrightness
        }
    }

    private var userName: String {
        let full = NSFullUserName()
        return full.isEmpty ? NSUserName() : full
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
}

private struct DividerLine: View {
    var body: some View {
        let p = ThemeStore.shared.palette
        Rectangle()
            .fill(Color(p.panelBorder).opacity(0.4))
            .frame(height: 1)
    }
}

private struct HeaderIconButton: View {
    let symbol: String
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let action: () -> Void

    var body: some View {
        let p = ThemeStore.shared.palette
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isHovered ? Color(p.accent) : Color(p.iconColor))
                .frame(width: 28, height: 28)
                .background(isHovered ? Color(p.hover).opacity(0.8) : Color(p.hover).opacity(0.3))
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(Color(p.panelBorder).opacity(0.5), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
    }
}
