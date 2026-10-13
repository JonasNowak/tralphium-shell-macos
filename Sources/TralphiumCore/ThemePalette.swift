import Foundation

/// A colour as 0...1 components. Core stays free of AppKit/SwiftUI, the app
/// converts this to `Color`.
public struct RGBA: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Parses `#RRGGBB` or `#RRGGBBAA` (the `#` is optional). Returns nil for anything else.
    public init?(hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else {
            return nil
        }
        let hasAlpha = digits.count == 8
        let shift: (Int) -> Double = { Double((value >> UInt64($0)) & 0xFF) / 255 }
        if hasAlpha {
            self.init(red: shift(24), green: shift(16), blue: shift(8), alpha: shift(0))
        } else {
            self.init(red: shift(16), green: shift(8), blue: shift(0))
        }
    }

    public func withAlpha(_ alpha: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// Colours and shape of one theme. Same fields as the QML `ThemePalette`.
public struct ThemePalette: Equatable, Sendable {
    public var name: String
    public var shelfBackground: RGBA
    public var shelfOpacity: Double
    public var buttonHover: RGBA
    public var buttonHoverOpacity: Double
    public var iconColor: RGBA
    public var textForeground: RGBA
    public var accent: RGBA
    public var indicatorActive: RGBA
    public var indicatorInactive: RGBA
    public var panelBorderWidth: Double = 1
    public var panelRadius: Double = 16

    // Derived colours used across the shell.
    public var panelBackground: RGBA { shelfBackground.withAlpha(shelfOpacity) }
    public var hover: RGBA { buttonHover.withAlpha(buttonHoverOpacity) }
    public var panelBorder: RGBA { hover }
    public var textSecondary: RGBA { textForeground.withAlpha(0.7) }
    public var danger: RGBA { RGBA(hex: "#ff5252")! }
}

extension ThemePalette {
    public static let defaultName = "nord"

    /// Looks a theme up by its config name. Unknown names fall back to Nord.
    public static func named(_ name: String) -> ThemePalette {
        all.first { $0.name == name } ?? nord
    }

    public static var all: [ThemePalette] {
        [nord, catppuccinMocha, catppuccinMacchiato, catppuccinFrappe, catppuccinLatte, kanagawa, oneDark, oneLight]
    }

    // Palette values are hand-written hex literals, so the force unwraps cannot fail (covered by tests).
    private static func make(
        _ name: String, background: String, hover: String, text: String, accent: String,
        indicatorActive: String? = nil, indicatorInactive: String
    ) -> ThemePalette {
        ThemePalette(
            name: name,
            shelfBackground: RGBA(hex: background)!,
            shelfOpacity: 0.95,
            buttonHover: RGBA(hex: hover)!,
            buttonHoverOpacity: 0.8,
            iconColor: RGBA(hex: text)!,
            textForeground: RGBA(hex: text)!,
            accent: RGBA(hex: accent)!,
            indicatorActive: RGBA(hex: indicatorActive ?? accent)!,
            indicatorInactive: RGBA(hex: indicatorInactive)!
        )
    }

    public static let nord = make(
        "nord", background: "#2E3440", hover: "#4C566A", text: "#ECEFF4", accent: "#88C0D0",
        indicatorActive: "#FFFFFF", indicatorInactive: "#4C566A")

    // Catppuccin: Copyright (c) 2021 Catppuccin, MIT License
    public static let catppuccinMocha = make(
        "catppuccin-mocha", background: "#1e1e2e", hover: "#313244", text: "#cdd6f4", accent: "#89b4fa",
        indicatorInactive: "#45475a")
    public static let catppuccinMacchiato = make(
        "catppuccin-macchiato", background: "#24273a", hover: "#363a4f", text: "#cad3f5", accent: "#8aadf4",
        indicatorInactive: "#494d64")
    public static let catppuccinFrappe = make(
        "catppuccin-frappe", background: "#303446", hover: "#414559", text: "#c6d0f5", accent: "#8caaee",
        indicatorInactive: "#51576d")
    public static let catppuccinLatte = make(
        "catppuccin-latte", background: "#eff1f5", hover: "#ccd0da", text: "#4c4f69", accent: "#1e66f5",
        indicatorInactive: "#bcc0cc")

    // Kanagawa: Copyright (c) 2021 rebelot, MIT License
    public static let kanagawa = make(
        "kanagawa", background: "#1F1F28", hover: "#363646", text: "#DCD7BA", accent: "#7E9CD8",
        indicatorInactive: "#54546D")

    // One Dark / One Light: Copyright (c) 2014 GitHub Inc. / Atom, MIT License
    public static let oneDark = make(
        "one-dark", background: "#282c34", hover: "#3e4451", text: "#abb2bf", accent: "#61afef",
        indicatorInactive: "#5c6370")
    public static let oneLight = make(
        "one-light", background: "#fafafa", hover: "#e5e5e6", text: "#383a42", accent: "#4078f2",
        indicatorInactive: "#a0a1a7")
}
