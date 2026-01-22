import SwiftUI

@main
struct CoverUpApp: App {
    var body: some Scene {
        MenuBarExtra("CoverUp", systemImage: "arrow.down.to.line") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
