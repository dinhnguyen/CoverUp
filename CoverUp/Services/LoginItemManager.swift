import Foundation
import ServiceManagement

enum LoginItemManager {
    @discardableResult
    static func setLaunchAtLogin(enabled: Bool) -> Bool {
        let service = SMAppService.mainApp

        if enabled {
            do {
                if service.status == .enabled {
                    return true
                }
                try service.register()
                return true
            } catch {
                print("Failed to enable launch at login: \(error)")
                return false
            }
        } else {
            do {
                if service.status == .notRegistered {
                    return true
                }
                try service.unregister()
                return true
            } catch {
                print("Failed to disable launch at login: \(error)")
                return false
            }
        }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
