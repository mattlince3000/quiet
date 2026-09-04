import Foundation

/// A regex compiled once, at static-initialization time.
///
/// `NSRegularExpression` is immutable and `Sendable`, so rule tables can live in
/// `static let` storage under strict concurrency without any unchecked escapes.
/// Patterns are written without nested quantifiers and every wildcard run is
/// explicitly bounded; combined with `Message.maxBodyLength` this bounds match time.
struct Pattern: Sendable {
    let source: String
    private let regex: NSRegularExpression

    init(_ source: String) {
        self.source = source
        // Rule patterns are compile-time constants covered by `RuleTests`; a bad
        // pattern is a build-time authoring error, never runtime input.
        guard let compiled = try? NSRegularExpression(pattern: source, options: [.caseInsensitive]) else {
            preconditionFailure("Invalid rule pattern: \(source)")
        }
        regex = compiled
    }

    func matches(_ text: String) -> Bool {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

/// How a rule decides whether it applies. Data, not control flow.
enum Matcher: Sendable {
    /// Any of these lowercased substrings appears in the body.
    case bodyPhrases([String])
    /// Any of these appears in the body once whitespace is removed, catching
    /// "a c t b l u e . c o m". Only safe for strings that cannot occur across
    /// an ordinary sentence break — see `FundraisingDomains.condensable`.
    case condensedPhrases([String])
    /// The pattern matches the body.
    case bodyPattern(Pattern)
    /// The pattern matches the sender string.
    case senderPattern(Pattern)
    /// A precomputed shape signal that regex cannot express cheaply.
    case shape(Shape)

    func matches(_ message: Message) -> Bool {
        switch self {
        case let .bodyPhrases(phrases):
            phrases.contains { message.lowercasedBody.contains($0) }
        case let .condensedPhrases(phrases):
            phrases.contains { message.condensedBody.contains($0) }
        case let .bodyPattern(pattern):
            pattern.matches(message.lowercasedBody)
        case let .senderPattern(pattern):
            pattern.matches(message.sender)
        case let .shape(shape):
            shape.matches(message)
        }
    }
}

/// Signals derived from the message as a whole rather than from its wording.
enum Shape: Sendable {
    /// Shouting: mostly capitals, or a pile of exclamation marks.
    case shouty
    /// A long body carrying a link — the classic robotext silhouette.
    case longWithLink
    /// Looks like a person typing: short, no link, no opt-out boilerplate.
    /// A fundraising blast has to get you somewhere, so it carries a link.
    case personal
    /// Carries a link of any kind.
    case linked

    func matches(_ message: Message) -> Bool {
        switch self {
        case .shouty:
            message.capsRatio > 0.4 || message.exclamationCount >= 3
        case .longWithLink:
            message.body.count > 120 && message.containsLink
        case .personal:
            !message.containsLink && !message.containsOptOut && message.body.count <= 160
        case .linked:
            message.containsLink
        }
    }
}

/// One junk signal.
struct Rule: Sendable {
    let id: String
    let weight: Int
    let matcher: Matcher
}

/// A group of related junk signals sharing a contribution ceiling, so that a
/// message stuffed with synonyms from one family cannot alone clear the threshold.
struct RuleFamily: Sendable {
    let id: String
    /// Maximum this family may contribute, or `nil` for no ceiling.
    let cap: Int?
    let rules: [Rule]

    /// Returns the capped score and the ids of the rules that fired.
    func evaluate(_ message: Message) -> (score: Int, fired: [String]) {
        var total = 0
        var fired: [String] = []
        for rule in rules where rule.matcher.matches(message) {
            total += rule.weight
            fired.append(rule.id)
        }
        if let cap {
            total = min(total, cap)
        }
        return (total, fired)
    }
}

/// A combination that disqualifies a message from the allow rules entirely.
/// Every matcher in `all` must match for the veto to apply.
struct AllowVeto: Sendable {
    let id: String
    let all: [Matcher]

    func matches(_ message: Message) -> Bool {
        all.allSatisfy { $0.matches(message) }
    }
}

/// A rule that short-circuits classification to a non-junk verdict.
struct AllowRule: Sendable {
    let id: String
    let action: Verdict.Action
    let subAction: Verdict.SubAction
    let matcher: Matcher
}
