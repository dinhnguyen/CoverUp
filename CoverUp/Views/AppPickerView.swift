import SwiftUI

struct AppPickerView: View {
    @Binding var selectedApps: Set<TargetApp>
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var allApps: [TargetApp] = []
    @State private var isLoading = true

    let onConfirm: () -> Void

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

                List(allApps.filter { app in
                    searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
                }, selection: .constant(selectedApps)) { app in
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundStyle(.secondary)
                        Text(app.name)
                        Spacer()
                        if selectedApps.contains(app) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedApps.contains(app) {
                            selectedApps.remove(app)
                        } else {
                            selectedApps.insert(app)
                        }
                    }
                }
                .listStyle(.plain)

                HStack {
                    Button("Clear") {
                        selectedApps.removeAll()
                    }
                    .disabled(selectedApps.isEmpty)
                    Spacer()
                    Button("Confirm") {
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
            loadApps()
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
