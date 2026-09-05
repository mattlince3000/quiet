import FilterCore
import Foundation

/// The only channel between the app and the filter extension.
///
/// SPEC §6: the App Group holds settings and counters and nothing else. The
/// permitted keys and their value kinds are declared by `AppGroupKey` in
/// FilterCore, where `swift test` can assert them; these accessors are the only
/// code that reads or writes the suite.
public enum AppGroup {
    public static let identifier = "group.com.getquiettexts.quiet"

    /// The App Group suite, never the standard one: SPEC §6 keeps every
    /// cross-target read and write inside this container.
    public static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// Counters shown on Home. Counts and dates only.
    public struct Stats: Equatable, Sendable {
        public var blockedTotal: Int
        public var blockedThisWeek: Int
        /// `nil` until the extension has run once, which is how Home tells
        /// whether the user has actually enabled the filter in Settings.
        public var lastRun: Date?

        public static let empty = Stats(blockedTotal: 0, blockedThisWeek: 0, lastRun: nil)
    }
}

public extension AppGroup {
    /// Reads the user's settings, falling back to the defaults if the app has
    /// never written them.
    static func config() -> Config {
        guard let defaults else { return .default }
        let sensitivity = defaults.string(forKey: AppGroupKey.sensitivity.rawValue)
            .flatMap(Config.Sensitivity.init(rawValue:)) ?? Config.default.sensitivity
        let allows = defaults.object(forKey: AppGroupKey.allowsCodesAndAlerts.rawValue) as? Bool
            ?? Config.default.allowsCodesAndAlerts
        return Config(sensitivity: sensitivity, allowsCodesAndAlerts: allows)
    }

    static func setSensitivity(_ sensitivity: Config.Sensitivity) {
        defaults?.set(sensitivity.rawValue, forKey: AppGroupKey.sensitivity.rawValue)
    }

    static func setAllowsCodesAndAlerts(_ allows: Bool) {
        defaults?.set(allows, forKey: AppGroupKey.allowsCodesAndAlerts.rawValue)
    }

    static func stats() -> Stats {
        guard let defaults else { return .empty }
        return Stats(
            blockedTotal: defaults.integer(forKey: AppGroupKey.blockedTotal.rawValue),
            blockedThisWeek: defaults.integer(forKey: AppGroupKey.blockedThisWeek.rawValue),
            lastRun: defaults.object(forKey: AppGroupKey.lastRun.rawValue) as? Date
        )
    }

    /// Bumps the filtered-message counters. Records counts and dates only.
    static func recordBlocked(now: Date = Date(), calendar: Calendar = .current) {
        guard let defaults else { return }
        defaults.set(now, forKey: AppGroupKey.lastRun.rawValue)
        let total = defaults.integer(forKey: AppGroupKey.blockedTotal.rawValue)
        defaults.set(total + 1, forKey: AppGroupKey.blockedTotal.rawValue)

        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let recordedWeek = defaults.object(forKey: AppGroupKey.weekStart.rawValue) as? Date
        if recordedWeek != startOfWeek {
            defaults.set(startOfWeek, forKey: AppGroupKey.weekStart.rawValue)
            defaults.set(0, forKey: AppGroupKey.blockedThisWeek.rawValue)
        }
        let week = defaults.integer(forKey: AppGroupKey.blockedThisWeek.rawValue)
        defaults.set(week + 1, forKey: AppGroupKey.blockedThisWeek.rawValue)
    }

    /// Notes that the extension ran, whatever the verdict was.
    static func recordRun(now: Date = Date()) {
        defaults?.set(now, forKey: AppGroupKey.lastRun.rawValue)
    }
}
