import Foundation
import Carbon
import Carbon.HIToolbox
import AppKit
import CoreGraphics

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

// MARK: - Event Tap Context
private class EventTapContext {
    var keyCode: UInt16 = 0
    var modifiers: UInt32 = 0
    var callback: (() -> Void)?
}

// MARK: - Carbon Event Handler Callback (global C function)
private func globalCarbonEventCallback(_ nextHandler: EventHandlerCallRef?,
                                       _ event: EventRef?,
                                       _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    if status == noErr {
        DispatchQueue.main.async {
            HotkeyManager.actionHandler?.handleHotkey()
        }
        return noErr
    }

    return OSStatus(eventNotHandledErr)
}

enum HotkeyManager {
    typealias HotkeyCallback = () -> Void

    static var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }

    private static var eventTap: CFMachPort?
    private static var eventTapSource: CFRunLoopSource?
    private static var eventTapContext: UnsafeMutablePointer<EventTapContext>?

    private static var menuItem: NSMenuItem?
    fileprivate static var actionHandler: HotkeyActionHandler?
    private static var carbonHotKeyRef: EventHotKeyRef?
    private static var carbonEventHandler: EventHandlerRef?

    // MARK: - Event Tap Callback
    private static let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        guard type == .keyDown else { return Unmanaged.passRetained(event) }
        guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }

        let context = userInfo.assumingMemoryBound(to: EventTapContext.self).pointee

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Check if key code matches and all modifiers are pressed
        let keyMatches = keyCode == context.keyCode

        let hasCmd = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOption = flags.contains(.maskAlternate)
        let hasControl = flags.contains(.maskControl)

        let needsCmd = (context.modifiers & UInt32(cmdKey)) != 0
        let needsShift = (context.modifiers & UInt32(shiftKey)) != 0
        let needsOption = (context.modifiers & UInt32(optionKey)) != 0
        let needsControl = (context.modifiers & UInt32(controlKey)) != 0

        let modifierMatches = (!needsCmd || hasCmd) &&
                              (!needsShift || hasShift) &&
                              (!needsOption || hasOption) &&
                              (!needsControl || hasControl)

        if keyMatches && modifierMatches {
            DispatchQueue.main.async {
                context.callback?()
            }
            return nil // Consume the event
        }

        return Unmanaged.passRetained(event)
    }

    static func registerEventTap(with config: HotkeyConfiguration, callback: @escaping HotkeyCallback) -> Bool {
        unregisterEventTap()

        guard isAccessibilityEnabled else { return false }
        guard let keyCode = config.keyCode else { return false }

        // Allocate context on the heap
        let context = UnsafeMutablePointer<EventTapContext>.allocate(capacity: 1)
        context.initialize(to: EventTapContext())
        context.pointee.keyCode = keyCode
        context.pointee.modifiers = config.modifiers.carbonFlags
        context.pointee.callback = callback

        eventTapContext = context

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: CGEventTapLocation(rawValue: 1)!,
            place: CGEventTapPlacement(rawValue: 0)!,
            options: CGEventTapOptions(rawValue: 0)!,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: UnsafeMutableRawPointer(context)
        ) else {
            context.deinitialize(count: 1)
            context.deallocate()
            eventTapContext = nil
            return false
        }

        Self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        Self.eventTapSource = source

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    static func unregisterEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let context = eventTapContext {
            context.deinitialize(count: 1)
            context.deallocate()
            eventTapContext = nil
        }
        eventTap = nil
        eventTapSource = nil
    }

    // MARK: - Menu Item Shortcut Methods
    static func registerMenuItemShortcut(with config: HotkeyConfiguration, action: @escaping () -> Void) {
        unregisterMenuItem()

        guard let keyCode = config.keyCode else { return }

        actionHandler = HotkeyActionHandler(action: action)

        // Install Carbon event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var handler: EventHandlerRef?

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            globalCarbonEventCallback,
            1,
            &eventType,
            nil,
            &handler
        )

        guard handlerStatus == noErr else { return }
        carbonEventHandler = handler

        // Register the hot key
        var hotKeyID = EventHotKeyID()
        hotKeyID.id = UInt32(keyCode)
        hotKeyID.signature = OSType(kEventHotKeyPressed)

        let flags = config.modifiers.carbonFlags
        var hotKeyRef: EventHotKeyRef?

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
        } else {
            // Clean up handler if registration failed
            if let handler = carbonEventHandler {
                RemoveEventHandler(handler)
                carbonEventHandler = nil
            }
        }
    }

    static func unregisterMenuItem() {
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            carbonHotKeyRef = nil
        }
        if let handler = carbonEventHandler {
            RemoveEventHandler(handler)
            carbonEventHandler = nil
        }
        menuItem = nil
        actionHandler = nil
    }
}
