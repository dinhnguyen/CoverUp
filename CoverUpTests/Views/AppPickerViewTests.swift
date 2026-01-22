import XCTest
@testable import CoverUp

final class AppPickerViewTests: XCTestCase {
    func test_appPickerView_instantiates() {
        let view = AppPickerView(selectedApps: .constant([]), onConfirm: {})
        XCTAssertNotNil(view)
    }
}
