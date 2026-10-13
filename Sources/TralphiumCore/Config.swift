import Foundation

public enum ShelfPosition: String, Sendable, CaseIterable {
    case bottom, left, right

    public var isVertical: Bool { self != .bottom }
}

/// Applications the shelf context menu opens, as app names for `open -a`.
public struct AppCommands: Equatable, Sendable {
    public var terminal = "Terminal"
    public var fileManager = "Finder"
    public var taskManager = "Activity Monitor"
    public var editor = "TextEdit"
    public var browser = "Safari"

    public init() {}
}

/// `config.json`. Decoding is lenient: a missing key, a wrong type or an
/// unknown value falls back to the default, so a typo never breaks the shell.
public struct TralphiumConfig: Equatable, Sendable {
    public var theme = ThemePalette.defaultName
    /// Image path. Empty keeps the current desktop picture.
    public var wallpaper = ""
    public var shelfAutoHide = false
    public var shelfPosition = ShelfPosition.bottom
    public var searchEngine = "DuckDuckGo"
    /// Do Not Disturb for the shell's own toasts.
    public var notificationsEnabled = true
    /// ⌥Space opens the launchpad.
    public var launchpadHotkey = true
    public var launchAtLogin = false
    /// Name of a Shortcuts shortcut that toggles Do Not Disturb. macOS has no
    /// public API for it. Empty opens the Focus settings instead.
    public var dndShortcut = ""
    /// Opacity of the bottom shelf background tint (0.0 to 1.0).
    public var shelfOpacity: Double = 0.50
    public var apps = AppCommands()

    public init() {}

    public init(json: Data?) {
        guard let json,
              let object = try? JSONSerialization.jsonObject(with: json),
              let dict = object as? [String: Any] else { return }

        func string(_ key: String, in d: [String: Any]) -> String? { d[key] as? String }
        func bool(_ key: String, in d: [String: Any]) -> Bool? { d[key] as? Bool }
        func double(_ key: String, in d: [String: Any]) -> Double? {
            if let num = d[key] as? NSNumber { return num.doubleValue }
            return nil
        }

        if let v = string("theme", in: dict), !v.isEmpty { theme = v }
        if let v = string("wallpaper", in: dict) { wallpaper = v }
        if let v = bool("shelfAutoHide", in: dict) { shelfAutoHide = v }
        if let v = string("shelfPosition", in: dict), let p = ShelfPosition(rawValue: v) { shelfPosition = p }
        if let v = string("searchEngine", in: dict), !v.isEmpty { searchEngine = v }
        if let v = bool("notificationsEnabled", in: dict) { notificationsEnabled = v }
        if let v = bool("launchpadHotkey", in: dict) { launchpadHotkey = v }
        if let v = bool("launchAtLogin", in: dict) { launchAtLogin = v }
        if let v = string("dndShortcut", in: dict) { dndShortcut = v }
        if let v = double("shelfOpacity", in: dict) { shelfOpacity = max(0.0, min(1.0, v)) }
        if let a = dict["apps"] as? [String: Any] {
            if let v = string("terminal", in: a), !v.isEmpty { apps.terminal = v }
            if let v = string("fileManager", in: a), !v.isEmpty { apps.fileManager = v }
            if let v = string("taskManager", in: a), !v.isEmpty { apps.taskManager = v }
            if let v = string("editor", in: a), !v.isEmpty { apps.editor = v }
            if let v = string("browser", in: a), !v.isEmpty { apps.browser = v }
        }
    }

    /// JSON for writing back. Keys this version does not know about stay in
    /// the file (`existing` is the file's current content).
    public func encoded(merging existing: Data?) -> Data {
        var dict = (existing.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]) ?? [:]
        dict["theme"] = theme
        dict["wallpaper"] = wallpaper
        dict["shelfAutoHide"] = shelfAutoHide
        dict["shelfPosition"] = shelfPosition.rawValue
        dict["searchEngine"] = searchEngine
        dict["notificationsEnabled"] = notificationsEnabled
        dict["launchpadHotkey"] = launchpadHotkey
        dict["launchAtLogin"] = launchAtLogin
        dict["dndShortcut"] = dndShortcut
        dict["shelfOpacity"] = shelfOpacity
        var appsDict = dict["apps"] as? [String: Any] ?? [:]
        appsDict["terminal"] = apps.terminal
        appsDict["fileManager"] = apps.fileManager
        appsDict["taskManager"] = apps.taskManager
        appsDict["editor"] = apps.editor
        appsDict["browser"] = apps.browser
        dict["apps"] = appsDict
        // Sorted keys keep the file stable between saves. Plain dictionaries
        // of JSON values always serialise.
        return (try? JSONSerialization.data(
            withJSONObject: dict, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
    }
}
