import Foundation
import Carbon
import AppKit

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

// MARK: - HotkeyActionHandler
private class HotkeyActionHandler {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc func handleHotkey() {
        action()
    }
}

// MARK: - toCarbonFlags Extension
extension [UInt32] {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        for modifier in self {
            flags |= modifier
        }
        return flags
    }
}

enum HotkeyManager {
    typealias HotkeyCallback = () -> Void

    static var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }

    private static var eventTap: CFMachPort?
    private static var eventTapSource: CFRunLoopSource?
    private static var currentCallback: HotkeyCallback?

    private static var menuItem: NSMenuItem?
    private static var actionHandler: HotkeyActionHandler?
    private static var carbonHotKeyRef: HotKeyRef?

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

    // MARK: - Menu Item Shortcut Methods
    static func registerMenuItemShortcut(with config: HotkeyConfiguration, action: @escaping () -> Void) {
        unregisterMenuItem()

        guard let keyCode = config.keyCode else { return }

        actionHandler = HotkeyActionHandler(action: action)

        var hotKeyID = EventHotKeyID()
        hotKeyID.id = UInt32(keyCode)
        hotKeyID.signature = OSType("CoverUp".withCString { $0.withMemoryRebound(to: OSType.self, capacity: 1) { $0.pointee } } ?? 0)

        let flags = config.modifiers.carbonFlags
        var hotKeyRef: HotKeyRef?

        let status = RegisterEventHotKey(
            UInt32(keyCode),
            flags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            carbonHotKeyRef = hotKeyRef
        }
    }

    static func unregisterMenuItem() {
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            carbonHotKeyRef = nil
        }
        menuItem = nil
        actionHandler = nil
    }

    private static func keyCodeToString(_ keyCode: UInt16) -> String {
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
        case 34: return "I"
        case 35: return "L"
        case 36: return "J"
        case 37: return "'"
        case 38: return "K"
        case 39: return ";"
        case 40: return "\\"
        case 41: return ","
        case 42: return "/"
        case 43: return "N"
        case 44: return "M"
        case 45: return "."
        case 46: return "`"
        case 47: return "="
        case 48: return "TAB"
        case 49: return "SPACE"
        case 50: return "`"
        case 51: return "DELETE"
        case 53: return "ESCAPE"
        case 54: return "RIGHT COMMAND"
        case 55: return "COMMAND"
        case 56: return "SHIFT"
        case 57: return "CAPS LOCK"
        case 58: return "OPTION"
        case 59: return "CONTROL"
        case 60: return "RIGHT SHIFT"
        case 61: return "RIGHT OPTION"
        case 62: return "RIGHT CONTROL"
        case 63: return "FUNCTION"
        case 64: return "F17"
        case 65: return "*"
        case 67: return "*"
        case 69: return "+"
        case 71: return "CLEAR"
        case 72: return "/"
        case 75: return "/"
        case 76: return "ENTER"
        case 78: return "+"
        case 79: return "CLEAR"
        case 81: return "="
        case 82: return "0"
        case 83: return "1"
        case 84: return "2"
        case 85: return "3"
        case 86: return "4"
        case 87: return "5"
        case 88: return "6"
        case 89: return "7"
        case 91: return "8"
        case 92: return "9"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 106: return "F16"
        case 107: return "F14"
        case 109: return "F10"
        case 111: return "F12"
        case 113: return "F15"
        case 114: return "HELP"
        case 115: return "HOME"
        case 116: return "PGUP"
        case 117: return "DELETE"
        case 118: return "F4"
        case 119: return "END"
        case 120: return "F2"
        case 121: return "PGDN"
        case 122: return "F1"
        case 123: return "LEFT ARROW"
        case 124: return "RIGHT ARROW"
        case 125: return "DOWN ARROW"
        case 126: return "UP ARROW"
        default: return "KEY_\(keyCode)"
        }
    }
}
