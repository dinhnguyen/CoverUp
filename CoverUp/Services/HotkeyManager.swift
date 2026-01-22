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
