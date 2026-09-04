import SwiftUI

@main
struct QuietApp: App {
    @State private var settings = FilterSettings()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(settings: settings)
            }
            .onChange(of: scenePhase) { _, phase in
                // The extension writes its counters from another process.
                if phase == .active {
                    settings.refresh()
                }
            }
        }
    }
}
