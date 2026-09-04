import Foundation

/// Signals about the shape of the message and the number that sent it, rather
/// than about what it says.
enum SignalRules {
    /// Link shorteners and the `verb.campaign.tld` vanity domains that campaign
    /// vendors hand out. Bare shorteners are common in legitimate texts too, so
    /// the allow rules run first and this only ever adds to an existing suspicion.
    static let links = RuleFamily(
        id: "link",
        cap: nil,
        rules: [
            Rule(
                id: "link.shortener",
                weight: 20,
                matcher: .bodyPattern(Pattern(
                    #"\b(?:bit\.ly|tinyurl\.com|t\.co|ow\.ly|rb\.gy|goo\.gl"#
                        + #"|buff\.ly|is\.gd|cutt\.ly|shorturl\.at|lnk\.to)\b"#
                        + #"|\b(?:act|go|vote|txt|give|donate|join|team|secure|my)"#
                        + #"\.[a-z0-9-]{2,40}\.(?:com|org|net|us|io|co)\b"#
                ))
            ),
        ]
    )

    /// Bulk senders: five-to-six digit short codes, and bare ten-digit 10DLC
    /// numbers with no country code.
    static let sender = RuleFamily(
        id: "sender",
        cap: nil,
        rules: [
            Rule(
                id: "sender.bulkNumber",
                weight: 15,
                matcher: .senderPattern(Pattern(#"^(?:\d{5,6}|\d{10})$"#))
            ),
        ]
    )

    /// Typographic urgency.
    static let shape = RuleFamily(
        id: "shape",
        cap: nil,
        rules: [
            Rule(id: "shape.shouty", weight: 10, matcher: .shape(.shouty)),
            Rule(id: "shape.longWithLink", weight: 10, matcher: .shape(.longWithLink)),
        ]
    )
}
