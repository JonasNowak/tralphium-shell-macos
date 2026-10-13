import AppKit
import SwiftUI
import TralphiumCore

extension Color {
    init(_ c: RGBA) {
        self.init(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }
}

/// The active theme, shared by all views. Replaced by the config-backed store
/// in phase 3 (PLAN.md).
@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()
    var palette = ThemePalette.named(ThemePalette.defaultName)
}
