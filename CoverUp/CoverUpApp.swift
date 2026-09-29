import SwiftUI
import AppKit

@main
class CoverUpMain {
    static func main() {
        let appDelegate = AppDelegate()
        NSApplication.shared.delegate = appDelegate
        NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        windowController = MainWindowController()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "arrow.down.to.line", accessibilityDescription: "CoverUp")
            button.action = #selector(toggleWindow)
            button.target = self
        }

        // Register hotkey on launch
        let settings = SettingsManager.load()
        if settings.hotkeyConfiguration.isValid {
            registerHotkey(with: settings)
        }
    }

    @objc func toggleWindow() {
        if let window = windowController?.window, window.isVisible {
            window.orderOut(nil)
        } else {
            windowController?.showWindow(nil)
        }
    }

    private func registerHotkey(with settings: AppSettings) {
        let config = settings.hotkeyConfiguration
        switch config.type {
        case .menuItem:
            HotkeyManager.registerMenuItemShortcut(with: config) {
                WindowManager.minimize(targetApps: settings.targetApps)
            }
        case .eventTap:
            HotkeyManager.registerEventTap(with: config) {
                WindowManager.minimize(targetApps: settings.targetApps)
            }
        }
    }
}
