import Foundation

/// Rules that short-circuit classification to a non-junk verdict.
///
/// These are the safety net: a filtered one-time code or doctor's reminder is a
/// real harm, a missed campaign text is an annoyance. When tuning, add an allow
/// rule before you lower a junk weight.
enum AllowRules {
    /// Evaluated in order; the first match wins.
    static let all: [AllowRule] = [
        AllowRule(
            id: "allow.oneTimeCode",
            action: .allow,
            subAction: .none,
            matcher: .bodyPattern(Pattern(#"\b(?:code|otp|passcode|pin|2fa)\b[^\n]{0,40}\b\d{4,8}\b"#))
        ),
        AllowRule(
            id: "allow.oneTimeCodeLeading",
            action: .allow,
            subAction: .none,
            matcher: .bodyPattern(Pattern(
                #"\b\d{4,8}\b[^\n]{0,40}\b(?:is your|code|passcode|otp|verification)\b"#
            ))
        ),
        AllowRule(
            id: "allow.delivery",
            action: .transaction,
            subAction: .transactionalOrders,
            matcher: .bodyPhrases([
                "out for delivery", "has shipped", "have shipped", "your package",
                "your order", "tracking number", "arriving today", "arriving tomorrow",
                "was delivered", "been delivered", "delivery attempt", "your shipment",
                "ready for pickup", "ready for you to pick up", "order confirmed",
            ])
        ),
        AllowRule(
            id: "allow.finance",
            action: .transaction,
            subAction: .transactionalFinance,
            matcher: .bodyPhrases([
                "debit card", "credit card", "card ending", "account ending",
                "was charged", "a charge of", "transaction of", "direct deposit",
                "your balance", "available balance", "did you make this",
                "did you authorize", "fraud alert", "was declined", "autopay",
                "zelle", "payment posted", "payment is due", "statement is ready",
                "overdraft", "deposited into", "your receipt", "receipt for your",
                "tax-deductible", "tax deductible",
            ])
        ),
        AllowRule(
            id: "allow.reminders",
            action: .transaction,
            subAction: .transactionalReminders,
            matcher: .bodyPhrases([
                "appointment", "your reservation", "prescription", "refill",
                "reschedule", "check-in", "your visit", "lab results",
                "test results", "pharmacy", "is ready to be picked up",
            ])
        ),
        AllowRule(
            id: "allow.serviceAlert",
            action: .transaction,
            subAction: .transactionalReminders,
            matcher: .bodyPhrases([
                "early dismissal", "school will be closed", "schools will be closed",
                "schools are closed", "snow day", "your student", "power outage",
                "outage in your area", "service has been restored", "water main",
                "boil water", "evacuation order", "shelter in place", "amber alert",
                "flood warning", "your driver",
            ])
        ),
        AllowRule(
            id: "allow.personal",
            action: .allow,
            subAction: .none,
            matcher: .shape(.personal)
        ),
        AllowRule(
            id: "allow.civicInfo",
            action: .allow,
            subAction: .none,
            matcher: .bodyPhrases([
                "your polling place", "your polling location", "polling place has",
                "board of elections", "your ballot was", "your ballot has been",
                "your voter registration is", "jury duty", "your mail ballot was",
            ])
        ),
    ]

    /// Combinations that disqualify a message from the allow rules.
    ///
    /// Without these the allow rules are the obvious evasion: dress a donation
    /// ask up as a service alert, a civic notice, or a note from a friend. Each
    /// veto is deliberately narrow, because every one of them is a chance to
    /// junk something real.
    static let vetoes: [AllowVeto] = [
        // Nothing legitimate asks you to confirm a delivery at actblue.com.
        AllowVeto(id: "veto.processor", all: [.bodyPhrases(FundraisingDomains.all)]),
        AllowVeto(id: "veto.processorSpaced", all: [.condensedPhrases(FundraisingDomains.condensable)]),
        // A direct second-person ask naming a dollar figure. "Can you chip in
        // $10" is a solicitation; "did you ever chip in for Kevin's gift" is a
        // friend, and does not match `directAsk`.
        AllowVeto(id: "veto.directAsk", all: [.bodyPattern(Patterns.directAsk), .bodyPattern(Patterns.amount)]),
        // "Chip in $5" plus somewhere to go. The link is what makes it a blast
        // rather than a person; a receipt or a friend's text has no ask-and-link.
        AllowVeto(
            id: "veto.linkedAsk",
            all: [.bodyPattern(Patterns.chipIn), .bodyPattern(Patterns.amount), .shape(.linked)]
        ),
    ]
}
