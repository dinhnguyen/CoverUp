import XCTest
@testable import CoverUp

final class TargetAppTests: XCTestCase {
    func test_targetApp_initialization() {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        XCTAssertEqual(app.id, "com.apple.Safari")
        XCTAssertEqual(app.name, "Safari")
        XCTAssertEqual(app.bundleId, "com.apple.Safari")
    }

    func test_targetApp_codable() throws {
        let app = TargetApp(id: "com.apple.Safari", name: "Safari")
        let encoder = JSONEncoder()
        let data = try encoder.encode(app)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TargetApp.self, from: data)
        XCTAssertEqual(app, decoded)
    }
}
