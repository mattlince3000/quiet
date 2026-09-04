import Foundation

/// The money ask: where the donation goes, how you get off the list, and the
/// urgency language used to produce the click.
enum FundraisingRules {
    /// A link to a political fundraising processor, spelled plainly or spaced
    /// out to dodge a literal match. The cap equals one hit: both rules describe
    /// the same signal, so an obfuscated domain is not worth double.
    static let processors = RuleFamily(
        id: "processor",
        cap: 50,
        rules: [
            Rule(id: "processor.domain", weight: 50, matcher: .bodyPhrases(FundraisingDomains.all)),
            Rule(
                id: "processor.domainSpaced",
                weight: 50,
                matcher: .condensedPhrases(FundraisingDomains.condensable)
            ),
        ]
    )

    /// Bulk-messaging opt-out boilerplate. Legitimate senders use it too, which
    /// is why it is only worth 25 on its own.
    static let optOut = RuleFamily(
        id: "optOut",
        cap: nil,
        rules: [
            Rule(
                id: "optOut.stop",
                weight: 25,
                matcher: .bodyPattern(Patterns.optOut)
            ),
        ]
    )

    /// Donation and urgency language. Individually weak, collectively decisive,
    /// capped so that a thesaurus alone cannot clear the threshold.
    static let solicitation = RuleFamily(
        id: "solicitation",
        cap: 45,
        rules: [
            Rule(
                id: "solicitation.chipIn",
                weight: 15,
                matcher: .bodyPattern(Patterns.chipIn)
            ),
            Rule(
                id: "solicitation.match",
                weight: 15,
                matcher: .bodyPattern(Pattern(
                    #"\bmatch(?:ed|ing|es)?\b|\b\d{1,2}\s?x\b"#
                        + #"|\bdoubled?\b|\btripled?\b"#
                ))
            ),
            Rule(
                id: "solicitation.deadline",
                weight: 15,
                matcher: .bodyPattern(Pattern(
                    #"\bbefore midnight\b|\bdeadline\b|\bexpires?\b"#
                        + #"|\bends? (?:at )?midnight\b|\bfinal (?:notice|hours|call|chance)\b"#
                        + #"|\bhours? left\b|\bact now\b|\blast chance\b|\bclosing in\b"#
                ))
            ),
            Rule(
                id: "solicitation.amount",
                weight: 15,
                matcher: .bodyPattern(Patterns.amount)
            ),
            Rule(
                id: "solicitation.give",
                weight: 15,
                matcher: .bodyPattern(Pattern(
                    #"\brush\b|\bdonate\b|\bdonation\b|\bdonors?\b"#
                        + #"|\bcontribut(?:e|ion|ions)\b|\bgrassroots\b"#
                        + #"|\bfundrais(?:e|er|ing)\b|\bgifts?\b"#
                ))
            ),
            Rule(
                id: "solicitation.ask",
                weight: 15,
                matcher: .bodyPattern(Patterns.directAsk)
            ),
        ]
    )
}
