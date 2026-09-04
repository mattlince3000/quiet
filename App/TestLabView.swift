import FilterCore
import SwiftUI

/// SPEC §3: paste any text, see the verdict and which rules fired.
///
/// Threat model: the pasted body is only ever shown through `Text(verbatim:)`.
/// No markdown parsing, no attributed string, no data detectors — a link in a
/// hostile message stays inert text that cannot be tapped.
struct TestLabView: View {
    let config: Config

    @State private var draft = ""
    @FocusState private var isEditing: Bool

    private var verdict: Verdict? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Classifier.classify(sender: "", body: trimmed, config: config)
    }

    var body: some View {
        Form {
            Section {
                TextEditor(text: $draft)
                    .frame(minHeight: 130)
                    .font(.body)
                    .focused($isEditing)
                    .overlay(alignment: .topLeading) {
                        if draft.isEmpty {
                            Text("Paste a text message here")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                Text("Message")
            } footer: {
                Text("Nothing you paste here is saved or sent anywhere.")
            }

            if let verdict {
                VerdictSection(verdict: verdict)
            } else {
                Section {
                    ForEach(Samples.all) { sample in
                        Button(sample.title) { draft = sample.body }
                    }
                } header: {
                    Text("Or try an example")
                }
            }
        }
        .navigationTitle("Test Lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !draft.isEmpty {
                    Button("Clear") {
                        draft = ""
                        isEditing = false
                    }
                }
            }
        }
    }
}

/// The result card: plain-language outcome first, detail underneath.
private struct VerdictSection: View {
    let verdict: Verdict

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: Outcome.of(verdict).symbol)
                    .font(.title)
                    .foregroundStyle(Outcome.of(verdict).tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Outcome.of(verdict).title)
                        .font(.headline)
                    Text(Outcome.of(verdict).detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Result")
        }

        Section {
            if verdict.firedRules.isEmpty {
                Text("Nothing suspicious matched.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(verdict.firedRules, id: \.self) { rule in
                    Text(RuleLabel.describe(rule))
                }
            }
        } header: {
            Text("What matched")
        } footer: {
            Text(
                "Score \(verdict.score). Filtered at \(Config.Sensitivity.standard.threshold) on Standard, "
                    + "\(Config.Sensitivity.aggressive.threshold) on Aggressive."
            )
        }
    }
}

/// Maps a verdict onto plain language. No jargon on screen.
private struct Outcome {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    static func of(_ verdict: Verdict) -> Outcome {
        switch verdict.action {
        case .junk:
            Outcome(
                title: "Filtered as junk",
                detail: "This would go to your Junk folder.",
                symbol: "xmark.bin.fill",
                tint: .red
            )
        case .transaction:
            Outcome(
                title: "Delivered as a receipt or alert",
                detail: "Codes, deliveries, and appointments always come through.",
                symbol: "checkmark.seal.fill",
                tint: .green
            )
        case .allow:
            Outcome(
                title: "Delivered to your inbox",
                detail: "Recognised as a real message.",
                symbol: "checkmark.circle.fill",
                tint: .green
            )
        case .promotion:
            Outcome(
                title: "Delivered as a promotion",
                detail: "Sorted, not blocked.",
                symbol: "tag.fill",
                tint: .orange
            )
        case .none:
            Outcome(
                title: "Delivered to your inbox",
                detail: "Not enough signals to filter it.",
                symbol: "checkmark.circle.fill",
                tint: .green
            )
        }
    }
}

/// The samples App Review is pointed at: two fundraising texts and a one-time code.
private struct Samples: Identifiable {
    let id = UUID()
    let title: String
    let body: String

    static let all: [Samples] = [
        Samples(
            title: "A fundraising text",
            body: "Chip in $5 before midnight! Our 3X MATCH expires tonight. "
                + "secure.actblue.com/donate/x Reply STOP to end"
        ),
        Samples(
            title: "A campaign text with a short link",
            body: "The deadline is TONIGHT and we are 212 gifts short. "
                + "Can you rush $25? bit.ly/2xyzab Reply STOP 2 end"
        ),
        Samples(title: "A one-time code", body: "Your Chase verification code is 482913. Do not share it."),
    ]
}
