# Quiet

An iOS app that filters political fundraising and campaign robotexts from unknown
senders. Everything runs on device. No accounts, no network, no analytics.

Quiet uses Apple's `IdentityLookup` message filter extension, which iOS offers
messages from senders who are not in your contacts. Quiet scores each one against
a table of rules and tells iOS to deliver it or send it to Junk. That is the whole
app.

## Why it exists

Campaign fundraising programs send a lot of texts. Apple's own spam filtering is
general-purpose; this is a stricter layer aimed at one specific kind of message.
Use both.

## How it works

Score = the sum of matched rule weights, capped per rule family. Above the
sensitivity threshold (60 Standard, 40 Aggressive) the message is junk.

Allow rules run **first** and short-circuit: one-time codes, delivery updates,
bank alerts, appointment reminders, school and utility notices, civic notices, and
anything shaped like a person typing. A missed robotext is an annoyance; a filtered
one-time code or doctor's reminder is a real harm, and the rules are tuned around
that asymmetry. A small set of narrow vetoes stops the allow rules from becoming
the evasion.

Message bodies are unicode-folded before matching — compatibility mapping,
zero-width scalars stripped, Cyrillic and Greek confusables mapped to ASCII — so
`аctblue.com` and `a c t b l u e . c o m` are caught like the plain spelling.

```
FilterCore/          Swift package. All classification logic. No dependencies.
  Sources/Rules/     One file per rule family. Rules are data, not branches.
  Tests/Corpus/      spam.txt and legit.txt, one message per line.
FilterExtension/     ILMessageFilterExtension. Glue only, ~50 lines.
App/                 Three SwiftUI screens: Home, Test Lab, Onboarding.
Shared/              App Group access. Settings and counters, nothing else.
```

## Privacy

Message text lives in memory for the duration of one filter callback and nowhere
else. It is never stored, logged, or transmitted. There is no networking code in
the repository, and a lint rule fails the build if any is added — along with rules
banning web views, pasteboard access, unsafe pointers, and logging in the filter
path. The shared container holds a sensitivity setting, one boolean, two counters,
and two dates; a test asserts that key set.

Full policy: [docs/index.html](docs/index.html)

## Working on it

```
make check    # lint + test + build. The bar for every commit.
make test     # FilterCore tests alone, ~1s
```

The corpus is the contract: **recall ≥ 95% on `spam.txt`, zero junk verdicts on
`legit.txt`** at every sensitivity. The loop is:

1. Add the message as a line in `spam.txt` or `legit.txt` (redact phone numbers).
2. `make test` — watch it fail.
3. Change rules or weights in `FilterCore/Sources/FilterCore/Rules/`.
4. `make check` — must be fully green.

Never lower the false-positive bar to make a test pass. Prefer adding an allow
rule over reducing a weight.

Test Lab in the app runs this same classifier: paste any message and see the
verdict plus every rule that matched.

## Status

Rules, corpus, and the three screens are done and tested. Device verification and
App Store submission are not. See [SPEC.md](SPEC.md) for the design and
[docs/app-review-notes.md](docs/app-review-notes.md) for what remains.
