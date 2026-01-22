import SwiftUI
import Carbon

struct HotkeyConfigView: View {
    @Binding var configuration: HotkeyConfiguration
    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: [UInt32] = []

    private let modifierNames: [UInt32: String] = [
        cmdKey: "⌘",
        shiftKey: "⇧",
        optionKey: "⌥",
        controlKey: "⌃"
    ]

    var body: some View {
        VStack(spacing: 16) {
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
        .onKeyPress { press in
            guard isRecording else { return .ignored }
            recordedKeyCode = press.keyCode
            configuration.keyCode = press.keyCode
            isRecording = false
            return .handled
        }
    }

    private var displayString: String {
        guard let keyCode = configuration.keyCode else {
            return "Press to record"
        }

        let keyString = keyCodeToString(keyCode)
        let modifierSymbols = configuration.modifiers
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
        case 55: return "⌘"
        case 56: return "⇧"
        case 58: return "⌥"
        case 59: return "⌃"
        default: return "\(keyCode)"
        }
    }
}

#Preview {
    HotkeyConfigView(configuration: .constant(HotkeyConfiguration()))
}
