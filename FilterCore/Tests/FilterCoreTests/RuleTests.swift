@testable import FilterCore
import XCTest

/// Properties of the rule table itself, independent of any corpus line.
final class RuleTests: XCTestCase {
    func testRuleIdentifiersAreUnique() {
        let ids = RuleSet.ruleIdentifiers
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate rule id in the table")
    }

    func testEveryRuleHasAPositiveWeightAndFamilyCapsAreReachable() {
        for family in RuleSet.families {
            XCTAssertFalse(family.rules.isEmpty, "\(family.id) has no rules")
            for rule in family.rules {
                XCTAssertGreaterThan(rule.weight, 0, "\(rule.id) has weight \(rule.weight)")
            }
            if let cap = family.cap {
                let total = family.rules.reduce(0) { $0 + $1.weight }
                XCTAssertLessThan(cap, total, "\(family.id) cap \(cap) can never bind")
                XCTAssertGreaterThanOrEqual(cap, family.rules.map(\.weight).max() ?? 0)
            }
        }
    }

    func testFamilyCapBoundsItsContribution() {
        let message = Message(
            sender: "",
            body: "chip in match deadline $5 donate can you help us win 3x before midnight"
        )
        let solicitation = FundraisingRules.solicitation.evaluate(message)
        XCTAssertGreaterThan(solicitation.fired.count, 3)
        XCTAssertEqual(solicitation.score, 45)
    }

    func testSensitivityThresholds() {
        XCTAssertEqual(Config.Sensitivity.standard.threshold, 60)
        XCTAssertEqual(Config.Sensitivity.aggressive.threshold, 40)
        XCTAssertEqual(Config.default.sensitivity, .standard)
        XCTAssertTrue(Config.default.allowsCodesAndAlerts)
    }

    func testOneTimeCodeShortCircuitsBeforeScoring() {
        let verdict = Classifier.classify(sender: "27633", body: "Your verification code is 482913")
        XCTAssertEqual(verdict.action, .allow)
        XCTAssertEqual(verdict.score, 0)
        XCTAssertEqual(verdict.firedRules, ["allow.oneTimeCode"])
    }

    func testDeliveryAndFinanceMapToTransactionSubActions() {
        let delivery = Classifier.classify(sender: "12345", body: "Your package is out for delivery today.")
        XCTAssertEqual(delivery.action, .transaction)
        XCTAssertEqual(delivery.subAction, .transactionalOrders)

        let finance = Classifier.classify(sender: "12345", body: "A charge of $22.10 posted to your card ending 0091.")
        XCTAssertEqual(finance.action, .transaction)
        XCTAssertEqual(finance.subAction, .transactionalFinance)
    }

    /// A fundraising payment link overrides the allow rules, so wrapping the ask
    /// in service-alert phrasing does not buy an evader anything.
    func testFundraisingLinkVetoesAllowRules() {
        let verdict = Classifier.classify(
            sender: "50409",
            body: "Your package is out for delivery! Also chip in $5 before midnight: secure.actblue.com/donate/x Reply STOP"
        )
        XCTAssertEqual(verdict.action, .junk)
        XCTAssertTrue(verdict.firedRules.contains("processor.domain"))
    }

    func testBulkSenderRuleFiresOnShortCodesAndTenDigitNumbers() {
        let body = "hello there"
        for sender in ["50409", "27633", "8005551212"] {
            let message = Message(sender: sender, body: body)
            XCTAssertEqual(SignalRules.sender.evaluate(message).score, 15, "sender \(sender)")
        }
        for sender in ["+15551234567", "MOM", "1234", ""] {
            let message = Message(sender: sender, body: body)
            XCTAssertEqual(SignalRules.sender.evaluate(message).score, 0, "sender \(sender)")
        }
    }

    func testTurningOffAllowRulesLetsScoringProceed() {
        let body = "Your code is 482913. Chip in $5 before midnight: actblue.com/donate Reply STOP"
        XCTAssertEqual(Classifier.classify(sender: "", body: body, config: .default).action, .junk)
        let off = Config(sensitivity: .standard, allowsCodesAndAlerts: false)
        XCTAssertEqual(Classifier.classify(sender: "", body: body, config: off).action, .junk)
    }

    func testVerdictReportsFiredRulesForTestLab() {
        let verdict = Classifier.classify(
            sender: "50409",
            body: "URGENT: 3X MATCH expires at midnight! Rush $10 to winred.com/x Reply STOP to end"
        )
        XCTAssertEqual(verdict.action, .junk)
        XCTAssertTrue(verdict.firedRules.contains("processor.domain"))
        XCTAssertTrue(verdict.firedRules.contains("optOut.stop"))
        XCTAssertGreaterThan(verdict.score, Config.Sensitivity.standard.threshold)
    }
}
