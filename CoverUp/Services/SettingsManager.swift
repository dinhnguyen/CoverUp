import Foundation

struct AppSettings: Codable {
    var targetApps: [TargetApp] = []
    var hotkeyConfiguration: HotkeyConfiguration = HotkeyConfiguration()
    var launchAtLogin: Bool = false
}

enum SettingsManager {
    private static let defaults = UserDefaults.standard
    private static let settingsKey = "com.coverup.settings"

    static func load() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    static func resetToDefaults() {
        defaults.removeObject(forKey: settingsKey)
    }
}
