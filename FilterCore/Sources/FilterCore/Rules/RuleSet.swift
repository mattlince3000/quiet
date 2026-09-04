import Foundation

/// The complete rule table. Adding or tuning a signal means editing this file
/// and the families it names — never the classifier's control flow.
public enum RuleSet {
    static let allowRules: [AllowRule] = AllowRules.all
    static let allowVeto: Matcher = AllowRules.veto

    static let families: [RuleFamily] = [
        FundraisingRules.processors,
        FundraisingRules.optOut,
        FundraisingRules.solicitation,
        PoliticalRules.political,
        SignalRules.links,
        SignalRules.sender,
        SignalRules.shape,
    ]

    /// Every rule identifier in the table, for tests and Test Lab.
    public static var ruleIdentifiers: [String] {
        allowRules.map(\.id) + families.flatMap { $0.rules.map(\.id) }
    }
}
