# App Review notes

Paste the section below into **App Review Information → Notes** in App Store Connect.
SPEC §8 step 6: message-filter apps are most often rejected because the reviewer cannot
work out how to enable the extension, so the enable steps come first.

---

## Notes for the reviewer

Quiet is an SMS filter that reduces political fundraising and campaign robotexts. It uses
Apple's IdentityLookup message filter extension. All filtering happens on device. The app
contains no networking code, collects no data, and has no accounts or analytics.

**Enabling the filter (required before the extension does anything):**

1. Install Quiet.
2. Open **Settings → Apps → Messages → Unknown & Spam**.
3. Tap **Text Message Filter** and choose **Quiet**.

The filter only receives messages from senders who are not in Contacts, and iOS never routes
messages from known contacts to it. On some carriers and regions the Text Message Filter option
is not offered by iOS; the app's onboarding screen explains this.

**Verifying behaviour without sending real texts:**

Open the app and tap **Test Lab**. Paste any message to see the verdict and which rules matched.
Test Lab runs the exact same classifier the extension uses. Three examples are built into the
screen, and the following can be pasted directly.

Two messages Quiet filters as junk:

> Chip in $5 before midnight! Our 3X MATCH expires tonight. secure.actblue.com/donate/x Reply STOP to end

> The deadline is TONIGHT and we are 212 gifts short. Can you rush $25? bit.ly/2xyzab Reply STOP 2 end

One message Quiet always delivers:

> Your Chase verification code is 482913. Do not share it with anyone.

One-time codes, delivery updates, appointment reminders, and bank alerts are matched by
explicit allow rules that run before any spam scoring, so they are never filtered.

**Privacy:** message text is held in memory only for the duration of a single filter callback
and is never stored, logged, or transmitted. The app's shared container holds only a sensitivity
setting, a boolean toggle, two counters, and two dates. Privacy manifests in both targets declare
no tracking and no collected data. Privacy policy: <https://mattlince3000.github.io/quiet/>

**Content neutrality (guideline 1.1):** Quiet is not partisan. The rules target fundraising and
campaign solicitation patterns generally, and the corpus used to tune them contains messages from
across the political spectrum. No party, candidate, or vendor is named anywhere in the app's
interface, name, or icon.

---

## Pre-submission checklist

- [ ] Replace `com.you.quiet` / `com.you.quiet.filter` with real bundle IDs in `project.yml`
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml`, then `make gen`
- [ ] Update the App Group identifier in `project.yml` and `Shared/AppGroupKeys.swift` to match
- [x] Publish `docs/` to GitHub Pages — live at <https://mattlince3000.github.io/quiet/>
- [ ] Put that URL in the App Store Connect listing's Privacy Policy field
- [ ] Confirm the privacy nutrition label is set to **Data Not Collected**
- [x] Add an app icon
- [x] Screenshots at 1320×2868 (6.9") in `docs/screenshots/` — note the Home counts are illustrative
- [x] Dedicated support email: getquiettexts@gmail.com
- [ ] Category Utilities, age rating 4+, support URL set
- [ ] Device-test once: enable the filter, have someone send a fundraising text and an OTP
