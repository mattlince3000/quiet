# CLAUDE.md — Quiet (robotext filter)

Read SPEC.md first. It is the source of truth; if code and SPEC disagree, fix one and say which.

## Hard rules
- Zero network code. Zero third-party dependencies. Zero storage of message content. If a task seems to need any of these, stop and ask.
- All classification logic lives in `FilterCore`. The extension is glue only (target ≤ 60 lines).
- Rules are data (`[Rule]`), not `if` chains. Add or tune a rule by editing the array and adding corpus lines.
- Fail open: any error in the extension returns `.none`.
- Never log sender or body. Never write anything to the App Group except the keys in `Shared/AppGroupKeys.swift`.
- Swift 6, strict concurrency, warnings are errors. No `@unchecked Sendable`, no `try!`, no force-unwraps outside tests.
- No new screens, settings, or features beyond the three screens in SPEC §3 without asking.

## Commands
```
make gen      # xcodegen generate
make lint     # swiftformat --lint . && swiftlint --strict
make test     # swift test --package-path FilterCore
make build    # xcodebuild -scheme Quiet -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
make check    # lint + test + build
```

## The loop
1. Add the new case as a line in `FilterCore/Tests/Corpus/spam.txt` or `legit.txt` (redact phone numbers, keep everything else verbatim).
2. `make test` — watch it fail.
3. Change rules/weights in `FilterCore/Sources/FilterCore/Rules/`.
4. `make check` — must be fully green: lint clean, recall ≥ 0.95 on spam, 0 false positives on legit, build succeeds.
5. Commit with a one-line message naming the rule or sample added.

Never lower the false-positive bar to make a test pass. A missed spam text is annoying; a filtered OTP or doctor's text is a real harm. Prefer allow-rule additions over weight reductions.

## Definition of done for any task
- `make check` green.
- No file grew past 200 lines; split by rule family if it does.
- Diff contains only what the task asked for.
- If you touched the extension or `Shared/`, re-read SPEC §6 and confirm nothing new is persisted or transmitted.
