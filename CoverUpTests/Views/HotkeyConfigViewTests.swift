import XCTest
@testable import CoverUp

final class HotkeyConfigViewTests: XCTestCase {
    func test_hotkeyConfigView_instantiates() {
        let view = HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
        XCTAssertNotNil(view)
    }
}
