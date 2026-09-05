import FilterCore
import SwiftUI

/// SPEC §3: status, counts, sensitivity, and the codes toggle. Nothing else.
struct HomeView: View {
    @Bindable var settings: FilterSettings

    var body: some View {
        Form {
            if !settings.isProbablyEnabled {
                Section {
                    NavigationLink {
                        OnboardingView()
                    } label: {
                        Label("How to turn Quiet on", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                    }
                } footer: {
                    // iOS exposes no way to ask whether we are the selected filter, so
                    // "unconfirmed" and "not set up" look identical from in here. Say that,
                    // rather than telling someone who did it correctly that they failed.
                    Text("Already turned it on? Then you're done. iOS doesn't let an app check "
                        + "whether it's the chosen filter, so Quiet can only confirm itself once "
                        + "the first text from an unknown number arrives.")
                }
            }

            Section {
                StatusRow(lastRun: settings.stats.lastRun)
            }

            Section {
                HStack {
                    CountView(number: settings.stats.blockedThisWeek, caption: "This week")
                    Divider()
                    CountView(number: settings.stats.blockedTotal, caption: "All time")
                }
                .padding(.vertical, 8)
            } header: {
                Text("Filtered")
            }

            Section {
                Picker("Sensitivity", selection: $settings.sensitivity) {
                    Text("Standard").tag(Config.Sensitivity.standard)
                    Text("Aggressive").tag(Config.Sensitivity.aggressive)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("How strict")
            } footer: {
                Text(settings.sensitivity == .standard
                    ? "Filters clear fundraising texts. Recommended."
                    : "Filters more, including borderline texts. Slightly more likely to catch something you wanted.")
            }

            Section {
                Toggle("Always allow codes and alerts", isOn: $settings.allowsCodesAndAlerts)
            } footer: {
                Text(
                    "Keeps one-time codes, delivery updates, appointment reminders, and bank alerts out of the filter."
                )
            }

            Section {
                NavigationLink { TestLabView(config: settings.currentConfig) } label: {
                    Label("Test Lab", systemImage: "flask")
                }
                if settings.isProbablyEnabled {
                    NavigationLink { OnboardingView() } label: {
                        Label("How to turn Quiet on", systemImage: "questionmark.circle")
                    }
                }
            }
        }
        .navigationTitle("Quiet")
    }
}

/// There is no API to ask iOS whether we are the chosen filter, so status is
/// inferred from whether the extension has ever run. SPEC §3.
private struct StatusRow: View {
    let lastRun: Date?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lastRun == nil ? "clock.badge.questionmark" : "checkmark.shield.fill")
                .font(.title2)
                .foregroundStyle(lastRun == nil ? Color.secondary : Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(lastRun == nil ? "Waiting for the first text" : "Filtering is on")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        guard let lastRun else {
            return "Quiet confirms itself the first time a number you don't know texts you."
        }
        return "Last checked a message \(lastRun.formatted(.relative(presentation: .named)))."
    }
}

private struct CountView: View {
    let number: Int
    let caption: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText())
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
