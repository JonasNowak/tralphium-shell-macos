# Tralphium for macOS: Port Plan

This repo (`tralphium-shell-macos`) is the macOS edition of
[tralphium-shell](https://github.com/JonasNowak/tralphium-shell). The original
is a Quickshell/QML shell for Wayland (Mango WM). **Quickshell does not run on
macOS**, so this is a port, not a patch: same look, same features, same config
concepts, rebuilt as a native Swift app.

Reference project: [ApolloShell](https://github.com/Silvertree2010/ApolloShell)
(MIT), a native Swift shell for macOS 26. We follow its architecture and
conventions where they fit. We do not copy its feature set wholesale.

Decisions (agreed with the owner):

- **Native Swift (AppKit + SwiftUI)**, chosen for the best CPU/GPU efficiency. No Qt, no web views.
- **Linux/Quickshell code is removed** from this repo. The original repo remains the Linux version; history here keeps it too (`git show upstream/main:<path>`).
- Remotes: `origin` = this repo, `upstream` = the Linux original. GitHub does not allow forking your own repo, so this is a fresh repo with the full history pushed.

## 1. Principles (from [agents.md](agents.md), adapted)

- **Lightweight:** idle shell uses ~0% CPU. Everything is event driven (notifications, run-loop sources, CoreAudio listeners). No polling timers except the clock tick. Hidden panels are ordered out, not just transparent.
- **KISS:** no third-party dependencies (no Sparkle, no Homebrew tap, no auto-updater). Plain SwiftPM, no Xcode project.
- **macOS native:** public APIs first. Private APIs only through `dlopen`/`dlsym` with a fallback or the feature switched off. Never crash because Apple changed something.
- **Modular:** UI-free logic in `TralphiumCore` (tested), AppKit/SwiftUI in `Tralphium`.

## 2. Toolchain and target

| Item | Choice |
| --- | --- |
| OS | macOS 26 (Tahoe) or later (Liquid Glass via `glassEffect` / `NSGlassEffectView`). Dev machine runs macOS 27 |
| Language | Swift 6 language mode, strict concurrency, UI on `@MainActor` |
| Build | `swift build` with the Command Line Tools, pinned SDK like ApolloShell's `build.sh` |
| Tests | Swift Testing, `./test.sh` |
| App | `LSUIElement` accessory app (no Dock icon, no menu), assembled by `scripts/assemble-app.sh` |
| Bundle ID | `io.github.jonasnowak.tralphium` |

## 3. Layout

```
Package.swift
Sources/TralphiumCore/    pure logic: config, palettes, pins, app catalog, fuzzy match, battery/volume models
Sources/Tralphium/        app: ShellPanel, Shelf, Launchpad, ControlPanel, PowerMenu, Toasts, Settings, services
Tests/TralphiumCoreTests/
Support/Info.plist, AppIcon.icns
scripts/assemble-app.sh, setup-signing.sh
build.sh, test.sh
```

Mapping of the old modules: `components/*` → `Sources/Tralphium/<Feature>/`,
`services/*` → `Sources/Tralphium/Services/`, `themes/*` → `TralphiumCore/Theme*.swift`,
`widgets/*` → `Sources/Tralphium/Widgets/` (small SwiftUI views).

## 4. Feature mapping

| Tralphium (Linux) | macOS implementation | Notes |
| --- | --- | --- |
| Shelf (`PanelWindow`, layer-shell) | `ShellPanel` (borderless `NSPanel`, non-activating, `.statusBar` level, `canJoinAllSpaces`) docked bottom/left/right | macOS has no exclusive zone. The shelf overlays windows. Offer to auto-hide Apple's Dock (`com.apple.dock` defaults), like ApolloShell's `AppleDockHiding` |
| Shelf auto-hide, position | Same options; hover tracking via `NSTrackingArea`, 4 px sliver | Animated by frame, not per-frame redraw |
| Taskbar (`ToplevelManager`) | Pinned + running apps from `NSWorkspace` (launch/terminate/activate/hide/unhide notifications). Drag-and-drop moveable icons to reorder or pin. Click activates, Option-click or context menu hides / unhides in background. Right-click: Pin/Unpin, Hide, Unhide in Background, Quit | Per-app, not per-window. |
| Pins, hidden apps | `PinnedList`, `HiddenApps` in Core, JSON persisted. Launchpad hidden apps drawer and hide/unhide context actions | Keyed by bundle ID |
| Launchpad + `list_apps.py` | Scan `/Applications`, `/System/Applications`, `~/Applications` (+ `/System/Cryptexes`), icons via `NSWorkspace.icon(forFile:)`. Fuzzy search, web-search fallback | Global hotkey via Carbon `RegisterEventHotKey` (no permission needed). Default ⌥Space |
| Control panel | Implemented (Quick settings pop-up docked above status area: network, bluetooth, DND, night shift, theme cycle, screen capture, volume with audio output sink picker, brightness, date, battery, session buttons, blurred glass background) | Replaces QML ControlPanel |
| Volume / sinks (PipeWire) | CoreAudio (`AudioObjectAddPropertyListener`), default output device, output list | Event driven |
| Brightness (sysfs) | `DisplayServices` via `dlopen` for built-in display. Hidden if unavailable | |
| Battery (sysfs) | IOKit `IOPSNotificationCreateRunLoopSource` | Replaces 10 s polling |
| Network (`nmcli`) | CoreWLAN (SSID, power toggle, scan), `CWEventDelegate` | Settings pane opens System Settings for full control |
| Bluetooth (`bluetui`) | IOBluetooth: power state, paired devices, connect/disconnect | Toggle power via private `IOBluetoothPreferenceSetControllerPowerState` through `dlsym` |
| VPN | `scutil --nc list/start/stop` | |
| Night Light (`gammastep`) | Night Shift via `CBBlueLightClient` (CoreBrightness, `dlopen`) | Hidden if missing |
| Do Not Disturb | Run a user Shortcut (`shortcuts run`) or open Focus settings. Public API does not exist | Documented limitation |
| Screenshot (`grim`/`slurp`) | `/usr/sbin/screencapture` (`-i` area, full screen, to clipboard/file) | Needs Screen Recording permission only for window thumbnails, not for `screencapture` |
| Share (`localsend`) | `NSSharingService` / AirDrop picker | |
| Power menu (`systemctl`, `loginctl`) | Shutdown/Restart/Log out via System Events Apple events, Sleep via `pmset sleepnow`, Lock via `pmset displaysleepnow` | Needs `NSAppleEventsUsageDescription` |
| Notifications server + Toasts | **Cannot intercept macOS Notification Center.** Toasts become shell-internal (battery, volume, screenshot saved, errors). Own notifications use `UNUserNotificationCenter` | `NotificationService`/`NotificationCard` shrink to a toast queue |
| TopBar ("Googlebook" bar) | **Dropped in v1.** macOS has its own menu bar. May return as a thin clock/status bar | |
| Wallpaper | `NSWorkspace.setDesktopImageURL` on all screens | No extra window, no GPU cost |
| Settings window (11 pages) | **Removed** (owner decision). No settings UI and no pages. Configuration is `config.json` with hot reload, plus the control panel toggles (theme, night shift, etc.). The control panel's Settings button becomes "Open config" and opens the file in the default editor | |
| Themes (8 QML palettes) | `ThemePalette` struct in Core with the same names: nord, catppuccin-{mocha,macchiato,frappe,latte}, kanagawa, one-dark, one-light | Glass tint + accent from palette |
| Material Symbols font | **SF Symbols.** Remove the 4 MB-class font asset | |
| `qs ipc call shell …` | URL scheme `tralphium://toggleLaunchpad`, `toggleControlPanel`, `powerMenu`, `screenshot`, `setTheme?name=`, `reload` | Bind in Shortcuts/Raycast/skhd. `open -g tralphium://…` |
| Autostart service | `SMAppService.mainApp` login item | |
| Config `~/.config/tralphium/config.json` | `~/Library/Application Support/Tralphium/config.json`, same keys where meaningful. Hot reload with `DispatchSource` file watcher. Missing/invalid keys fall back to defaults (lenient decoding) | `apps.terminal` etc. default to Terminal.app, Finder, Activity Monitor, TextEdit |

## 5. Cleanup list (Linux leftovers)

Junk, removable immediately: `qs.log`, `run.log`, `screenshot*.png`, `grab.qml`,
`grab_icons.qml`, `dump_tray.qml`, `replace.py`, `update_config.py`.

Removed after the matching feature is ported: all `*.qml`, `etc/` (`list_apps.py`,
`get_sinks.sh`, `mango_reload.py`), `assets/fonts/`.

Also: add `.gitignore` (`.build/`, `build/`, `dist/`, `.DS_Store`, `.local.env`), rewrite
[README.md](README.md) for macOS (dependencies section disappears: nothing to install),
fix `agents.md` Mango/Quickshell wording.

## 6. Phases

Each phase ends with: build green, tests green, commit, push.

1. **Repo + plan.** Create repo, this plan, `agents.md` reference. *(done)*
2. **Scaffold.** `Package.swift` (Core + app + tests), `build.sh`, `test.sh`, `Info.plist`, `assemble-app.sh`, `ShellPanel`, accessory app lifecycle, single instance, `.gitignore`, junk deletion. Result: app launches and shows an empty themed shelf. *(done)*
3. **Core logic + tests.** *(done)* Config (lenient JSON, defaults, watcher), 8 palettes, `PinnedList`, `HiddenApps`, fuzzy matcher, app catalog, battery/volume description strings.
4. **Shelf.** *(done)* Launcher button, taskbar (pinned + running, indicators, context menu, pin/unpin/quit), status area (Wi-Fi, volume, battery, clock), bottom bar docked, auto-hide with hover sliver.
5. **Launchpad.** *(done)* Fullscreen overlay panel, auto-focused search, app grid, web-search fallback, global hotkey (⌥Space), Esc / backdrop dismiss, Enter key launch.
6. **Control panel & Power menu.** *(done)* Control panel (quick toggles, volume slider with audio sink device picker, brightness slider, session actions, open config.json) and centered modal Power menu (Shut down, Restart, Sleep, Sign out, Lock). Transparency effects enabled with NSVisualEffectView across all panels. Docker (shelf) auto-hides when any application enters fullscreen.
7. **Power menu, toasts, URL scheme, login item, wallpaper.** (URL scheme & login item integration for Shelf/Launchpad/ControlPanel/PowerMenu).
8. ~~Settings window~~ removed from scope.
9. **Final cleanup.** *(done)* Delete Linux leftover files, rewrite README for macOS, tag `0.20`.

## 7. Verification

- `swift build -c release` and `./test.sh` pass.
- Views are checked visually: render off-screen (`NSHostingView` → `cacheDisplay` → PNG) and by running the app and capturing with `screencapture`.
- Idle check: Activity Monitor / `top -pid` shows ~0% CPU with all panels closed.
- Features that need permissions (Accessibility, Screen Recording, Apple Events) degrade gracefully when denied and say so in the UI.

## 8. Build notes

- The repo lives in `~/Documents`, which iCloud's file provider syncs. It stamps `FinderInfo` on build products and `codesign` then fails with "resource fork, Finder information, or similar detritus not allowed". `build.sh` and `test.sh` therefore build in `~/Library/Caches/Tralphium/build` (override with `TRALPHIUM_BUILD_DIR`).
- With only the Command Line Tools, `test.sh` adds the Swift Testing search paths by hand (same trick as ApolloShell).
- The terminal running the agent has no Screen Recording permission, so UI checks use the window list (`CGWindowListCopyWindowInfo`) and off-screen rendering instead of `screencapture`.

## 9. Known limitations and open questions

- No space reservation for windows (macOS has no equivalent of layer-shell exclusive zones). Mitigation: Apple Dock auto-hide helper, optional "keep shelf above windows" level.
- No interception of system notifications.
- Window-level taskbar entries need Accessibility. Decide after phase 4.
- Private APIs (DisplayServices, CoreBrightness, IOBluetooth power) can break on macOS updates. Each is isolated behind a protocol with a no-op fallback.
- Signing: ad-hoc by default. `scripts/setup-signing.sh` creates a local identity so Accessibility grants survive rebuilds.
