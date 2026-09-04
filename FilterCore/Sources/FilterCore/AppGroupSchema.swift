import Foundation

/// The complete description of what may live in the App Group.
///
/// SPEC §6: the shared container holds settings and counters and nothing else.
/// Keeping the key list and its value kinds here — rather than next to the
/// `UserDefaults` calls — is what lets `swift test` assert the invariant without
/// a device or a simulator.
public enum AppGroupKey: String, Sendable, CaseIterable {
    /// `Config.Sensitivity.rawValue`.
    case sensitivity
    /// SPEC §3's "Allow one-time codes and delivery alerts" toggle.
    case allowsCodesAndAlerts
    /// Messages filtered since install.
    case blockedTotal
    /// Messages filtered in the current week.
    case blockedThisWeek
    /// Start of the week `blockedThisWeek` counts.
    case weekStart
    /// Last time the extension ran, used to show filter status.
    case lastRun

    /// The kinds of value the App Group may hold. Message text is not
    /// representable as any of them, which is the point.
    public enum ValueKind: String, Sendable, CaseIterable {
        case integer
        case date
        case boolean
        case enumeration
    }

    public var kind: ValueKind {
        switch self {
        case .sensitivity: .enumeration
        case .allowsCodesAndAlerts: .boolean
        case .blockedTotal, .blockedThisWeek: .integer
        case .weekStart, .lastRun: .date
        }
    }
}
