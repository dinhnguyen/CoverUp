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
