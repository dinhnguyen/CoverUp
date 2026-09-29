import XCTest
@testable import CoverUp

final class LoginItemManagerTests: XCTestCase {
    func test_setLaunchAtLogin_enableAndDisable() {
        // Test enabling
        let enableResult = LoginItemManager.setLaunchAtLogin(enabled: true)
        XCTAssertTrue(enableResult)

        // Test disabling
        let disableResult = LoginItemManager.setLaunchAtLogin(enabled: false)
        XCTAssertTrue(disableResult)
    }

    func test_isLaunchAtLoginEnabled_returnsStatus() {
        // This test just verifies the property is accessible
        _ = LoginItemManager.isLaunchAtLoginEnabled
    }
}
