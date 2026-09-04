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
