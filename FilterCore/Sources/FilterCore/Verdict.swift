import Foundation

/// The result of classifying a single message.
///
/// `FilterCore` is platform-agnostic on purpose: it never imports `IdentityLookup`.
/// The extension maps `Action`/`SubAction` onto the `IL*` enums at the boundary.
public struct Verdict: Equatable, Sendable {
    /// Mirrors `ILMessageFilterAction`.
    public enum Action: String, Equatable, Sendable, CaseIterable {
        case none
        case allow
        case junk
        case promotion
        case transaction
    }

    /// The subset of `ILMessageFilterSubAction` we actually produce.
    public enum SubAction: String, Equatable, Sendable, CaseIterable {
        case none
        case promotionalOffers
        case transactionalFinance
        case transactionalOrders
        case transactionalReminders
    }

    /// What the extension should do with the message.
    public let action: Action
    /// Refinement of `action`; `.none` unless the verdict is `.transaction` or `.promotion`.
    public let subAction: SubAction
    /// Total junk score. Zero for allow-listed messages.
    public let score: Int
    /// Identifiers of every rule that fired, in evaluation order. Test Lab shows these.
    public let firedRules: [String]

    public init(action: Action, subAction: SubAction = .none, score: Int = 0, firedRules: [String] = []) {
        self.action = action
        self.subAction = subAction
        self.score = score
        self.firedRules = firedRules
    }

    /// The fail-open verdict: deliver the message normally.
    public static let passthrough = Verdict(action: .none)
}
