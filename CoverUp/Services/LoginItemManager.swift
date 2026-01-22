import Foundation
import ServiceManagement

enum LoginItemManager {
    private static let helperBundleId = "com.coverup.app.LoginHelper"

    static func setLaunchAtLogin(enabled: Bool, bundleId: String? = nil) -> Bool {
        let id = bundleId ?? helperBundleId

        if enabled {
            return SMAppService.loginItem.setStatus() == .enabled
        } else {
            return SMAppService.loginItem.setStatus() == .disabled
        }
    }

    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.loginItem.status == .enabled
    }
}
