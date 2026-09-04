import Foundation

/// User-tunable classifier settings, mirrored in the App Group.
public struct Config: Equatable, Sendable {
    public enum Sensitivity: String, Equatable, Sendable, CaseIterable {
        case standard
        case aggressive

        /// Score at or above which a message is junk.
        public var threshold: Int {
            switch self {
            case .standard: 60
            case .aggressive: 40
            }
        }
    }

    /// How eagerly to mark messages as junk.
    public var sensitivity: Sensitivity
    /// When true, one-time codes and service alerts short-circuit to `.allow`/`.transaction`.
    public var allowsCodesAndAlerts: Bool

    public init(sensitivity: Sensitivity = .standard, allowsCodesAndAlerts: Bool = true) {
        self.sensitivity = sensitivity
        self.allowsCodesAndAlerts = allowsCodesAndAlerts
    }

    public static let `default` = Config()
}
