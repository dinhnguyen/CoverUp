# CoverUp Design Document

**Date**: 2026-01-22
**Author**: Design Session

## Overview

CoverUp is a macOS menu bar application that minimizes windows from configured applications when triggered by a global hotkey.

### Purpose

Quickly declutter the desktop by minimizing all windows from selected applications with a single keyboard shortcut.

### Tech Stack

- Swift + SwiftUI for the UI
- AppKit for window management
- Carbon/CGEvent for global hotkey interception
- UserDefaults for configuration persistence
- ServiceManagement for launch-at-login

### Core Behavior

- **Hotkey Mode**: Minimize-only (not toggle)
- **App Handling**: Skip apps with no open windows, continue silently
- **Hotkey Methods**: Both menu item and event tap supported
- **Launch**: Opt-in launch at login

---

## Architecture

### Project Structure

```
CoverUp/
├── CoverUpApp.swift          # App entry, menu bar only
├── Views/
│   ├── ContentView.swift     # Main UI: app picker, settings
│   ├── AppPickerView.swift   # Browse/select installed apps
│   └── HotkeyConfigView.swift # Configure global hotkey
├── Services/
│   ├── WindowManager.swift   # Find/minimize windows via NSWorkspace
│   ├── HotkeyManager.swift   # Register & handle global hotkeys
│   └── AppLister.swift       # Get installed applications
├── Models/
│   └── TargetApp.swift       # App model with bundle ID, name, icon
└── Resources/
    └── Assets.xcassets
```

### Configuration Storage (UserDefaults)

| Key | Type | Description |
|-----|------|-------------|
| `targetApps` | `[String]` | Bundle identifiers of selected apps |
| `hotkeyType` | `String` | "menuItem" or "eventTap" |
| `hotkeyModifiers` | `[UInt32]` | Modifier flags |
| `hotkeyKeyCode` | `UInt16` | Virtual key code |
| `launchAtLogin` | `Bool` | Launch at system login |

---

## Components

### CoverUpApp.swift

Main app entry point that:
- Configures app as menu bar only (no dock icon)
- Shows menu bar dropdown on click
- Initializes services on launch

### ContentView.swift

Main settings interface:
- List of configured target apps with remove button
- "Add Apps" button to open AppPickerView
- Hotkey configuration section
- Launch at login toggle
- Accessibility status indicator

### AppPickerView.swift

Application picker interface:
- Lists all apps from `/Applications` and `~/Applications`
- Shows app icon, name, and bundle ID
- Search/filter functionality
- Multi-select with checkmarks
- Confirms selection, saves to `targetApps`

### HotkeyConfigView.swift

Hotkey configuration interface:
- Method selector: "System Menu Item" or "Global Event Tap"
- Key recorder: press desired key combination
- Validates for conflicts
- Saves configuration to UserDefaults

### WindowManager.swift

Handles window operations:
- `getWindows(for bundleId: String) -> [NSWindow]`
- `minimize(windows: [NSWindow])`
- Iterates configured apps, finds running apps, minimizes all windows

### HotkeyManager.swift

Handles hotkey registration:
- `registerHotkey(type: HotkeyType, modifiers: [UInt32], keyCode: UInt16) -> Bool`
- `unregisterHotkey()`
- Menu item shortcut via Carbon API
- Event tap via CGEventTapCreate
- Callbacks to trigger WindowManager

### AppLister.swift

Enumerates installed applications:
- `getInstalledApps() -> [TargetApp]`
- Reads from standard application directories
- Extracts bundle ID, name, icon

### TargetApp.swift

Data model:
```swift
struct TargetApp: Identifiable, Codable {
    let id: String           // Bundle identifier
    let name: String         // Display name
    let bundleId: String     // Same as id
}
```

---

## Data Flow

### Normal Operation

1. App launches, loads configuration from UserDefaults
2. User opens menu bar dropdown → ContentView displays
3. User clicks "Add Apps" → AppPickerView shows installed apps
4. User selects apps, confirms → updates `targetApps` in UserDefaults
5. User configures hotkey → HotkeyManager registers the shortcut
6. User presses hotkey globally → HotkeyManager detects trigger
7. WindowManager iterates `targetApps`, finds running apps, minimizes windows
8. Apps with no windows are skipped silently

### Hotkey Trigger Flow

```
User presses hotkey
       ↓
HotkeyManager detects (menu or event tap)
       ↓
WindowManager.minimize(targetApps)
       ↓
For each bundleId in targetApps:
    - Find running application
    - Get all windows
    - Minimize each window
       ↓
Complete (skip apps with no windows)
```

---

## Error Handling

### Hotkey Registration

| Scenario | Handling |
|----------|----------|
| Event tap fails (no accessibility) | Show alert with System Preferences instructions |
| Menu shortcut conflicts | Alert user, suggest alternate key |
| Both methods fail | Disable hotkey, show clear error message |

### Window Operations

| Scenario | Handling |
|----------|----------|
| App not running | Skip silently |
| No windows | Skip silently |
| AX API permission denied | Log error, continue |
| App unresponsive | Timeout after 2s, skip |

### Accessibility Permissions

- Check status via `AXIsProcessTrusted()` on launch
- Prompt user on first launch if not granted
- Show inline help with "Open System Preferences" button if missing
- Disable hotkey feature until granted

### Launch at Login

- Use `SMLoginItemSetEnabled()` from ServiceManagement
- Check if already registered before re-registering
- Handle sandbox limitations (may need entitlements)

---

## Edge Cases

### Configuration

- Invalid bundle ID in config → filter out on load
- App deleted after selection → gracefully skip at runtime
- Corrupted UserDefaults → reset to defaults

### Runtime

- App suspended but not running → skip (no windows)
- Fullscreen windows → may not minimize, handle gracefully
- Hidden apps → windows still minimized
- System apps with restricted access → skip with log

---

## Future Considerations (Post-v1)

- Window exclusion rules (minimize all except specific windows)
- Multiple hotkey profiles
- Visual feedback notification on minimize
- Restore functionality (toggle mode)
- Shortcut conflicts with other apps
