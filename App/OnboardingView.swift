import SwiftUI

/// SPEC §3: the three-step enable walkthrough, plus the "I don't see it"
/// fallback. `App-prefs:` deep links are unreliable, so this opens the app's own
/// Settings page and spells the rest out in words.
struct OnboardingView: View {
    @Environment(\.openURL) private var openURL

    private static let steps = [
        "Open Settings, then tap Apps → Messages.",
        "Tap Unknown & Spam, then Text Message Filter.",
        "Choose Quiet from the list.",
    ]

    var body: some View {
        Form {
            Section {
                Text(
                    "Quiet filters fundraising and campaign robotexts from numbers you don't know. It runs entirely on your iPhone."
                )
                .font(.body)
            }

            Section {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20, alignment: .leading)
                            .accessibilityHidden(true)
                        Text(step)
                            .font(.body)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(index + 1). \(step)")
                }
            } header: {
                Text("Three steps")
            }

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                }
            } footer: {
                Text("Settings opens on Quiet's own page. From there, go back once to reach Apps.")
            }

            Section {
                DisclosureGroup("I don't see Text Message Filter") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(
                            "Some carriers and regions don't offer message filtering, and the option is "
                                + "hidden when that's the case. It isn't something Quiet can turn on."
                        )
                        Text(
                            "It also needs iOS 17 or later. If you recently installed Quiet, try restarting "
                                + "your iPhone — the option can take a moment to appear."
                        )
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
                DisclosureGroup("Should I also use Apple's filter?") {
                    Text(
                        "Yes. Turn on Screen Unknown Senders in the same Settings screen. Apple's filter "
                            + "catches general spam; Quiet adds a stricter layer for fundraising texts. "
                            + "They work together."
                    )
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
            } header: {
                Text("If something looks wrong")
            }
        }
        .navigationTitle("Turn on Quiet")
        .navigationBarTitleDisplayMode(.inline)
    }
}
