import Foundation
import AppKit

enum WindowManager {
    static func getWindows(for bundleId: String) -> [NSWindow] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
            return []
        }

        return app.windows.filter { window in
            window.isVisible && window.title != ""
        }
    }

    static func minimize(windows: [NSWindow]) {
        for window in windows {
            window.orderOut(nil)
        }
    }

    static func minimize(targetApps: [TargetApp]) {
        for app in targetApps {
            let windows = getWindows(for: app.id)
            minimize(windows: windows)
        }
    }
}
