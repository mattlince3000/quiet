@testable import FilterCore
import XCTest

/// The only untrusted input is a string. These tests treat it as hostile.
final class AdversarialTests: XCTestCase {
    /// SPEC §5: 50 ms budget per rule against a 10 KB adversarial body.
    private let perRuleBudget = 0.050

    private static let adversarialBodies: [String] = [
        String(repeating: "a", count: 10_000),
        String(repeating: "$1 chip in match deadline ", count: 400),
        String(repeating: "stop to end ", count: 900),
        String(repeating: "https://act.a-b.com/x ", count: 500),
        String(repeating: "!", count: 10_000),
        String(repeating: "1234 code ", count: 1000),
        String(repeating: "\u{0}\u{1}\u{7f}", count: 3000),
        String(repeating: "🚨", count: 5000),
        String(repeating: "aaaa.com ", count: 1100),
        String(repeating: "A", count: 5000) + String(repeating: "0", count: 5000),
    ]

    func testNoRuleExceedsItsTimeBudgetOnAdversarialInput() {
        let matchers: [(String, Matcher)] =
            RuleSet.allowRules.map { ($0.id, $0.matcher) }
                + RuleSet.families.flatMap { family in family.rules.map { ($0.id, $0.matcher) } }

        for body in Self.adversarialBodies {
            let message = Message(sender: String(repeating: "9", count: 10_000), body: body)
            for (id, matcher) in matchers {
                let start = Date()
                _ = matcher.matches(message)
                let elapsed = Date().timeIntervalSince(start)
                XCTAssertLessThan(elapsed, perRuleBudget, "\(id) took \(elapsed)s")
            }
        }
    }

    func testBodyAndSenderAreTruncatedBeforeMatching() {
        let message = Message(
            sender: String(repeating: "9", count: 50_000),
            body: String(repeating: "z", count: 50_000)
        )
        XCTAssertEqual(message.body.count, Message.maxBodyLength)
        XCTAssertEqual(message.sender.count, Message.maxBodyLength)

        let short = Message(sender: "12345", body: "hi")
        XCTAssertEqual(short.sender, "12345")
        XCTAssertEqual(short.body, "hi")
    }

    /// A junk signal hidden past the truncation point simply is not seen. That
    /// is the intended trade: bounded work beats complete work.
    func testClassificationStaysBoundedForHugeBodies() {
        let padding = String(repeating: "hello ", count: 5000)
        let verdict = Classifier.classify(sender: "12345", body: padding + "actblue.com chip in $5 Reply STOP")
        XCTAssertEqual(verdict.action, .none)
    }

    func testEmptyAndDegenerateInputsAreHandled() {
        for body in ["", " ", "\n\n", "\u{0}", "🚨🚨🚨"] {
            let verdict = Classifier.classify(sender: "", body: body)
            XCTAssertNotEqual(verdict.action, .junk, "body: \(body.debugDescription)")
        }
    }

    func testWholeClassificationIsFastEnoughForTheExtension() {
        let body = String(repeating: "URGENT chip in $5 before the midnight deadline! act.x-y.com ", count: 200)
        let start = Date()
        for _ in 0 ..< 100 {
            _ = Classifier.classify(sender: "50409", body: body)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0, "100 classifications took \(elapsed)s")
    }
}
