import FilterCore
import Foundation

/// The only channel between the app and the filter extension.
///
/// SPEC §6: the App Group holds settings and counters and nothing else. The
/// accessors below are the whole API surface, and every one of them reads or
/// writes a scalar — never message text, never a sender.
public enum AppGroup {
    public static let identifier = "group.com.you.quiet"

    /// Every key that may ever appear in the shared suite.
    public enum Key: String, CaseIterable {
        /// `Config.Sensitivity.rawValue`.
        case sensitivity
        /// Bool. SPEC §3's "Allow one-time codes and delivery alerts" toggle.
        case allowsCodesAndAlerts
        /// Int. Messages filtered since install.
        case blockedTotal
        /// Int. Messages filtered in the current week.
        case blockedThisWeek
        /// Date. Start of the week `blockedThisWeek` counts.
        case weekStart
        /// Date. Last time the extension ran, used to show filter status.
        case lastRun
    }

    /// The App Group suite, never the standard one: SPEC §6 keeps every
    /// cross-target read and write inside this container.
    public static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

public extension AppGroup {
    /// Reads the user's settings, falling back to the defaults if the app has
    /// never written them.
    static func config() -> Config {
        guard let defaults else { return .default }
        let sensitivity = (defaults.string(forKey: Key.sensitivity.rawValue))
            .flatMap(Config.Sensitivity.init(rawValue:)) ?? Config.default.sensitivity
        let allows = defaults.object(forKey: Key.allowsCodesAndAlerts.rawValue) as? Bool
            ?? Config.default.allowsCodesAndAlerts
        return Config(sensitivity: sensitivity, allowsCodesAndAlerts: allows)
    }

    /// Bumps the filtered-message counters. Records counts and dates only.
    static func recordBlocked(now: Date = Date(), calendar: Calendar = .current) {
        guard let defaults else { return }
        defaults.set(now, forKey: Key.lastRun.rawValue)
        defaults.set(defaults.integer(forKey: Key.blockedTotal.rawValue) + 1, forKey: Key.blockedTotal.rawValue)

        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let recordedWeek = defaults.object(forKey: Key.weekStart.rawValue) as? Date
        if recordedWeek != startOfWeek {
            defaults.set(startOfWeek, forKey: Key.weekStart.rawValue)
            defaults.set(0, forKey: Key.blockedThisWeek.rawValue)
        }
        defaults.set(defaults.integer(forKey: Key.blockedThisWeek.rawValue) + 1, forKey: Key.blockedThisWeek.rawValue)
    }

    /// Notes that the extension ran, whatever the verdict was.
    static func recordRun(now: Date = Date()) {
        defaults?.set(now, forKey: Key.lastRun.rawValue)
    }
}
