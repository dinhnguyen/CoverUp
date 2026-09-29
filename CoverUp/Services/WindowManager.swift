import Foundation
import AppKit
import Accessibility
import CoreGraphics

struct WindowInfo {
    let pid: pid_t
    let windowNumber: CGWindowID
    let title: String
}

enum WindowManager {
    static func getWindows(for bundleId: String) -> [WindowInfo] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
            print("WindowManager: App with bundle ID '\(bundleId)' is not running")
            return []
        }

        let pid = app.processIdentifier

        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[CFString: Any]] else {
            print("WindowManager: Failed to get window list")
            return []
        }

        return windowList.compactMap { windowInfo -> WindowInfo? in
            guard let ownerPid = windowInfo[kCGWindowOwnerPID] as? pid_t,
                  ownerPid == pid,
                  let windowNumber = windowInfo[kCGWindowNumber] as? CGWindowID,
                  let isOnScreen = windowInfo[kCGWindowIsOnscreen] as? Bool, isOnScreen,
                  let title = windowInfo[kCGWindowName] as? String, !title.isEmpty else {
                return nil
            }

            return WindowInfo(pid: pid, windowNumber: windowNumber, title: title)
        }
    }

    static func minimize(windows: [WindowInfo]) {
        guard !windows.isEmpty else { return }

        // Group windows by PID to minimize API calls
        let grouped = Dictionary(grouping: windows) { $0.pid }

        for (pid, windowInfos) in grouped {
            let axElement = AXUIElementCreateApplication(pid)
            var windowsArray: CFTypeRef?

            let result = AXUIElementCopyAttributeValue(axElement, kAXWindowsAttribute as CFString, &windowsArray)

            if result != .success {
                print("WindowManager: Failed to get windows for PID \(pid): \(result.rawValue)")
                continue
            }

            guard let array = windowsArray as? [AXUIElement] else {
                print("WindowManager: Failed to cast windows array for PID \(pid)")
                continue
            }

            for windowRef in array {
                // Get the window number from the AX element
                var numberValue: CFTypeRef?
                let numberResult = AXUIElementCopyAttributeValue(windowRef, kAXWindowAttribute as CFString, &numberValue)

                if numberResult == .success, let numValue = numberValue as? NSNumber {
                    let shouldMinimize = windowInfos.contains { $0.windowNumber == numValue.uint32Value }
                    if shouldMinimize {
                        let setResult = AXUIElementSetAttributeValue(windowRef, kAXMinimizedAttribute as CFString, true as CFBoolean)
                        if setResult != .success {
                            print("WindowManager: Failed to minimize window \(numValue.uint32Value): \(setResult.rawValue)")
                        }
                    }
                }
            }
        }
    }

    static func minimize(targetApps: [TargetApp]) {
        for app in targetApps {
            let windows = getWindows(for: app.id)
            minimize(windows: windows)
        }
    }
}
