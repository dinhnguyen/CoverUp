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
