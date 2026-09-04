import Foundation

/// A normalized, length-bounded view of one inbound message.
///
/// Everything a rule needs is computed once here so that matching stays linear
/// in the body length no matter how many rules run.
public struct Message: Sendable {
    /// ReDoS guard: bodies are truncated before any pattern ever sees them.
    public static let maxBodyLength = 1000

    public let sender: String
    public let body: String
    /// Lowercased `body`, for case-insensitive substring matchers.
    let lowercasedBody: String
    /// Fraction of cased letters that are uppercase. Zero when there are no letters.
    let capsRatio: Double
    let exclamationCount: Int
    let containsLink: Bool
    /// True when the body carries bulk-send opt-out boilerplate.
    let containsOptOut: Bool

    public init(sender: String, body: String) {
        self.sender = String(sender.prefix(Message.maxBodyLength))
        let truncated = String(body.prefix(Message.maxBodyLength))
        self.body = truncated
        lowercasedBody = truncated.lowercased()

        var uppercase = 0
        var cased = 0
        var bangs = 0
        for character in truncated {
            if character == "!" {
                bangs += 1
            }
            guard character.isLetter, character.isCased else { continue }
            cased += 1
            if character.isUppercase {
                uppercase += 1
            }
        }
        capsRatio = cased > 0 ? Double(uppercase) / Double(cased) : 0
        exclamationCount = bangs

        containsLink = Patterns.link.matches(lowercasedBody)
        containsOptOut = Patterns.optOut.matches(lowercasedBody)
    }
}
