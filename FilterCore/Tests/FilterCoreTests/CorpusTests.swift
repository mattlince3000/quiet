import FilterCore
import XCTest

/// The contract: catch nearly all of the spam, and never touch a real text.
final class CorpusTests: XCTestCase {
    /// SPEC §7. A missed robotext is an annoyance, so this bar is high but not 1.0.
    private let requiredRecall = 0.95

    func testSpamRecallMeetsBar() throws {
        let samples = try Corpus.load("spam")
        XCTAssertGreaterThanOrEqual(samples.count, 20, "corpus too small to mean anything")

        var missed: [String] = []
        for sample in samples {
            let verdict = Classifier.classify(sender: Corpus.noSender, body: sample, config: .default)
            if verdict.action != .junk {
                missed.append("[\(verdict.score)] \(sample)")
            }
        }

        let recall = Double(samples.count - missed.count) / Double(samples.count)
        XCTAssertGreaterThanOrEqual(
            recall, requiredRecall,
            "recall \(recall) below \(requiredRecall). Missed:\n" + missed.joined(separator: "\n")
        )
    }

    /// Zero tolerance, at every sensitivity. A filtered one-time code or
    /// doctor's reminder is a real harm.
    func testNoFalsePositivesAtAnySensitivity() throws {
        let samples = try Corpus.load("legit")
        XCTAssertGreaterThanOrEqual(samples.count, 20)

        for sensitivity in Config.Sensitivity.allCases {
            let config = Config(sensitivity: sensitivity, allowsCodesAndAlerts: true)
            for sample in samples {
                let verdict = Classifier.classify(sender: Corpus.noSender, body: sample, config: config)
                XCTAssertNotEqual(
                    verdict.action, .junk,
                    "false positive at \(sensitivity.rawValue) [\(verdict.score)] \(verdict.firedRules): \(sample)"
                )
            }
        }
    }

    /// A bulk-sender number must never be enough to junk an otherwise clean text.
    func testBulkSenderAloneNeverJunks() throws {
        for sample in try Corpus.load("legit") {
            for sender in ["27633", "262966", "8005551212"] {
                let verdict = Classifier.classify(sender: sender, body: sample, config: .default)
                XCTAssertNotEqual(verdict.action, .junk, "false positive from sender \(sender): \(sample)")
            }
        }
    }

    /// Turning off the allow rules must not turn on false positives for the
    /// person-to-person texts, which are scored purely on their wording.
    func testCodesAndAlertsOffStillLeavesRealTextsAlone() throws {
        let config = Config(sensitivity: .standard, allowsCodesAndAlerts: false)
        for sample in try Corpus.load("legit") {
            let verdict = Classifier.classify(sender: Corpus.noSender, body: sample, config: config)
            XCTAssertNotEqual(verdict.action, .junk, "[\(verdict.score)] \(verdict.firedRules): \(sample)")
        }
    }
}
