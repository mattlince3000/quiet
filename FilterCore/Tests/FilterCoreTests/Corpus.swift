import Foundation
import XCTest

/// Loads the corpus files that ship as test resources.
enum Corpus {
    enum LoadError: Error { case missing(String) }

    /// Returns one entry per non-blank, non-comment line.
    static func load(_ name: String) throws -> [String] {
        guard let url = Bundle.module.url(forResource: "Corpus/\(name)", withExtension: "txt") else {
            throw LoadError.missing(name)
        }
        return try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    /// Corpus lines carry no sender, so the corpus measures the body rules alone
    /// and neither side gets a free 15 points from `sender.bulkNumber`.
    static let noSender = ""
}
