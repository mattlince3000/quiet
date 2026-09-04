@testable import FilterCore
import XCTest

/// SPEC §6: "App Group stores only integers, a Date, and an enum. Assert this
/// with a test on the Shared keys."
///
/// What this proves: the declared schema admits only scalar kinds, and the key
/// set has not grown. What it cannot prove: that no caller bypasses the schema
/// and writes a raw string. That is held by the `banned_shared_defaults` lint
/// rule and by `AppGroup`'s accessors being the only writers.
final class AppGroupSchemaTests: XCTestCase {
    func testEveryKeyHoldsAScalarKind() {
        for key in AppGroupKey.allCases {
            XCTAssertTrue(
                AppGroupKey.ValueKind.allCases.contains(key.kind),
                "\(key.rawValue) declares an unknown value kind"
            )
        }
    }

    /// A new key is a deliberate act, not a drive-by. If this fails, confirm the
    /// addition is a counter or a setting, then update the list.
    func testKeySetIsExactlyWhatSpecAllows() {
        XCTAssertEqual(
            Set(AppGroupKey.allCases.map(\.rawValue)),
            ["sensitivity", "allowsCodesAndAlerts", "blockedTotal", "blockedThisWeek", "weekStart", "lastRun"]
        )
    }

    func testNoKeyCouldHoldMessageContent() {
        // A body or a sender would have to be a string, and no key admits one.
        for key in AppGroupKey.allCases {
            XCTAssertNotEqual(key.kind.rawValue, "string")
        }
        let names = AppGroupKey.allCases.map { $0.rawValue.lowercased() }
        for forbidden in ["body", "message", "sender", "text", "content"] {
            XCTAssertFalse(names.contains { $0.contains(forbidden) }, "key name suggests content: \(forbidden)")
        }
    }

    func testRawValuesAreStableAndUnique() {
        let raws = AppGroupKey.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raws).count, raws.count)
        for raw in raws {
            XCTAssertFalse(raw.isEmpty)
        }
    }
}
