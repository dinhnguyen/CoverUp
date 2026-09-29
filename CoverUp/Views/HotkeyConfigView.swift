import SwiftUI
import Carbon
import AppKit

struct HotkeyConfigView: View {
    @Binding var configuration: HotkeyConfiguration
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var eventMonitor: Any?
    @State private var recordedModifiers: [UInt32] = []

    var body: some View {
        VStack(spacing: 16) {
            // Header with close button
            HStack {
                Text("Configure Hotkey")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey Method")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Method", selection: $configuration.type) {
                    Text("Menu Item").tag(HotkeyType.menuItem)
                    Text("Global Event Tap").tag(HotkeyType.eventTap)
                }
                .pickerStyle(.segmented)

                if configuration.type == .eventTap {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Requires Accessibility permissions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Key Combination")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(action: { isRecording.toggle() }) {
                        Text(displayString)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .frame(minWidth: 120, minHeight: 44)
                            .background(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if isRecording {
                        Text("Press any key...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    } else {
                        Button("Clear") {
                            configuration.keyCode = nil
                            configuration.modifiers = []
                        }
                        .disabled(configuration.keyCode == nil)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 300)
        .onChange(of: isRecording) { newValue in
            if newValue {
                startEventMonitor()
            } else {
                stopEventMonitor()
            }
        }
        .onDisappear {
            stopEventMonitor()
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }

            recordedKeyCode = event.keyCode
            configuration.keyCode = event.keyCode

            var modifiers: [UInt32] = []
            if event.modifierFlags.contains(.command) { modifiers.append(UInt32(cmdKey)) }
            if event.modifierFlags.contains(.shift) { modifiers.append(UInt32(shiftKey)) }
            if event.modifierFlags.contains(.option) { modifiers.append(UInt32(optionKey)) }
            if event.modifierFlags.contains(.control) { modifiers.append(UInt32(controlKey)) }
            recordedModifiers = modifiers
            configuration.modifiers = modifiers

            isRecording = false
            return nil
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private var displayString: String {
        if configuration.keyCode == nil {
            return "Press to record"
        }
        return KeyCodeMapper.displayString(
            for: configuration.keyCode,
            modifiers: configuration.modifiers
        )
    }
}

#Preview {
    HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
}
