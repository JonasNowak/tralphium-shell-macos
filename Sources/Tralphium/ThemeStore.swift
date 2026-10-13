import AppKit
import SwiftUI
import TralphiumCore

extension Color {
    init(_ c: RGBA) {
        self.init(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }
}

/// The active theme, shared by all views. Views read it inside `body`, so the
/// Observation framework redraws them when the config's theme changes.
@MainActor
final class ThemeStore {
    static let shared = ThemeStore()
    var palette: ThemePalette { ThemePalette.named(ConfigStore.shared.config.theme) }
}
