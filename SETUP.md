# SETUP — First hour on the new Mac

Do these in order. Each step ends with a check so you know it worked before moving on.

## 1. Apple side (start these first; they have wait times)
- [ ] Sign into the Mac with the Apple ID you'll publish under.
- [ ] Enroll at developer.apple.com/programs ($99/yr, Individual). Approval usually 1–2 days.
- [ ] App Store: install **Xcode**. Open it once, accept the license, and when prompted install the **iOS** platform (several GB — let it finish).
- [ ] Terminal: `xcode-select --install` then `sudo xcodebuild -license accept`.
  - Check: `xcodebuild -version` prints an Xcode version.

## 2. Tooling
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git xcodegen swiftlint swiftformat
```
- Check: `xcodegen --version`, `swiftlint version`, `swiftformat --version` all print.
- Configure git: `git config --global user.name "Your Name"` and `git config --global user.email you@example.com`.

## 3. Claude Code
- Download the Claude desktop app from claude.ai/download, sign in with your existing Claude account, open the **Code** tab.
- Or CLI: `brew install claude` then `claude` to authenticate.
- Optional Xcode bridge: `claude mcp add --transport stdio xcode -- xcrun mcpbridge`
- Check: in a scratch folder, run `claude` and ask it to `xcodebuild -version`. It should succeed.

## 4. Project
```
mkdir -p ~/Projects/quiet && cd ~/Projects/quiet
git init
# copy SPEC.md, CLAUDE.md, SETUP.md here
```

## 5. First prompt to Claude Code
> Read SPEC.md and CLAUDE.md. Create: project.yml for XcodeGen (App + FilterExtension targets, App Group, privacy manifests), the FilterCore Swift package with the rules engine and Verdict types, a Makefile with the commands in CLAUDE.md, `.swiftlint.yml` with the custom rules from SPEC §6 (banned APIs), `.swiftformat`, and a corpus with 20 spam and 20 legit samples. Then run `make check` and fix until green. Don't build UI yet.

- Check: `make check` green. Commit.

## 6. Device
- [ ] Plug in iPhone, tap Trust, enable Developer Mode (Settings → Privacy & Security → Developer Mode).
- [ ] Xcode → Settings → Accounts → add Apple ID. Select your team on both targets under Signing & Capabilities (automatic signing).
- [ ] Prompt: *"Build and run the Quiet scheme on my connected iPhone."* Then on the phone: Settings → Apps → Messages → Unknown & Spam → Text Message Filter → Quiet.
- [ ] Have someone text you "Chip in $5 before midnight! https://bit.ly/xyz Reply STOP to end" and separately "Your code is 482913". First goes to Junk, second to inbox.

You're now at Milestone M2. Everything after this is the corpus loop and the three screens.
