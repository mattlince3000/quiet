import Foundation

/// Turns a rule identifier into something a family member can read.
///
/// Derived rather than hand-mapped, so adding a rule never leaves Test Lab
/// showing a raw identifier: "solicitation.chipIn" becomes
/// "Donation language — chip in".
enum RuleLabel {
    private static let families: [String: String] = [
        "allow": "Allowed",
        "veto": "Override",
        "processor": "Fundraising website",
        "optOut": "Bulk-text opt-out",
        "solicitation": "Donation language",
        "political": "Campaign words",
        "link": "Link",
        "sender": "Sender",
        "shape": "Style",
    ]

    static func describe(_ identifier: String) -> String {
        let parts = identifier.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return humanize(identifier) }
        let family = families[parts[0]] ?? humanize(parts[0])
        return "\(family) — \(humanize(parts[1]))"
    }

    /// "chipIn" -> "chip in", "domainSpaced" -> "domain spaced".
    private static func humanize(_ camelCase: String) -> String {
        var words: [String] = []
        var current = ""
        for character in camelCase {
            if character.isUppercase, !current.isEmpty {
                words.append(current)
                current = String(character).lowercased()
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty {
            words.append(current)
        }
        return words.joined(separator: " ")
    }
}
