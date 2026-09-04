import SwiftUI

/// The three screens in SPEC §3 land in M3. This is the minimum that builds and
/// launches so the extension has a host app to ship inside.
@main
struct QuietApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 8) {
                Text("Quiet").font(.largeTitle.bold())
                Text("Filtering runs in the Messages extension.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
