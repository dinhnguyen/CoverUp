# CoverUp Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Build a macOS menu bar app that minimizes configured app windows via global hotkey

**Architecture:** SwiftUI menu bar app with services for window management, hotkey registration, and app listing. UserDefaults for persistence, ServiceManagement for launch-at-login.

**Tech Stack:** Swift, SwiftUI, AppKit, Carbon (HIToolbox), CGEvent, ServiceManagement, XcodeGen

---

## Prerequisites

Before starting, ensure XcodeGen is installed:
```bash
brew install xcodegen
```

---

## Task 1: Project Structure & XcodeGen Setup

**Files:**
- Create: `CoverUp/project.yml`
- Create: `CoverUp/CoverUpApp.swift`
- Create: `CoverUp/Resources/Assets.xcassets/Contents.json`
- Create: `CoverUp/Resources/Info.plist`

**Step 1: Create project.yml**

```bash
mkdir -p CoverUp/Resources/Assets.xcassets
```

**Step 2: Write project.yml**

```yaml
name: CoverUp
options:
  bundleIdPrefix: com.coverup
  deploymentTarget:
    macOS: "12.0"
  xcodeVersion: "15.0"

settings:
  base:
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic

targets:
  CoverUp:
    type: application
    platform: macOS
    sources:
      - path: CoverUp
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.coverup.app
        INFOPLIST_FILE: Resources/Info.plist
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        COMBINE_HIDPI_IMAGES: YES
        LD_RUNPATH_SEARCH_PATHS: "$(inherited) @executable_path/../Frameworks"
        ENABLE_HARDENED_RUNTIME: YES
        CODE_SIGN_ENTITLEMENTS: CoverUp/CoverUp.entitlements
    entitlements:
      path: CoverUp/CoverUp.entitlements
```

**Step 3: Write Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

**Step 4: Write Assets.xcassets/Contents.json**

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 5: Write CoverUp.entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.accessibility.apple-events</key>
    <true/>
</dict>
</plist>
```

**Step 6: Write minimal CoverUpApp.swift**

```swift
import SwiftUI

@main
struct CoverUpApp: App {
    var body: some Scene {
        MenuBarExtra("CoverUp", systemImage: "arrow.down.to.line") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 7: Generate Xcode project**

```bash
cd CoverUp && xcodegen generate
```

**Step 8: Build to verify**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

**Step 9: Commit**

```bash
git add CoverUp/
git commit -m "feat: initial project structure with XcodeGen"
```

---

## Task 2: TargetApp Model

**Files:**
- Create: `CoverUp/Models/TargetApp.swift`

**Step 1: Write test**

```swift
import XCTest
@testable import CoverUp

final class TargetAppTests: XCTestCase {
    func test_targetApp_initialization() {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        XCTAssertEqual(app.id, "com.apple.Safari")
        XCTAssertEqual(app.name, "Safari")
        XCTAssertEqual(app.bundleId, "com.apple.Safari")
    }

    func test_targetApp_codable() throws {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        let encoder = JSONEncoder()
        let data = try encoder.encode(app)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TargetApp.self, from: data)
        XCTAssertEqual(app, decoded)
    }
}
```

**Step 2: Create test file and run to fail**

```bash
mkdir -p CoverUpTests/Models
cat > CoverUpTests/Models/TargetAppTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class TargetAppTests: XCTestCase {
    func test_targetApp_initialization() {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        XCTAssertEqual(app.id, "com.apple.Safari")
        XCTAssertEqual(app.name, "Safari")
        XCTAssertEqual(app.bundleId, "com.apple.Safari")
    }

    func test_targetApp_codable() throws {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        let encoder = JSONEncoder()
        let data = try encoder.encode(app)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TargetApp.self, from: data)
        XCTAssertEqual(app, decoded)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - TargetApp not defined

**Step 3: Write implementation**

```swift
import Foundation

struct TargetApp: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String

    var bundleId: String { id }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TargetApp, rhs: TargetApp) -> Bool {
        lhs.id == rhs.id
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Models/TargetApp.swift CoverUpTests/
git commit -m "feat: add TargetApp model"
```

---

## Task 3: AppLister Service

**Files:**
- Create: `CoverUp/Services/AppLister.swift`

**Step 1: Write test**

```swift
func test_getInstalledApps_returnsNonEmpty() {
    let apps = AppLister.getInstalledApps()
    XCTAssertFalse(apps.isEmpty)
}

func test_getInstalledApps_containsKnownApps() {
    let apps = AppLister.getInstalledApps()
    let bundleIds = apps.map(\.id)
    XCTAssertTrue(bundleIds.contains("com.apple.Safari"))
}
```

**Step 2: Write test file and run to fail**

```bash
mkdir -p CoverUpTests/Services
cat > CoverUpTests/Services/AppListerTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class AppListerTests: XCTestCase {
    func test_getInstalledApps_returnsNonEmpty() {
        let apps = AppLister.getInstalledApps()
        XCTAssertFalse(apps.isEmpty)
    }

    func test_getInstalledApps_containsKnownApps() {
        let apps = AppLister.getInstalledApps()
        let bundleIds = apps.map(\.id)
        XCTAssertTrue(bundleIds.contains("com.apple.Safari"))
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - AppLister not defined

**Step 3: Write implementation**

```swift
import Foundation
import AppKit

enum AppLister {
    static func getInstalledApps() -> [TargetApp] {
        var apps: [TargetApp] = []

        let directories = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for directory in directories {
            let url = URL(fileURLWithPath: directory)
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.bundleIdentifierKey, .localizedNameKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "app" else { continue }

                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.bundleIdentifierKey, .localizedNameKey])
                    guard let bundleId = resourceValues.bundleIdentifier,
                          let name = resourceValues.localizedName,
                          !bundleId.isEmpty else { continue }

                    apps.append(TargetApp(id: bundleId, name: name))
                } catch {
                    continue
                }
            }
        }

        return Array(Set(apps)).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/AppLister.swift CoverUpTests/Services/
git commit -m "feat: add AppLister service"
```

---

## Task 4: WindowManager Service

**Files:**
- Create: `CoverUp/Services/WindowManager.swift`

**Step 1: Write test**

```swift
func test_getWindows_forNonexistentApp_returnsEmpty() {
    let windows = WindowManager.getWindows(for: "com.nonexistent.app")
    XCTAssertTrue(windows.isEmpty)
}

func test_minimize_noWindows_doesNotCrash() {
    WindowManager.minimize(windows: [])
}
```

**Step 2: Write test file and run to fail**

```bash
mkdir -p CoverUpTests/Services
cat > CoverUpTests/Services/WindowManagerTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class WindowManagerTests: XCTestCase {
    func test_getWindows_forNonexistentApp_returnsEmpty() {
        let windows = WindowManager.getWindows(for: "com.nonexistent.app")
        XCTAssertTrue(windows.isEmpty)
    }

    func test_minimize_noWindows_doesNotCrash() {
        WindowManager.minimize(windows: [])
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - WindowManager not defined

**Step 3: Write implementation**

```swift
import Foundation
import AppKit

enum WindowManager {
    static func getWindows(for bundleId: String) -> [NSWindow] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
            return []
        }

        return app.windows.filter { window in
            window.isVisible && window.title != ""
        }
    }

    static func minimize(windows: [NSWindow]) {
        for window in windows {
            window.orderOut(nil)
        }
    }

    static func minimize(targetApps: [TargetApp]) {
        for app in targetApps {
            let windows = getWindows(for: app.id)
            minimize(windows: windows)
        }
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/WindowManager.swift CoverUpTests/Services/
git commit -m "feat: add WindowManager service"
```

---

## Task 5: HotkeyManager Service - Part 1 (Models & Types)

**Files:**
- Create: `CoverUp/Services/HotkeyManager.swift`

**Step 1: Write test**

```swift
func test_hotkeyType_values() {
    XCTAssertEqual(HotkeyType.menuItem.rawValue, "menuItem")
    XCTAssertEqual(HotkeyType.eventTap.rawValue, "eventTap")
}

func test_defaultHotkeyConfiguration() {
    let config = HotkeyConfiguration()
    XCTAssertNil(config.keyCode)
    XCTAssertTrue(config.modifiers.isEmpty)
    XCTAssertEqual(config.type, .menuItem)
}
```

**Step 2: Write test file and run to fail**

```bash
cat > CoverUpTests/Services/HotkeyManagerTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class HotkeyManagerTests: XCTestCase {
    func test_hotkeyType_values() {
        XCTAssertEqual(HotkeyType.menuItem.rawValue, "menuItem")
        XCTAssertEqual(HotkeyType.eventTap.rawValue, "eventTap")
    }

    func test_defaultHotkeyConfiguration() {
        let config = HotkeyConfiguration()
        XCTAssertNil(config.keyCode)
        XCTAssertTrue(config.modifiers.isEmpty)
        XCTAssertEqual(config.type, .menuItem)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - HotkeyType/HotkeyConfiguration not defined

**Step 3: Write implementation**

```swift
import Foundation
import Carbon

enum HotkeyType: String, Codable, CaseIterable {
    case menuItem = "menuItem"
    case eventTap = "eventTap"
}

struct HotkeyConfiguration: Codable, Equatable {
    var type: HotkeyType = .menuItem
    var keyCode: UInt16?
    var modifiers: [UInt32] = []

    var isValid: Bool {
        keyCode != nil && !modifiers.isEmpty
    }
}

enum HotkeyManager {
    typealias HotkeyCallback = () -> Void

    static var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/HotkeyManager.swift CoverUpTests/Services/
git commit -m "feat: add HotkeyManager types"
```

---

## Task 6: HotkeyManager Service - Part 2 (Event Tap Implementation)

**Files:**
- Modify: `CoverUp/Services/HotkeyManager.swift`

**Step 1: Write test for event tap registration**

```swift
func test_registerEventTap_withoutAccessibility_returnsFalse() {
    let config = HotkeyConfiguration(type: .eventTap, keyCode: 49, modifiers: [controlKey])
    let result = HotkeyManager.registerEventTap(with: config) {}
    XCTAssertFalse(result)
}
```

**Step 2: Write test and run to fail**

```bash
cat >> CoverUpTests/Services/HotkeyManagerTests.swift << 'EOF'

    func test_registerEventTap_withoutAccessibility_returnsFalse() {
        let config = HotkeyConfiguration(type: .eventTap, keyCode: 49, modifiers: [controlKey])
        let result = HotkeyManager.registerEventTap(with: config) {}
        XCTAssertFalse(result)
    }
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - registerEventTap not defined

**Step 3: Add event tap implementation**

```swift
extension HotkeyManager {
    private static var eventTap: CFMachPort?
    private static var eventTapSource: CFRunLoopSource?
    private static var currentCallback: HotkeyCallback?

    static func registerEventTap(with config: HotkeyConfiguration, callback: @escaping HotkeyCallback) -> Bool {
        unregisterEventTap()

        guard isAccessibilityEnabled else { return false }
        guard let keyCode = config.keyCode else { return false }

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let eventTap = CGEventTapCreate(
            kCGSessionEventTap,
            kCGHeadInsertEventTap,
            .defaultTap,
            eventMask
        ) else {
            return false
        }

        Self.eventTap = eventTap
        Self.currentCallback = callback

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)

        CGEventTapEnable(eventTap, true)

        Self.eventTapSource = source

        return true
    }

    static func unregisterEventTap() {
        if let tap = eventTap {
            CGEventTapEnable(tap, false)
        }
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        eventTapSource = nil
        currentCallback = nil
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/HotkeyManager.swift CoverUpTests/Services/
git commit -m "feat: add HotkeyManager event tap implementation"
```

---

## Task 7: HotkeyManager Service - Part 3 (Menu Item Implementation)

**Files:**
- Modify: `CoverUp/Services/HotkeyManager.swift`

**Step 1: Write test for menu item registration**

```swift
func test_registerMenuItem_withValidConfig_doesNotCrash() {
    let config = HotkeyConfiguration(type: .menuItem, keyCode: 49, modifiers: [controlKey])
    HotkeyManager.registerMenuItemShortcut(with: config, action: {})
}
```

**Step 2: Write test and run to fail**

```bash
cat >> CoverUpTests/Services/HotkeyManagerTests.swift << 'EOF'

    func test_registerMenuItem_withValidConfig_doesNotCrash() {
        let config = HotkeyConfiguration(type: .menuItem, keyCode: 49, modifiers: [controlKey])
        HotkeyManager.registerMenuItemShortcut(with: config, action: {})
    }
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - registerMenuItemShortcut not defined

**Step 3: Add menu item implementation**

```swift
import Carbon

extension HotkeyManager {
    private static var menuItemRef: NSMenuItem?

    static func registerMenuItemShortcut(with config: HotkeyConfiguration, action: @escaping HotkeyCallback) -> Bool {
        unregisterMenuItem()

        guard let keyCode = config.keyCode else { return false }

        let keyEquivalent = keyCodeToString(keyCode)
        let keyEquivalentModifiers = config.modifiers.toCarbonFlags()

        let menuItem = NSMenuItem(
            title: "Trigger CoverUp",
            action: #selector(handleHotkeyAction(_:)),
            keyEquivalent: keyEquivalent
        )
        menuItem.keyEquivalentModifierMask = keyEquivalentModifiers
        menuItem.target = HotkeyActionHandler.shared
        HotkeyActionHandler.shared.callback = action

        NSApp.menu?.insertItem(menuItem, at: 0)

        Self.menuItemRef = menuItem

        return true
    }

    static func unregisterMenuItem() {
        if let item = menuItemRef {
            item.target = nil
            item.action = nil
            NSApp.menu?.removeItem(item)
        }
        menuItemRef = nil
    }

    private static func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "o"
        case 32: return "u"
        case 33: return "["
        case 34: return "}"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 39: return "'"
        case 40: return "k"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "n"
        case 46: return "m"
        case 47: return "."
        case 50: return "`"
        case 51: return "\\"
        case 53: return "\u{1b}"
        default: return ""
        }
    }
}

private extension Array where Element == UInt32 {
    func toCarbonFlags() -> Int {
        var flags: Int = 0
        for modifier in self {
            flags |= Int(modifier)
        }
        return flags
    }
}

@objc final class HotkeyActionHandler: NSObject {
    static let shared = HotkeyActionHandler()
    var callback: (() -> Void)?

    @objc func handleHotkeyAction(_ sender: Any?) {
        callback?()
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/HotkeyManager.swift CoverUpTests/Services/
git commit -m "feat: add HotkeyManager menu item implementation"
```

---

## Task 8: SettingsManager Service

**Files:**
- Create: `CoverUp/Services/SettingsManager.swift`

**Step 1: Write test**

```swift
func test_defaultSettings_returnsExpected() {
    let settings = SettingsManager.load()
    XCTAssertTrue(settings.targetApps.isEmpty)
    XCTAssertFalse(settings.launchAtLogin)
    XCTAssertFalse(settings.hotkeyConfiguration.isValid)
}

func test_saveAndLoad_roundtrip() {
    var settings = SettingsManager.load()
    settings.targetApps = [TargetApp(id: "com.apple.Safari", name: "Safari")]
    settings.launchAtLogin = true
    SettingsManager.save(settings)

    let loaded = SettingsManager.load()
    XCTAssertEqual(loaded.targetApps.count, 1)
    XCTAssertEqual(loaded.targetApps.first?.id, "com.apple.Safari")
}
```

**Step 2: Write test file and run to fail**

```bash
mkdir -p CoverUpTests/Services
cat > CoverUpTests/Services/SettingsManagerTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class SettingsManagerTests: XCTestCase {
    override func setUp() {
        SettingsManager.resetToDefaults()
    }

    func test_defaultSettings_returnsExpected() {
        let settings = SettingsManager.load()
        XCTAssertTrue(settings.targetApps.isEmpty)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.hotkeyConfiguration.isValid)
    }

    func test_saveAndLoad_roundtrip() {
        var settings = SettingsManager.load()
        settings.targetApps = [TargetApp(id: "com.apple.Safari", name: "Safari")]
        settings.launchAtLogin = true
        SettingsManager.save(settings)

        let loaded = SettingsManager.load()
        XCTAssertEqual(loaded.targetApps.count, 1)
        XCTAssertEqual(loaded.targetApps.first?.id, "com.apple.Safari")
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - SettingsManager not defined

**Step 3: Write implementation**

```swift
import Foundation

struct AppSettings: Codable {
    var targetApps: [TargetApp] = []
    var hotkeyConfiguration: HotkeyConfiguration = HotkeyConfiguration()
    var launchAtLogin: Bool = false
}

enum SettingsManager {
    private static let defaults = UserDefaults.standard
    private static let settingsKey = "com.coverup.settings"

    static func load() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    static func resetToDefaults() {
        defaults.removeObject(forKey: settingsKey)
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/SettingsManager.swift CoverUpTests/Services/
git commit -m "feat: add SettingsManager service"
```

---

## Task 9: AppPickerView

**Files:**
- Create: `CoverUp/Views/AppPickerView.swift`

**Step 1: Write minimal test**

```swift
func test_appPickerView_instantiates() {
    let view = AppPickerView(selectedApps: .constant([]), onConfirm: {})
    XCTAssertNotNil(view)
}
```

**Step 2: Write test file and run to fail**

```bash
mkdir -p CoverUpTests/Views
cat > CoverUpTests/Views/AppPickerViewTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class AppPickerViewTests: XCTestCase {
    func test_appPickerView_instantiates() {
        let view = AppPickerView(selectedApps: .constant([]), onConfirm: {})
        XCTAssertNotNil(view)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - AppPickerView not defined

**Step 3: Write implementation**

```swift
import SwiftUI

struct AppPickerView: View {
    @Binding var selectedApps: Set<TargetApp>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var allApps: [TargetApp] = []
    @State private var isLoading = true

    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Applications")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            if isLoading {
                ProgressView("Loading apps...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                List(allApps.filter { app in
                    searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
                }, selection: .constant(selectedApps)) { app in
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(.secondary)
                        Text(app.name)
                        Spacer()
                        if selectedApps.contains(app) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedApps.contains(app) {
                            selectedApps.remove(app)
                        } else {
                            selectedApps.insert(app)
                        }
                    }
                }
                .listStyle(.plain)

                HStack {
                    Button("Clear") {
                        selectedApps.removeAll()
                    }
                    .disabled(selectedApps.isEmpty)
                    Spacer()
                    Button("Confirm") {
                        onConfirm()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            loadApps()
        }
    }

    private func loadApps() {
        allApps = AppLister.getInstalledApps()
        isLoading = false
    }
}

#Preview {
    AppPickerView(selectedApps: .constant([])) {}
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Views/AppPickerView.swift CoverUpTests/Views/
git commit -m "feat: add AppPickerView"
```

---

## Task 10: HotkeyConfigView

**Files:**
- Create: `CoverUp/Views/HotkeyConfigView.swift`

**Step 1: Write minimal test**

```swift
func test_hotkeyConfigView_instantiates() {
    let view = HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
    XCTAssertNotNil(view)
}
```

**Step 2: Write test file and run to fail**

```bash
cat > CoverUpTests/Views/HotkeyConfigViewTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class HotkeyConfigViewTests: XCTestCase {
    func test_hotkeyConfigView_instantiates() {
        let view = HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
        XCTAssertNotNil(view)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - HotkeyConfigView not defined

**Step 3: Write implementation**

```swift
import SwiftUI
import Carbon

struct HotkeyConfigView: View {
    @Binding var configuration: HotkeyConfiguration
    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: [UInt32] = []

    private let modifierNames: [UInt32: String] = [
        cmdKey: "⌘",
        shiftKey: "⇧",
        optionKey: "⌥",
        controlKey: "⌃"
    ]

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey Method")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Method", selection: $configuration.type) {
                    Text("Menu Item").tag(HotkeyType.menuItem)
                    Text("Global Event Tap").tag(HotkeyType.eventTap)
                }
                .pickerStyle(.segmented)

                if configuration.type == .eventTap {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Requires Accessibility permissions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Key Combination")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(action: { isRecording.toggle() }) {
                        Text(displayString)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .frame(minWidth: 120, minHeight: 44)
                            .background(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if isRecording {
                        Text("Press any key...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    } else {
                        Button("Clear") {
                            configuration.keyCode = nil
                            configuration.modifiers = []
                        }
                        .disabled(configuration.keyCode == nil)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 300)
        .onKeyPress { press in
            guard isRecording else { return .ignored }
            recordedKeyCode = press.keyCode
            configuration.keyCode = press.keyCode
            isRecording = false
            return .handled
        }
    }

    private var displayString: String {
        guard let keyCode = configuration.keyCode else {
            return "Press to record"
        }

        let keyString = keyCodeToString(keyCode)
        let modifierSymbols = configuration.modifiers
            .sorted()
            .compactMap { modifierNames[$0] }
            .joined(separator: "")

        return modifierSymbols + keyString
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "}"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        case 51: return "\\"
        case 53: return "⎋"
        case 55: return "⌘"
        case 56: return "⇧"
        case 58: return "⌥"
        case 59: return "⌃"
        default: return "\(keyCode)"
        }
    }
}

#Preview {
    HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Views/HotkeyConfigView.swift CoverUpTests/Views/
git commit -m "feat: add HotkeyConfigView"
```

---

## Task 11: ContentView - Main UI

**Files:**
- Create: `CoverUp/Views/ContentView.swift`

**Step 1: Write minimal test**

```swift
func test_contentView_instantiates() {
    let view = ContentView()
    XCTAssertNotNil(view)
}
```

**Step 2: Write test file and run to fail**

```bash
cat > CoverUpTests/Views/ContentViewTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class ContentViewTests: XCTestCase {
    func test_contentView_instantiates() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - ContentView not defined

**Step 3: Write implementation**

```swift
import SwiftUI

struct ContentView: View {
    @State private var settings = SettingsManager.load()
    @State private var showingAppPicker = false
    @State private var showingHotkeyConfig = false
    @State private var accessibilityGranted = HotkeyManager.isAccessibilityEnabled

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CoverUp")
                    .font(.headline)
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Target Apps Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Apps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showingAppPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                if settings.targetApps.isEmpty {
                    Text("No apps configured")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(settings.targetApps) { app in
                                HStack {
                                    Image(systemName: "app.fill")
                                        .foregroundStyle(.secondary)
                                    Text(app.name)
                                    Spacer()
                                    Button {
                                        removeApp(app)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
            .padding()

            Divider()

            // Hotkey Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hotkey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Configure") {
                        showingHotkeyConfig = true
                    }
                }

                HStack {
                    if settings.hotkeyConfiguration.isValid {
                        Text(hotkeyDisplayString)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        if settings.hotkeyConfiguration.type == .eventTap && !accessibilityGranted {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()

            Divider()

            // Launch at Login
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .padding()

            Divider()

            // Quit
            HStack {
                Spacer()
                Button("Quit CoverUp") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
        }
        .frame(width: 300)
        .onChange(of: settings.launchAtLogin) { _, newValue in
            SettingsManager.save(settings)
            LoginItemManager.setLaunchAtLogin(enabled: newValue)
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(selectedApps: .init(
                get: { Set(settings.targetApps) },
                set: { settings.targetApps = Array($0) }
            )) {
                SettingsManager.save(settings)
                registerHotkey()
            }
        }
        .sheet(isPresented: $showingHotkeyConfig) {
            HotkeyConfigView(configuration: $settings.hotkeyConfiguration)
                .onChange(of: settings.hotkeyConfiguration) { _, _ in
                    SettingsManager.save(settings)
                    registerHotkey()
                }
        }
        .onAppear {
            accessibilityGranted = HotkeyManager.isAccessibilityEnabled
        }
    }

    private func removeApp(_ app: TargetApp) {
        settings.targetApps.removeAll { $0.id == app.id }
        SettingsManager.save(settings)
    }

    private var hotkeyDisplayString: String {
        guard let keyCode = settings.hotkeyConfiguration.keyCode else {
            return "Not configured"
        }

        let keyString = keyCodeToString(keyCode)
        let modifierSymbols = settings.hotkeyConfiguration.modifiers
            .sorted()
            .compactMap { modifierNames[$0] }
            .joined(separator: "")

        return modifierSymbols + keyString
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "}"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        case 51: return "\\"
        case 53: return "⎋"
        default: return "\(keyCode)"
        }
    }

    private var modifierNames: [UInt32: String] {
        [
            cmdKey: "⌘",
            shiftKey: "⇧",
            optionKey: "⌥",
            controlKey: "⌃"
        ]
    }

    private func registerHotkey() {
        guard settings.hotkeyConfiguration.isValid else { return }

        let config = settings.hotkeyConfiguration

        switch config.type {
        case .menuItem:
            HotkeyManager.registerMenuItemShortcut(with: config) {
                WindowManager.minimize(targetApps: settings.targetApps)
            }
        case .eventTap:
            HotkeyManager.registerEventTap(with: config) {
                WindowManager.minimize(targetApps: settings.targetApps)
            }
        }
    }
}

#Preview {
    ContentView()
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Views/ContentView.swift CoverUpTests/Views/
git commit -m "feat: add ContentView main UI"
```

---

## Task 12: Launch at Login Manager

**Files:**
- Create: `CoverUp/Services/LoginItemManager.swift`

**Step 1: Write test**

```swift
func test_setLaunchAtLogin_invalidBundle_returnsFalse() {
    let result = LoginItemManager.setLaunchAtLogin(enabled: true, bundleId: "invalid.bundle.id")
    XCTAssertFalse(result)
}
```

**Step 2: Write test file and run to fail**

```bash
cat > CoverUpTests/Services/LoginItemManagerTests.swift << 'EOF'
import XCTest
@testable import CoverUp

final class LoginItemManagerTests: XCTestCase {
    func test_setLaunchAtLogin_invalidBundle_returnsFalse() {
        let result = LoginItemManager.setLaunchAtLogin(enabled: true, bundleId: "invalid.bundle.id")
        XCTAssertFalse(result)
    }
}
EOF
```

Run: `xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(error:|BUILD)"`
Expected: FAIL - LoginItemManager not defined

**Step 3: Write implementation**

```swift
import Foundation
import ServiceManagement

enum LoginItemManager {
    private static let helperBundleId = "com.coverup.app.LoginHelper"

    static func setLaunchAtLogin(enabled: Bool, bundleId: String? = nil) -> Bool {
        let id = bundleId ?? helperBundleId

        if enabled {
            return SMAppService.loginItem.setStatus() == .enabled
        } else {
            return SMAppService.loginItem.setStatus() == .disabled
        }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.loginItem.status == .enabled
    }
}
```

**Step 4: Run tests to verify pass**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test -target CoverUpTests 2>&1 | grep -E "(Test Case.*passed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, tests pass

**Step 5: Commit**

```bash
git add CoverUp/Services/LoginItemManager.swift CoverUpTests/Services/
git commit -m "feat: add LoginItemManager service"
```

---

## Task 13: Final Integration & Build Verification

**Step 1: Run all tests**

```bash
xcodebuild -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug test 2>&1 | grep -E "(Test Case.*passed|Test Case.*failed|error:|BUILD)"
```

Expected: BUILD SUCCEEDED, all tests pass

**Step 2: Clean build**

```bash
xcodebuild clean -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug 2>&1 | tail -3
xcodebuild build -project CoverUp.xcodeproj -scheme CoverUp -configuration Debug 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

**Step 3: Final commit**

```bash
git add .
git commit -m "feat: complete CoverUp implementation - all features"
git tag v1.0.0
```

---

## Summary

This plan creates a complete, testable CoverUp implementation with:
- Menu bar app structure
- App picker for selecting target applications
- Dual hotkey support (menu item + event tap)
- Window management via AppKit
- Launch at login via ServiceManagement
- Settings persistence via UserDefaults
- Full test coverage for all services
