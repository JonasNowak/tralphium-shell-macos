# Tralphium for macOS (v0.20)

A lightweight, native desktop shell for macOS built in Swift (AppKit + SwiftUI).

This is the native macOS edition of Tralphium, designed with a focus on simplicity (KISS), performance, and seamless macOS integration.

## Features

### Bottom Shelf
- **Launcher Button:** Tralphium ring-and-dot button to toggle Launchpad.
- **Taskbar:** Pinned applications and active running applications with crisp icons, running/active indicators, and context menus (Pin/Unpin, Quit).
- **Status Area:** Event-driven system indicators:
  - Wi-Fi status and power toggle (CoreWLAN)
  - Audio status and mute toggle (CoreAudio)
  - Battery percentage and charge status (IOKit)
  - Real-time digital clock and date tooltip
- **Auto-Hide:** Optional auto-hide behavior with a 4px hover sliver that slides in smoothly when hovered.
- **Context Menu:** Right-click anywhere on the shelf to quickly open Terminal, Files (Finder), Activity Monitor, or the configuration file.

### Launchpad
- **Fast Application Search:** Fullscreen overlay with instant fuzzy search across installed macOS applications.
- **Keyboard Navigation:** Type to filter, press Enter to immediately launch the top match.
- **Web Search Fallback:** Search the web directly from the launcher if no local app matches.
- **Install Web App:** Type a URL or app name with no local matches and click "Install as Web App" to instantly create a standalone Helium app.
- **Global Hotkey:** Press `⌥Space` (Option + Space) anywhere in macOS to toggle Launchpad.
- **URL Scheme Integration:** Trigger actions from Raycast, Shortcuts, or terminal via `tralphium://toggleLaunchpad`, `tralphium://openLaunchpad`, or `tralphium://closeLaunchpad`.

### Chrome OS-Style Web Applications (Helium)
Tralphium allows creating first-class, standalone Chrome OS-style web apps powered by Helium (`net.imput.helium`):
- **Standalone Windows:** Runs via Helium `--app="<url>"` mode with no browser tabs or navigation chrome.
- **Independent macOS App Bundles:** Packaged directly into `~/Applications/<Name>.app` with high-resolution app icon generation (Apple `.icns` standard sizes), executable launcher, and ad-hoc code signature.
- **Auto-Discovery:** Immediately indexed in Tralphium's Launchpad and pinnable to the shelf taskbar.
- **Ways to Add:**
  - **Shelf:** Right-click shelf and choose "Add Web App (Helium)...".
  - **Launchpad:** Enter a URL or site name and click "Install as Web App".
  - **CLI:** Run `./scripts/add-webapp.sh <url> [name] [--open]`.
  - **URL Scheme:** `open -g "tralphium://addWebApp?url=https://youtube.com&name=YouTube"`.

## Design & Architecture

- **macOS Native:** Built with Swift 6, AppKit, and SwiftUI using Swift Package Manager. No third-party dependencies.
- **Zero Idle CPU (~0%):** Completely event-driven using system notifications and run-loop sources (`NSWorkspace`, `CoreAudio`, `IOKit`, `CoreWLAN`). No polling loops.
- **Nord Theme:** Clean arctic Nord aesthetics with translucent glass backgrounds.
- **Modular:** UI-independent logic and models in `TralphiumCore` covered by unit tests; UI in `Tralphium`.

## Building and Running

### Requirements
- macOS 14+ (macOS 26+ compatible)
- Apple Command Line Tools or Xcode

### Build & Run
```bash
# Build release, assemble ~/Applications/Tralphium.app, and start
./build.sh
```

### Run Tests
```bash
./test.sh
```

## Configuration

Settings are stored in:
`~/Library/Application Support/Tralphium/config.json`

The file is automatically created with defaults on first launch and **hot-reloads immediately** upon saving changes.

```json
{
  "theme": "nord",
  "shelfAutoHide": false,
  "shelfPosition": "bottom",
  "launchpadHotkey": true,
  "searchEngine": "DuckDuckGo",
  "apps": {
    "terminal": "Terminal",
    "fileManager": "Finder",
    "taskManager": "Activity Monitor",
    "editor": "TextEdit",
    "browser": "Safari"
  }
}
```

## URL Scheme

Tralphium registers the `tralphium://` URL scheme for system integration:
- `open -g tralphium://toggleLaunchpad` - Toggle the Launchpad overlay
- `open -g tralphium://openLaunchpad` - Open the Launchpad
- `open -g tralphium://closeLaunchpad` - Close the Launchpad
- `open -g tralphium://reloadConfig` - Force reload configuration from disk
- `open -g "tralphium://addWebApp?url=https://..."` - Create and register a Helium web app
- `open -g tralphium://refreshApps` - Refresh application index in Launchpad and Shelf
