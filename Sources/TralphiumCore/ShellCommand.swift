import Foundation

/// Actions other tools can trigger with `open -g tralphium://<command>`; the
/// replacement for the Linux `qs ipc call shell <function>`.
public enum ShellCommand: Equatable, Sendable {
    case toggleLaunchpad
    case openLaunchpad
    case closeLaunchpad
    case toggleControlPanel
    case openPowerMenu
    case takeScreenshot
    case toggleTheme
    case setTheme(String)
    case reloadConfig
    case unhide(String)
    case unhideInBackground(String)
    case unhideAll
    case hide(String)

    public static let scheme = "tralphium"

    /// `tralphium://setTheme?name=nord` or `tralphium://setTheme/nord`.
    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              let command = url.host?.lowercased() else { return nil }
        switch command {
        case "togglelaunchpad": self = .toggleLaunchpad
        case "openlaunchpad": self = .openLaunchpad
        case "closelaunchpad": self = .closeLaunchpad
        case "togglecontrolpanel": self = .toggleControlPanel
        case "openpowermenu": self = .openPowerMenu
        case "takescreenshot": self = .takeScreenshot
        case "toggletheme": self = .toggleTheme
        case "reloadconfig": self = .reloadConfig
        case "unhideall": self = .unhideAll
        case "settheme":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let fromQuery = items?.first { $0.name == "name" }?.value
            let fromPath = url.pathComponents.dropFirst().first
            guard let name = fromQuery ?? fromPath, !name.isEmpty else { return nil }
            self = .setTheme(name)
        case "unhide":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let fromQuery = items?.first { $0.name == "id" }?.value
            let fromPath = url.pathComponents.dropFirst().first
            guard let id = fromQuery ?? fromPath, !id.isEmpty else { return nil }
            self = .unhide(id)
        case "unhideinbackground":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let fromQuery = items?.first { $0.name == "id" }?.value
            let fromPath = url.pathComponents.dropFirst().first
            guard let id = fromQuery ?? fromPath, !id.isEmpty else { return nil }
            self = .unhideInBackground(id)
        case "hide":
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let fromQuery = items?.first { $0.name == "id" }?.value
            let fromPath = url.pathComponents.dropFirst().first
            guard let id = fromQuery ?? fromPath, !id.isEmpty else { return nil }
            self = .hide(id)
        default: return nil
        }
    }
}

/// Entries shown in the taskbar: pinned apps first (in pin order), then
/// running apps that are not pinned.
public enum TaskbarModel {
    public struct Item: Equatable, Sendable {
        public let id: String
        public let isPinned: Bool
    }

    public static func items(pinned: IDList, running: [String]) -> [Item] {
        var result = pinned.ids.map { Item(id: $0, isPinned: true) }
        for id in running where !pinned.contains(id) && !result.contains(where: { $0.id.caseInsensitiveCompare(id) == .orderedSame }) {
            result.append(Item(id: id, isPinned: false))
        }
        return result
    }
}

extension ThemePalette {
    /// The theme after `name` in the built-in order, wrapping around.
    public static func next(after name: String) -> ThemePalette {
        let themes = all
        guard let i = themes.firstIndex(where: { $0.name == name }) else { return nord }
        return themes[(i + 1) % themes.count]
    }
}
