import Foundation
import AppKit

enum AppLister {
    static func getInstalledApps() -> [TargetApp] {
        var apps: [TargetApp] = []

        let directories = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for directory in directories {
            let url = URL(fileURLWithPath: directory)
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.bundleIdentifierKey, .localizedNameKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "app" else { continue }

                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.bundleIdentifierKey, .localizedNameKey])
                    guard let bundleId = resourceValues.bundleIdentifier,
                          let name = resourceValues.localizedName,
                          !bundleId.isEmpty else { continue }

                    apps.append(TargetApp(id: bundleId, name: name))
                } catch {
                    continue
                }
            }
        }

        return Array(Set(apps)).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
