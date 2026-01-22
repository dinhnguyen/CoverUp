import XCTest
@testable import CoverUp

final class ContentViewTests: XCTestCase {
    func test_contentView_instantiates() {
        let view = ContentView()
        XCTAssertNotNil(view)
    }
}
