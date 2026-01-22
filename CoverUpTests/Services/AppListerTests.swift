import XCTest
@testable import CoverUp

final class AppListerTests: XCTestCase {
    func test_getInstalledApps_returnsNonEmpty() {
        let apps = AppLister.getInstalledApps()
        XCTAssertFalse(apps.isEmpty)
    }

    func test_getInstalledApps_containsKnownApps() {
        let apps = AppLister.getInstalledApps()
        let bundleIds = apps.map(\.id)
        XCTAssertTrue(bundleIds.contains("com.apple.Safari"))
    }
}
