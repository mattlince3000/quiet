import Foundation

/// Classifies one message. Pure, synchronous, allocation-light, and the only
/// entry point the extension uses.
public enum Classifier {
    /// Scores `body` against the rule table and returns a verdict.
    ///
    /// - Parameters:
    ///   - sender: The sender string iOS handed us. Treated as untrusted text.
    ///   - body: The message body. Truncated to `Message.maxBodyLength` first.
    ///   - config: User settings. Defaults to Standard sensitivity with allow
    ///     rules enabled.
    public static func classify(
        sender: String,
        body: String,
        config: Config = .default
    ) -> Verdict {
        let message = Message(sender: sender, body: body)

        // Allow rules first, so a one-time code never has to out-argue a score.
        let vetoed = RuleSet.allowVetoes.contains { $0.matches(message) }
        if config.allowsCodesAndAlerts, !vetoed {
            for rule in RuleSet.allowRules where rule.matcher.matches(message) {
                return Verdict(action: rule.action, subAction: rule.subAction, firedRules: [rule.id])
            }
        }

        var score = 0
        var fired: [String] = []
        for family in RuleSet.families {
            let result = family.evaluate(message)
            score += result.score
            fired.append(contentsOf: result.fired)
        }

        guard score >= config.sensitivity.threshold else {
            return Verdict(action: .none, score: score, firedRules: fired)
        }
        return Verdict(action: .junk, score: score, firedRules: fired)
    }
}
