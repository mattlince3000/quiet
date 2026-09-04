import Foundation

/// Patterns shared by more than one rule, or needed while normalizing a `Message`.
enum Patterns {
    /// A bare domain or an explicit URL. Deliberately conservative: it wants a
    /// known TLD so that "see you at 5pm.ok" is not a link.
    static let link = Pattern(
        #"https?://"#
            + #"|\bwww\.[a-z0-9-]{2,40}\."#
            + #"|\b[a-z0-9][a-z0-9-]{1,40}\.(?:com|org|net|io|us|co|ly|gov|edu|info|link|app|gl|to|xyz)\b"#
    )

    /// Bulk-messaging opt-out boilerplate. Shared by the `optOut` rule and by
    /// `Message`, which uses it to tell bulk sends from person-to-person texts.
    static let optOut = Pattern(
        #"\b(?:reply|txt|text|send|msg)\s{0,3}stop\b"#
            + #"|\bstop\s{0,3}(?:to|2)\s{0,3}(?:end|quit|opt|unsub|cancel|stop)"#
            + #"|\bstop2end\b|\bstop=end\b"#
    )

    /// "chip in" / "pitch in".
    static let chipIn = Pattern(#"\bchip(?:ping|ped)?\s{1,3}in\b|\bpitch\s{1,3}in\b"#)

    /// A dollar figure.
    static let amount = Pattern(#"\$\s?\d"#)

    /// A direct, second-person request. Present tense and pointed at you, which
    /// is what separates "can you chip in $10" from "did you chip in for the gift".
    static let directAsk = Pattern(
        #"\bcan you (?:help|chip|give|rush|donate|pitch|send)\b"#
            + #"|\bwill you (?:help|chip|give|donate|stand)\b"#
            + #"|\bhelp us (?:reach|hit|close|win|fight|beat|stop)\b"#
            + #"|\bwe(?:'re| are)\s{1,3}(?:still\s{1,3})?(?:\d{1,6}|short|behind|running out)\b"#
    )
}

/// Payment processors and voter-contact platforms used almost exclusively by
/// political fundraising programs. Presence of one of these is the single
/// strongest signal we have — strong enough to veto the allow rules.
enum FundraisingDomains {
    static let all: [String] = [
        "actblue.com",
        "act.blue",
        "winred.com",
        "win.red",
        "anedot.com",
        "ngpvan.com",
        "actionnetwork.org",
        "donorbox.org",
        "givebutter.com",
        "secure.mobilize.us",
        "revv.co",
        "fundraiseup.com",
    ]
}
