import SwiftUI

struct ContentView: View {
    @State private var settings = SettingsManager.load()
    @State private var showingAppPicker = false
    @State private var showingHotkeyConfig = false
    @State private var accessibilityGranted = HotkeyManager.isAccessibilityEnabled

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CoverUp")
                    .font(.headline)
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Target Apps Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Apps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showingAppPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                if settings.targetApps.isEmpty {
                    Text("No apps configured")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(settings.targetApps) { app in
                                HStack {
                                    Image(systemName: "app.fill")
                                        .foregroundStyle(.secondary)
                                    Text(app.name)
                                    Spacer()
                                    Button {
                                        removeApp(app)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
            .padding()

            Divider()

            // Hotkey Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hotkey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Configure") {
                        showingHotkeyConfig = true
                    }
                }

                HStack {
                    if settings.hotkeyConfiguration.isValid {
                        Text(hotkeyDisplayString)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        if settings.hotkeyConfiguration.type == .eventTap && !accessibilityGranted {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Not configured")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()

            Divider()

            // Launch at Login
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
                .padding()

            Divider()

            // Quit
            HStack {
                Spacer()
                Button("Quit CoverUp") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding()
        }
        .frame(width: 300)
        .onChange(of: settings.launchAtLogin) { _, newValue in
            SettingsManager.save(settings)
            LoginItemManager.setLaunchAtLogin(enabled: newValue)
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(selectedApps: .init(
                get: { Set(settings.targetApps) },
                set: { settings.targetApps = Array($0) }
            )) {
                SettingsManager.save(settings)
                registerHotkey()
            }
        }
        .sheet(isPresented: $showingHotkeyConfig) {
            HotkeyConfigView(configuration: $settings.hotkeyConfiguration)
                .onChange(of: settings.hotkeyConfiguration) { _, _ in
                    SettingsManager.save(settings)
                    registerHotkey()
                }
        }
        .onAppear {
            accessibilityGranted = HotkeyManager.isAccessibilityEnabled
        }
    }

    private func removeApp(_ app: TargetApp) {
        settings.targetApps.removeAll { $0.id == app.id }
        SettingsManager.save(settings)
    }

    private var hotkeyDisplayString: String {
        guard let keyCode = settings.hotkeyConfiguration.keyCode else {
            return "Not configured"
        }

        let keyString = keyCodeToString(keyCode)
        let modifierSymbols = settings.hotkeyConfiguration.modifiers
            .sorted()
            .compactMap { modifierNames[$0] }
            .joined(separator: "")

        return modifierSymbols + keyString
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "}"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        case 51: return "\\"
        case 53: return "⎋"
        default: return "\(keyCode)"
        }
    }

    private var modifierNames: [UInt32: String] {
        [
            cmdKey: "⌘",
            shiftKey: "⇧",
            optionKey: "⌥",
            controlKey: "⌃"
        ]
    }

    private func registerHotkey() {
        guard settings.hotkeyConfiguration.isValid else { return }

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

#Preview {
    ContentView()
}
