[English](README.md) | [简体中文](README.zh-CN.md)

# ShouldRenew (续吗)

> Decide whether to renew before the next charge — and if you're cancelling, follow the channel's steps all the way through.

Implemented from `xuma-prd-for-ai.md` (v1.1, an implementation-focused PRD that supersedes the original renewornot-requirement.docx). Local-first — no network, no accounts.

## Feature Scope (the decision loop only)

- **Add**: a catalog of 26 mainstream AI plans (the PRD's original 10 plus: ChatGPT Pro, Claude Max, SuperGrok, Poe, Doubao, ERNIE Bot, Zhipu Qingyan, Windsurf, JetBrains AI, Jimeng, Runway, Kling, Suno, ElevenLabs, Notion AI, Metaso; prices are editable placeholders), plus name/price/currency (usd|cny)/cycle (month|year)/channel (apple|wechat|alipay|website)/next charge date/purpose; the free tier is capped at 10 entries (cancelled ones don't count), and past the cap a disabled paywall panel is shown (no StoreKit)
- **Today**: the decision card shows only the nearest charge within 14 days (renew-or-not question / price line / "charged in N days" / "Renew · Cancel first"); with no card, an empty state — "Nothing to decide right now"; "Expiring soon" lists at most 3 items; overlapping purposes trigger the hint "{A} and {B} both lean {X} — keep just one?"
- **Actions**: Renew → decidedRenew (automatically rolls the cycle and returns to active once the charge date passes), undoable right after (Today toast "Undo" / detail page "Back to active" / list swipe "Back to active"); Cancel first → channel guide (verbatim 4-step copy for apple/wechat/alipay/website) → "I've cancelled" or "Renew after all"; Sleep on it for 1 day → snoozed, returns the next day (also undoable)
- **List**: active → renewal marked → cancelled (collapsed by default); tap to edit, swipe to cancel/delete
- **Reminders**: 7/3/1 days before nextChargeAt at 09:30, with the copy `{name} {n} 天后扣 {price}，续吗？` ("{name} will be charged {price} in {n} days — renew?"), identifier `renew.{id}.{offset}`; tapping opens Today (deep link `shouldrenew://today`); the full schedule is re-planned on launch and after any change
- **Settings**: notification toggle (requests permission when turned on; if not authorized, guides the user to system settings), default currency for new subscriptions, About (with version number)

Explicitly out of scope (PRD §0/§11): a monthly-report tab, pie charts/spending categories/annual forecasts, an amount hero, multi-currency conversion, bank/email sync, a generic subscription catalog, usage APIs.

## Project Structure

```
ShouldRenew.xcodeproj          iOS 17+ SwiftUI (com.shouldrenew.app, display name 续吗)
ShouldRenew/
  Assets.xcassets              Final icon (teal background, ivory 续吗 lettering)
  Support/Copy.swift           Copy library (§10 + per-screen strings)
  Support/Theme.swift          Visual tokens: teal/ivory/page/soft/ink + primary/secondary capsule buttons
  Support/AppSettings.swift    Notification toggle, default currency for new subscriptions
  Services/                    Notification scheduling (deep link), UNUserNotificationCenterDelegate
  Views/                       Today (decision card/empty state/expiring soon/overlap hints),
                               decision card + detail, cancel guide, list (three sections),
                               add (catalog + form), settings
ShouldRenewCore/               SwiftPM package (pure logic, runnable with swift test)
  Models.swift                 §3 data model (Subscription/CatalogItem + enums)
  Catalog.swift                10-item catalog (ids match the PRD table one for one)
  CancelGuide.swift            Four-channel, four-step guides (§5.3 verbatim copy)
  ReminderPlanner.swift        §6 reminder planning (skips trigger times already in the past)
  SubscriptionStore.swift      JSON persistence + legacy data migration + cap/overlap/cycle rollover
  Tests/                       14 unit tests (including the logic behind acceptance A2/A3/A5/A6)
ShouldRenewUITests/            UI regression: A1 add, A7 three tabs with no monthly-report tab
design/xuma-assets/            Final cut assets and Today-page design mockups
```

## Development

```bash
cd ShouldRenewCore && swift test          # core logic
xcodebuild -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild test -project ShouldRenew.xcodeproj -scheme ShouldRenew \
  -destination 'platform=iOS Simulator,name=iPhone 17'   # UI regression
```

Data is stored only on-device in `Documents/subscriptions.json`; legacy (v0.1) data migrates automatically (currency/cycle/channel/purpose/status mapped field by field; usage and exchange-rate fields are dropped per the new requirements).

## Story & Retrospective

- [3 days, 13 commits: a full vibe-coding retrospective (with 6 pitfalls to avoid)](story/vibe-coding-story.md) (in Chinese)

## App Store Configuration Status

- `PrivacyInfo.xcprivacy`: no tracking, no data collected, UserDefaults (CA92.1)
- `ITSAppUsesNonExemptEncryption = NO` (no network, no custom encryption)
- Version 1.0.0 (injected via MARKETING_VERSION, shown in Settings → About); display name 续吗, iPhone only
- Free cap of 10 entries; the unlock/IAP entry has been removed per App Review requirements
- Still to complete on the App Store Connect side: developer account/signing team, privacy policy URL, support URL, screenshots (6.9"), ICP filing (mainland China), trademark clearance
