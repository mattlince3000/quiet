@testable import FilterCore
import XCTest

/// Evasion is the one threat the rules can lose to quietly: a missed domain
/// costs 50 points and nothing fails. These tests are the alarm.
final class NormalizationTests: XCTestCase {
    /// The bare ask, stripped of the STOP and chip-in boilerplate that would
    /// otherwise carry the score on its own. Only the domain signal is left, so
    /// if folding regresses these go straight to `.allow`.
    private func domainOnly(_ domain: String) -> Verdict {
        Classifier.classify(sender: "", body: "See \(domain) for details")
    }

    func testPlainDomainIsCaught() {
        let verdict = domainOnly("secure.actblue.com")
        XCTAssertTrue(verdict.firedRules.contains("processor.domain"))
        XCTAssertGreaterThanOrEqual(verdict.score, 50)
    }

    func testSpacedOutDomainIsCaught() {
        let verdict = domainOnly("a c t b l u e . c o m")
        XCTAssertTrue(verdict.firedRules.contains("processor.domainSpaced"), "\(verdict.firedRules)")
    }

    func testZeroWidthSplitDomainIsCaught() {
        let invisibles = [
            ("ZWSP", "\u{200B}"), ("ZWNJ", "\u{200C}"), ("ZWJ", "\u{200D}"),
            ("BOM", "\u{FEFF}"), ("soft hyphen", "\u{00AD}"), ("word joiner", "\u{2060}"),
        ]
        for (name, invisible) in invisibles {
            let verdict = domainOnly("act\(invisible)blue.com")
            XCTAssertTrue(verdict.firedRules.contains("processor.domain"), "\(name) defeated the rule")
        }
    }

    func testHomoglyphDomainIsCaught() {
        // Cyrillic а, е, о, с; Greek ο.
        for domain in ["\u{0430}ctblue.com", "actblu\u{0435}.com", "actblue.c\u{043E}m", "winr\u{0435}d.com"] {
            let verdict = domainOnly(domain)
            XCTAssertTrue(verdict.firedRules.contains("processor.domain"), "\(domain) → \(verdict.firedRules)")
        }
    }

    func testFullwidthDomainIsCaught() {
        let verdict = domainOnly("\u{FF41}\u{FF43}\u{FF54}\u{FF42}\u{FF4C}\u{FF55}\u{FF45}.com")
        XCTAssertTrue(verdict.firedRules.contains("processor.domain"), "\(verdict.firedRules)")
    }

    func testCombinedEvasionIsCaught() {
        // Fullwidth + zero-width + spacing + a homoglyph, all at once.
        let verdict = domainOnly("\u{FF41}\u{200B}c t \u{0431}lue.com".replacingOccurrences(of: "\u{0431}", with: "b"))
        XCTAssertTrue(verdict.score >= 50, "\(verdict.score) \(verdict.firedRules)")
    }

    /// The risk the condensed form introduces: stripping whitespace welds a
    /// sentence break into a domain. Short labels are excluded for exactly this.
    func testSentenceBreaksDoNotBecomeDomains() {
        let traps = [
            "Time to act. Blue skies ahead, see you Saturday!",
            "We win. Red team is up next week.",
            "Great job today. Anedot was not involved.",
        ]
        for body in traps {
            let verdict = Classifier.classify(sender: "", body: body)
            XCTAssertFalse(
                verdict.firedRules.contains("processor.domainSpaced"),
                "false domain match in: \(body) → \(verdict.firedRules)"
            )
            XCTAssertNotEqual(verdict.action, .junk, body)
        }
    }

    /// An obfuscated domain must not be scored twice.
    func testSpacedAndPlainDomainDoNotStack() {
        let verdict = Classifier.classify(sender: "", body: "actblue.com and a c t b l u e . c o m")
        XCTAssertEqual(verdict.score, 50, "\(verdict.firedRules)")
    }

    /// Folding must not disturb the signals that protect real texts.
    func testFoldingPreservesDigitsAndAmounts() {
        let code = Classifier.classify(sender: "", body: "Your verification code is 482913")
        XCTAssertEqual(code.action, .allow)

        let fullwidthCode = Classifier.classify(
            sender: "",
            body: "Your code is \u{FF14}\u{FF18}\u{FF12}\u{FF19}\u{FF11}\u{FF13}"
        )
        XCTAssertEqual(fullwidthCode.action, .allow, "fullwidth digits should fold to a usable code")

        let message = Message(sender: "", body: "Chip in $5 now")
        XCTAssertTrue(Patterns.amount.matches(message.lowercasedBody))
    }

    func testFoldingPreservesWordBoundaries() {
        // Condensing is domain-only; phrase rules must still see the space.
        let message = Message(sender: "", body: "chip in $5")
        XCTAssertTrue(Patterns.chipIn.matches(message.lowercasedBody))
        XCTAssertEqual(message.condensedBody, "chipin$5")
    }

    func testShoutingSurvivesFullwidthFolding() {
        let message = Message(sender: "", body: "\u{FF35}\u{FF32}\u{FF27}\u{FF25}\u{FF2E}\u{FF34}")
        XCTAssertGreaterThan(message.capsRatio, 0.9, "fullwidth capitals should still read as shouting")
    }

    func testFoldingIsBoundedOnHostileInput() {
        let hostile = String(repeating: "\u{200B}\u{0430}\u{FF41}", count: 3000)
        let start = Date()
        let verdict = Classifier.classify(sender: "", body: hostile)
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.1)
        XCTAssertNotEqual(verdict.action, .junk)
    }
}
