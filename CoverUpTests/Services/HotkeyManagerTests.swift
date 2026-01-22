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

    func test_registerEventTap_withoutAccessibility_returnsFalse() {
        let config = HotkeyConfiguration(type: .eventTap, keyCode: 49, modifiers: [controlKey])
        let result = HotkeyManager.registerEventTap(with: config) {}
        XCTAssertFalse(result)
    }

    func test_registerMenuItem_withValidConfig_doesNotCrash() {
        let config = HotkeyConfiguration(type: .menuItem, keyCode: 49, modifiers: [controlKey])
        HotkeyManager.registerMenuItemShortcut(with: config, action: {})
    }
}
