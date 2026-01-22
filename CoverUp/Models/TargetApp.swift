import Foundation

struct TargetApp: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String

    var bundleId: String { id }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TargetApp, rhs: TargetApp) -> Bool {
        lhs.id == rhs.id
    }
}
