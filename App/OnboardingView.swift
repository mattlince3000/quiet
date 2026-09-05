import SwiftUI

/// SPEC §3: the three-step enable walkthrough, plus the "I don't see it"
/// fallback. `App-prefs:` deep links are unreliable, so this opens the app's own
/// Settings page and spells the rest out in words.
/// A tight bullet, so the two-filter split reads as a list without shouting.
private struct BulletLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .font(.system(size: 6))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            configuration.title
        }
    }
}

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
                VStack(alignment: .leading, spacing: 10) {
                    Text("iOS will show you a warning that says the developer receives your messages, "
                        + "including things like bank codes.")
                    Text("That warning appears for every message filter app. iOS shows it because a "
                        + "filter runs code on your texts, and iOS has no way to tell whether that "
                        + "code sends anything anywhere.")
                    Text("Quiet has no internet connection at all. Not limited — absent. There is no "
                        + "networking code in the app, and the filter is not registered to send a "
                        + "message anywhere, so it has no way to.")
                        .fontWeight(.medium)
                }
                .font(.body)
                .padding(.vertical, 2)

                DisclosureGroup("How can I check that?") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Every line of Quiet is public at github.com/mattlince3000/quiet. "
                            + "Anyone can read what it does with a message.")
                        Text("Test Lab, on the previous screen, shows you the whole decision for any "
                            + "message you paste — the verdict and every rule that matched.")
                        Text("Nothing is kept. Quiet stores your settings and a count of filtered "
                            + "messages. Deleting the app removes all of it.")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Before you start")
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
                VStack(alignment: .leading, spacing: 10) {
                    Text("While you are on that screen, also switch on Screen Unknown Senders.")
                        .fontWeight(.medium)
                    Text("The two filters cover different things, and neither one covers everything:")
                    Label(
                        "Quiet catches fundraising and campaign texts sent as SMS — where nearly all of "
                            + "them come from.",
                        systemImage: "circle.fill"
                    )
                    Label(
                        "Apple's filter catches general spam, and iMessages from people you don't know. "
                            + "Quiet cannot see iMessages — Apple does not allow any app to.",
                        systemImage: "circle.fill"
                    )
                }
                .font(.body)
                .labelStyle(BulletLabel())
                .padding(.vertical, 2)
            } header: {
                Text("Turn on both")
            } footer: {
                Text("Together they cover far more than either one alone.")
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
            } header: {
                Text("If something looks wrong")
            }
        }
        .navigationTitle("Turn on Quiet")
        .navigationBarTitleDisplayMode(.inline)
    }
}
