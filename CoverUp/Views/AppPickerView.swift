import SwiftUI

struct AppPickerView: View {
    @Binding var selectedApps: Set<TargetApp>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var allApps: [TargetApp] = []
    @State private var isLoading = true
    @State private var localSelection: Set<TargetApp> = []

    let onConfirm: () -> Void

    private var filteredApps: [TargetApp] {
        if searchText.isEmpty {
            return allApps
        }
        return allApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Applications")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            if isLoading {
                ProgressView("Loading apps...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                List {
                    ForEach(filteredApps, id: \.id) { app in
                        HStack(spacing: 8) {
                            Image(systemName: localSelection.contains(app) ? "checkmark.square.fill" : "square")
                                .foregroundColor(localSelection.contains(app) ? .accentColor : .gray)
                                .font(.title3)
                                .onTapGesture {
                                    toggleApp(app)
                                }

                            Text(app.name)
                                .onTapGesture {
                                    toggleApp(app)
                                }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleApp(app)
                        }
                    }
                }
                .listStyle(.plain)

                HStack {
                    Button("Clear") {
                        localSelection.removeAll()
                    }
                    .disabled(localSelection.isEmpty)
                    Spacer()
                    Button("Confirm (\(localSelection.count))") {
                        selectedApps = localSelection
                        onConfirm()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            localSelection = selectedApps
            loadApps()
        }
    }

    private func toggleApp(_ app: TargetApp) {
        if localSelection.contains(app) {
            localSelection.remove(app)
        } else {
            localSelection.insert(app)
        }
    }

    private func loadApps() {
        allApps = AppLister.getInstalledApps()
        isLoading = false
    }
}

#Preview {
    AppPickerView(selectedApps: .constant([])) {}
}
