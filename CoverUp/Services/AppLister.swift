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

            // Check if directory exists
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                print("AppLister: Directory does not exist: \(directory)")
                continue
            }

            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsHiddenFiles]
            ) else {
                print("AppLister: Failed to create enumerator for: \(directory)")
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "app" else { continue }

                // Skip dot-prefixed apps (hidden/system)
                let fileName = fileURL.lastPathComponent
                if fileName.hasPrefix(".") { continue }

                // Use Bundle to get app info
                guard let bundle = Bundle(path: fileURL.path) else {
                    print("AppLister: Failed to load bundle at: \(fileURL.path)")
                    continue
                }

                guard let bundleId = bundle.bundleIdentifier,
                      let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String ??
                                 bundle.infoDictionary?["CFBundleName"] as? String,
                      !bundleId.isEmpty else {
                    continue
                }

                apps.append(TargetApp(id: bundleId, name: name))
            }
        }

        return Array(Set(apps)).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
