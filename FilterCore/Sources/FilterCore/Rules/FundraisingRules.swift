import Foundation

/// The money ask: where the donation goes, how you get off the list, and the
/// urgency language used to produce the click.
enum FundraisingRules {
    /// A link to a political fundraising processor. Uncapped and heavy.
    static let processors = RuleFamily(
        id: "processor",
        cap: nil,
        rules: [
            Rule(id: "processor.domain", weight: 50, matcher: .bodyPhrases(FundraisingDomains.all)),
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
                matcher: .bodyPattern(Pattern(#"\bchip(?:ping|ped)?\s{1,3}in\b|\bpitch\s{1,3}in\b"#))
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
                matcher: .bodyPattern(Pattern(#"\$\s?\d"#))
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
                matcher: .bodyPattern(Pattern(
                    #"\bcan you (?:help|chip|give|rush|donate|pitch|send)\b"#
                        + #"|\bwill you (?:help|chip|give|donate|stand)\b"#
                        + #"|\bhelp us (?:reach|hit|close|win|fight|beat|stop)\b"#
                        + #"|\bwe(?:'re| are)\s{1,3}(?:still\s{1,3})?(?:\d{1,6}|short|behind|running out)\b"#
                ))
            ),
        ]
    )
}
