import XCTest
@testable import CoverUp

final class SettingsManagerTests: XCTestCase {
    override func setUp() {
        SettingsManager.resetToDefaults()
    }

    func test_defaultSettings_returnsExpected() {
        let settings = SettingsManager.load()
        XCTAssertTrue(settings.targetApps.isEmpty)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.hotkeyConfiguration.isValid)
    }

    func test_saveAndLoad_roundtrip() {
        var settings = SettingsManager.load()
        settings.targetApps = [TargetApp(id: "com.apple.Safari", name: "Safari")]
        settings.launchAtLogin = true
        SettingsManager.save(settings)

        let loaded = SettingsManager.load()
        XCTAssertEqual(loaded.targetApps.count, 1)
        XCTAssertEqual(loaded.targetApps.first?.id, "com.apple.Safari")
    }
}
