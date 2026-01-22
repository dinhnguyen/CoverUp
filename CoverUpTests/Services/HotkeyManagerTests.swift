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
