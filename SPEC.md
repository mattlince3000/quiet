# SPEC — Robotext Filter for iPhone

Working name: **Quiet** (rename freely; do not use "ActBlue", "WinRed", or any party/vendor name in the app name, icon, or metadata — App Review guideline 5.2.1 trademark).

## 1. Purpose

Free iOS app that silences robo-campaign and fundraising spam texts (SMS / MMS / RCS) from unknown senders using Apple's sanctioned Message Filter Extension. Everything runs on-device. No accounts, no network, no analytics.

### Non-goals (v1)
- No iMessage filtering (Apple does not expose it).
- No server-side classification (no Associated Domains, no `deferQueryRequestToNetwork`).
- No contact access. iOS only routes *unknown* senders to us; the extension never sees contacts.
- No message storage. Message text lives in the extension's memory for the duration of one `handle()` call and nowhere else.
- No Core ML model in v1. Rules first; ML is v2 once the corpus proves the need.

## 2. Platform facts that shape the design

- Framework: `IdentityLookup`. Extension subclass of `ILMessageFilterExtension`, implements `ILMessageFilterQueryHandling` (and `ILMessageFilterCapabilitiesQueryHandling` to declare supported sub-actions).
- Input per message: `sender` (phone number / short code string) and `messageBody`. That's it.
- Output: `ILMessageFilterQueryResponse.action` ∈ `.none`, `.allow`, `.junk`, `.promotion`, `.transaction`; optional `subAction` (e.g. `.promotionalOffers`, `.transactionalFinance`).
- Extensions do not run in the Simulator — device testing only. Do all logic in a Swift package so unit tests run on macOS without a device.
- Tight memory/time budget in the extension: no third-party frameworks, no large tables, precompiled regexes, bounded input length.
- User must enable us: Settings → Apps → Messages → Unknown & Spam → Text Message Filter → pick this app. The toggle may be absent on some carriers/regions; onboarding must handle "I don't see it."
- iOS 26+ already has "Screen Unknown Senders" + built-in spam detection. Position this app as a stricter, fundraising-specific layer, not a replacement. Onboarding should tell users to turn *both* on.
- Filtering doesn't apply to senders the user has replied to 3+ times.

## 3. Product

Three screens. Nothing else.

| Screen | Contents |
|---|---|
| **Onboarding** | 3-step enable walkthrough with a deep link to Settings (`App-prefs:` is unreliable; use `UIApplication.openSettingsURLString` and written steps). "Don't see the toggle?" fallback. |
| **Home** | Filter status (on/off detected via shared App Group "last seen" timestamp), counts blocked this week/total, sensitivity picker (Standard / Aggressive), toggle "Allow one-time codes and delivery alerts" (default on). |
| **Test Lab** | Paste any text → see verdict + which rules fired. Used by family for trust, by App Review for verification, and by you for debugging. |

Design: SwiftUI, system fonts, system colors, one accent color, supports Dynamic Type and Dark Mode. Family members are the users — big text, no jargon, no settings sprawl.

## 4. Architecture

```
Quiet/
├── project.yml              # XcodeGen — project structure lives in text, not .pbxproj
├── App/                     # SwiftUI app target (iOS 17+)
├── FilterExtension/         # ILMessageFilterExtension, ~40 lines, calls FilterCore
├── FilterCore/              # Swift package, platform-agnostic, 100% of the logic
│   ├── Sources/FilterCore/
│   │   ├── Classifier.swift     # public func classify(sender:body:config:) -> Verdict
│   │   ├── Rules/               # one file per rule family
│   │   ├── Verdict.swift        # action, subAction, score, firedRules
│   │   └── Config.swift         # sensitivity, allow-codes flag
│   └── Tests/FilterCoreTests/
│       ├── Corpus/spam.txt      # one message per line, real examples (numbers redacted)
│       ├── Corpus/legit.txt     # OTPs, bank alerts, doctor, school, delivery, friends
│       └── CorpusTests.swift    # asserts recall on spam ≥ 0.95, false positives on legit == 0
└── Shared/                  # App Group constants, UserDefaults keys
```

- App and extension share an **App Group** for: config (sensitivity, flags) and counters (blocked count, last-run timestamp). Nothing else is ever written.
- Extension `handle()` = read config → `FilterCore.classify` → map Verdict to response → increment counter → complete. Any thrown error → `.none` (fail open; never lose a legitimate text).
- FilterCore has zero dependencies and compiles for macOS so `swift test` runs in ~1s.

## 5. Classifier (v1: weighted rules)

Score = sum of rule weights; thresholds by sensitivity (Standard 60, Aggressive 40). Anything hitting an **allow** rule short-circuits to `.allow`.

**Allow rules (evaluate first)**
- One-time code pattern (`\b\d{4,8}\b` near "code", "verification", "OTP", "passcode").
- Delivery / appointment / bank-transaction phrasing → `.transaction` with matching subAction, not junk.
- Service alerts (school closure, utility outage, ride/driver) and civic notices ("your polling place",
  "your ballot", jury duty) → not junk. Civic notices are unavoidably full of political nouns; without
  this rule a moved-polling-place text scores as fundraising.
- **Person-to-person shape**: no link, no opt-out boilerplate, ≤ 160 chars → `.allow`. A fundraising
  blast has to get you somewhere, so it carries a link; a friend asking whether you chipped in for a
  co-worker's gift does not. This is what keeps ordinary texts out of the solicitation family's reach.

**Allow veto:** three narrow combinations skip the allow rules entirely — a fundraising processor
domain; a direct second-person ask naming a dollar figure ("can you chip in $10"); and "chip in $X"
alongside a link. Without them the allow rules are the obvious evasion: dress the ask up as a service
alert, a civic notice, or a note from a friend. Each veto is a chance to junk something real, so they
stay narrow — "did you ever chip in for Kevin's gift? I put in $20" matches none of them.

**Known miss (accepted):** a short, linkless, person-shaped ask — "a volunteer with the campaign.
Can you chip in $10?" — scores 55 and so clears Aggressive but not Standard. Catching it at Standard
needs a rule keyed on "volunteer with the campaign", a hair from the wording of a real text thanking
you for volunteering. Per CLAUDE.md the miss is the cheaper error. Pinned by
`testPersonShapedAskIsCaughtOnlyAtAggressive`.

**Junk signals (weights are starting points; tune against corpus)**
| Signal | Weight |
|---|---|
| Fundraising domains: actblue.com, secure.actblue.com, winred.com, ngpvan, actionnetwork.org, anedot, text-to-give shorteners | 50 |
| "Reply STOP" / "STOP to end" / "Txt STOP" | 25 |
| URL shortener (bit.ly, t.co, tinyurl, and campaign-specific like `act.*`, `go.*`, `vote.*` subdomains) | 20 |
| Donation / matching language: "chip in", "match", "3x", "before midnight", "deadline", "$" + amount | 15 each, cap 45 |
| Political nouns: candidate, senate, governor, GOP, Dem, poll, ballot, PAC | 10 each, cap 30 |
| Sender is 5–6 digit short code or 10DLC pattern with no country code | 15 |
| ALL CAPS ratio > 40% or ≥ 3 exclamation marks | 10 |
| Body length > 120 chars AND contains a URL | 10 |

Rules are data (a Swift array of `Rule { id, pattern, weight }`), not branching code, so Claude Code can add/tune without touching control flow.

**Regex safety:** every pattern is compiled once, statically; no nested quantifiers; input truncated to 1,000 chars before matching (ReDoS guard). A unit test runs every rule against a 10 KB adversarial string with a 50 ms timeout.

**v2 (only if corpus shows rules plateau):** `MLTextClassifier` via Create ML trained on the corpus, bundled in the extension, used as one more weighted signal. Keep the model under a few MB.

## 6. Privacy & security requirements

- Zero network. No `URLSession` anywhere in the codebase. Enforce with a lint rule (custom SwiftLint regex rule that fails on `URLSession`, `NWConnection`, `import Network`).
- Zero third-party dependencies. SwiftLint/SwiftFormat run as tools, not linked.
- Never log message body or sender. `os_log` calls in the extension use `privacy: .private` or log nothing.
- App Group stores only integers, a Date, and an enum. Assert this with a test on the `Shared` keys.
- Fail open on error (`.none`).
- No `UserDefaults.standard` for anything cross-target; only the App Group suite.
- Swift 6 language mode, strict concurrency, `-warnings-as-errors`.
- Privacy manifest (`PrivacyInfo.xcprivacy`) in both targets declaring no tracking and no collected data; declare `UserDefaults` required-reason API (CA92.1).
- Privacy nutrition label in App Store Connect: **Data Not Collected**.

### Threat model

The only untrusted input is a string of text from an attacker. Treat every message body and sender as hostile.

| Threat | Why it can't happen here | Enforced by |
|---|---|---|
| Malicious text executes code | Body is only ever matched against static regexes. No `eval`, no scripting, no `WKWebView`, no `NSAttributedString` from HTML, no `URL(string:)` construction from body content. Swift is memory-safe; no `UnsafePointer` anywhere. | Lint rule banning `WKWebView`, `Unsafe`, `NSAttributedString(html`, `dataDetectorTypes` |
| Crafted text crashes or hangs the extension (DoS) | Input truncated to 1,000 chars; regexes have no nested quantifiers; 50 ms per-rule timeout test; any throw → `.none`. iOS also kills a misbehaving extension, and the message is delivered normally. | Adversarial-input test in `FilterCoreTests` |
| Text exfiltrates data | No network code, no clipboard writes, no shared containers beyond the App Group, no URL opening from the extension. | Lint rule banning `URLSession`, `Network`, `UIPasteboard`, `open(` in the extension and FilterCore |
| Text Lab renders a link the user taps | Test Lab shows body as plain `Text`, never as a link or attributed string; links are inert. | Code review checklist |
| Attacker learns the rules and evades them | Accepted. Rules are in the open-source repo; the corpus loop tightens them over time. The failure mode is a missed spam text, not a harm. | — |
| App itself becomes a data risk | It holds nothing: no message store, no contacts, no identity. Uninstall = clean slate. | App Group key test |

## 7. Quality gates (all must pass before any commit)

```
swiftformat --lint .
swiftlint --strict
swift test --package-path FilterCore
xcodebuild -scheme Quiet -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

Corpus tests are the contract: recall ≥ 95% on `spam.txt`, **zero** junk verdicts on `legit.txt`. Add a line to a corpus file → run → fix rules → repeat. That's the loop.

## 8. Path to the App Store

1. **Apple Developer Program** ($99/yr, individual is fine; approval 1–2 days). Needs a Mac with current Xcode and a physical iPhone.
2. **Bundle IDs**: `com.you.quiet` and `com.you.quiet.filter`; both with App Group `group.com.you.quiet`. Xcode automatic signing handles provisioning.
3. **Build & device test**: install, enable the filter in Settings, have a friend text you a fake "chip in $5" message and an OTP. Confirm the first lands in Junk and the second in the inbox.
4. **TestFlight** to family (internal testers need no review; external testers need a light beta review).
5. **App Store Connect listing**: name, subtitle, 3–5 screenshots at the required size (App Store Connect tells you which), description, keywords ("spam text filter, robotext, fundraising texts"), category Utilities, age 4+, support URL, **privacy policy URL** (required — a one-page GitHub Pages site saying "this app collects nothing" is enough).
6. **App Review notes** (this is where filter apps get rejected): explain exactly how to enable the filter step by step, state that all filtering is on-device with no data collection, and point them to Test Lab so they can verify behavior without sending real texts. Include 2 sample spam messages and 1 sample OTP.
7. **Guidelines to satisfy**: 2.1 (must not crash, must have real functionality — the three screens cover 4.2 "minimum functionality"), 5.1.1 (privacy policy + manifest), 5.2.1 (no third-party trademarks), 1.1 (keep copy politically neutral — "fundraising and campaign robotexts," never partisan).
8. **Submit**. Typical review 1–3 days. If rejected, the rejection cites the guideline; fix and resubmit — most first-timers get one rejection.

## 9. Milestones

| # | Deliverable | Done when |
|---|---|---|
| M1 | FilterCore + corpus | `swift test` green with ≥ 40 spam / ≥ 40 legit samples |
| M2 | Extension + minimal App | Junk lands in Junk folder on your own phone |
| M3 | Three screens polished | Family member enables it without help |
| M4 | TestFlight | Two weeks of family use, zero "I missed a real text" reports |
| M5 | App Store | Approved and live |
