import SwiftUI
import Carbon

struct ContentView: View {
    @State private var settings = SettingsManager.load()
    @State private var showingAppPicker = false
    @State private var showingHotkeyConfig = false
    @State private var accessibilityGranted = HotkeyManager.isAccessibilityEnabled
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CoverUp")
                    .font(.headline)
                Spacer()
                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
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
                        Text(KeyCodeMapper.displayString(
                            for: settings.hotkeyConfiguration.keyCode,
                            modifiers: settings.hotkeyConfiguration.modifiers
                        ))
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

                // Accessibility warning
                if settings.hotkeyConfiguration.type == .eventTap && !accessibilityGranted {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility access required")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Button("Open System Settings") {
                            openAccessibilitySettings()
                        }
                        .font(.caption)
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
        .onChange(of: settings.launchAtLogin) { newValue in
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
                .onChange(of: settings.hotkeyConfiguration) { _ in
                    SettingsManager.save(settings)
                    registerHotkey()
                }
        }
        .onAppear {
            accessibilityGranted = HotkeyManager.isAccessibilityEnabled
        }
        .alert("CoverUp", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func removeApp(_ app: TargetApp) {
        settings.targetApps.removeAll { $0.id == app.id }
        SettingsManager.save(settings)
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
            let success = HotkeyManager.registerEventTap(with: config) {
                WindowManager.minimize(targetApps: settings.targetApps)
            }

            if !success {
                if !HotkeyManager.isAccessibilityEnabled {
                    alertMessage = "Accessibility permissions are required for event tap hotkeys. Please grant CoverUp accessibility access in System Settings > Privacy & Security > Accessibility."
                } else {
                    alertMessage = "Failed to register hotkey. Please try a different key combination."
                }
                showingAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}
