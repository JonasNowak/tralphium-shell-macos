import AppKit
import Carbon.HIToolbox
import ServiceManagement

/// A global keyboard shortcut. Carbon's hot key API needs no permissions.
@MainActor
final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: @MainActor () -> Void

    init?(keyCode: Int, modifiers: Int, action: @escaping @MainActor () -> Void) {
        self.action = action
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, context in
            guard let context else { return noErr }
            let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec, context, &handler) == noErr else {
            return nil
        }
        let id = EventHotKeyID(signature: OSType(0x5452_4C50), id: 1)  // 'TRLP'
        guard RegisterEventHotKey(
            UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &reference) == noErr else {
            return nil
        }
    }

    func unregister() {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
        reference = nil
        handler = nil
    }
}

/// Sets the desktop picture on every screen.
@MainActor
enum WallpaperService {
    private static var applied = ""

    static func apply(_ path: String) {
        guard !path.isEmpty, path != applied else { return }
        let expanded = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else { return }
        applied = path
        let url = URL(fileURLWithPath: expanded)
        for screen in NSScreen.screens {
            try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
    }
}

/// Start at login, through the system's login item service.
@MainActor
enum LoginItem {
    static func set(enabled: Bool) {
        // Only an installed app bundle can register itself.
        guard Bundle.main.bundleIdentifier != nil else { return }
        let service = SMAppService.mainApp
        let isOn = service.status == .enabled
        guard isOn != enabled else { return }
        if enabled { try? service.register() } else { try? service.unregister() }
    }
}
