import XCTest
@testable import CoverUp

final class LoginItemManagerTests: XCTestCase {
    func test_setLaunchAtLogin_invalidBundle_returnsFalse() {
        let result = LoginItemManager.setLaunchAtLogin(enabled: true, bundleId: "invalid.bundle.id")
        XCTAssertFalse(result)
    }
}
