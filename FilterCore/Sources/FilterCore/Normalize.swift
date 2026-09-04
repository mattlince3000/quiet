import Foundation

/// Folds the tricks an evader uses to break literal matching, without changing
/// what the message says.
///
/// Every transform here is meaning-preserving for the English-language rules we
/// run: none of them merges words, and none touches digits — one-time codes and
/// dollar amounts have to survive intact.
enum Normalize {
    /// Scalars that render as nothing and exist only to split a word.
    ///
    /// These are matched as scalars, not `Character`s: a zero-width joiner binds
    /// into the neighbouring grapheme cluster, so iterating by `Character` never
    /// sees it and the evasion sails through.
    private static let invisibles: Set<Unicode.Scalar> = [
        "\u{200B}", // zero width space
        "\u{200C}", // zero width non-joiner
        "\u{200D}", // zero width joiner
        "\u{2060}", // word joiner
        "\u{FEFF}", // zero width no-break space
        "\u{00AD}", // soft hyphen
        "\u{180E}", // mongolian vowel separator
        "\u{034F}", // combining grapheme joiner
    ]

    /// Cyrillic and Greek letters that are visually indistinguishable from ASCII.
    /// A Cyrillic "а" in "аctblue.com" reads identically and matches nothing.
    private static let confusables: [Unicode.Scalar: Unicode.Scalar] = [
        // Cyrillic lowercase
        "\u{0430}": "a", "\u{0435}": "e", "\u{043E}": "o", "\u{0440}": "p",
        "\u{0441}": "c", "\u{0445}": "x", "\u{0443}": "y", "\u{0456}": "i",
        "\u{0458}": "j", "\u{0455}": "s", "\u{043A}": "k", "\u{043C}": "m",
        "\u{0442}": "t", "\u{043D}": "h", "\u{0432}": "b", "\u{0433}": "r",
        // Cyrillic uppercase
        "\u{0410}": "A", "\u{0415}": "E", "\u{041E}": "O", "\u{0420}": "P",
        "\u{0421}": "C", "\u{0425}": "X", "\u{0423}": "Y", "\u{041A}": "K",
        "\u{041C}": "M", "\u{0422}": "T", "\u{041D}": "H", "\u{0412}": "B",
        // Greek lowercase
        "\u{03B1}": "a", "\u{03B5}": "e", "\u{03BF}": "o", "\u{03C1}": "p",
        "\u{03B9}": "i", "\u{03BA}": "k", "\u{03C4}": "t", "\u{03C5}": "u",
        "\u{03C7}": "x", "\u{03BD}": "v", "\u{03C3}": "s",
        // Greek uppercase
        "\u{0391}": "A", "\u{0395}": "E", "\u{039F}": "O", "\u{03A1}": "P",
        "\u{0396}": "Z", "\u{039A}": "K", "\u{03A4}": "T", "\u{03A7}": "X",
    ]

    /// Compatibility-normalizes (folding fullwidth and styled letters to ASCII),
    /// drops invisibles, and maps confusables. Case is preserved so that the
    /// shouting heuristic still sees the original capitals.
    static func fold(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.precomposedStringWithCompatibilityMapping.unicodeScalars {
            if invisibles.contains(scalar) {
                continue
            }
            scalars.append(confusables[scalar] ?? scalar)
        }
        return String(scalars)
    }

    /// Removes every whitespace character.
    ///
    /// Only domain matchers look at this form: collapsing spaces would weld
    /// "chip in" into "chipin" and break phrase matching everywhere else.
    static func condense(_ text: String) -> String {
        text.filter { !$0.isWhitespace }
    }
}
