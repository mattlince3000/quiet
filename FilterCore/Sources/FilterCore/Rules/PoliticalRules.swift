import Foundation

/// Campaign vocabulary. Capped low on purpose: talking about an election is not
/// spam, and civic notices legitimately use every word in this family.
enum PoliticalRules {
    static let political = RuleFamily(
        id: "political",
        cap: 30,
        rules: [
            Rule(
                id: "political.campaign",
                weight: 10,
                matcher: .bodyPattern(Pattern(#"\bcampaign\b|\bcandidates?\b|\bre-?elect(?:ion)?\b"#))
            ),
            Rule(
                id: "political.office",
                weight: 10,
                matcher: .bodyPattern(Pattern(
                    #"\bsenate\b|\bsenators?\b|\bgovernor\b|\bmayor\b"#
                        + #"|\bcongress(?:ional|man|woman)?\b|\bpresidential\b"#
                        + #"|\battorney general\b|\bhouse seat\b"#
                ))
            ),
            Rule(
                id: "political.party",
                weight: 10,
                matcher: .bodyPattern(Pattern(
                    #"\bgop\b|\bdemocrats?\b|\bdemocratic\b|\brepublicans?\b"#
                        + #"|\bdems?\b|\bmaga\b|\bsuper\s{1,3}pac\b|\bpac\b"#
                ))
            ),
            Rule(
                id: "political.electoral",
                weight: 10,
                matcher: .bodyPattern(Pattern(
                    #"\bpolls?\b|\bpolling\b|\bballots?\b|\bvoters?\b|\belection\b"#
                        + #"|\bprimary\b|\bswing (?:state|district)\b|\bturnout\b"#
                ))
            ),
            Rule(
                id: "political.opponent",
                weight: 10,
                matcher: .bodyPattern(Pattern(
                    #"\bopponent\b|\bout-?rais(?:e|es|ing|ed)\b|\bflip the\b"#
                        + #"|\btake back the\b|\bmajority\b|\bextremists?\b|\bradical\b"#
                ))
            ),
        ]
    )
}
