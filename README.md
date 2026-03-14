# Split Genesis

<p align="center">
  <img src="docs/assets/icon.png" alt="Split Genesis" width="120" />
</p>

<p align="center">
  <strong>Fair splits. No signup. No cloud. Just math.</strong>
</p>

<p align="center">
  <a href="https://github.com/salahxiv/split-genesis/actions"><img src="https://github.com/salahxiv/split-genesis/workflows/CI/badge.svg" alt="CI" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS-lightgrey" alt="Platforms" />
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/offline--first-✓-success" alt="Offline First" />
  <a href="https://github.com/salahxiv/split-genesis/issues"><img src="https://img.shields.io/github/issues/salahxiv/split-genesis" alt="Open Issues" /></a>
</p>

---

Split Genesis is an **open-source expense splitting app** built with an offline-first philosophy. Track shared costs with friends, travel groups, or flatmates — privately, without giving your data to anyone.

> No account. No cloud. No vendor lock-in. Your data stays on your device.

---

## Why Split Genesis?

Most expense-splitting apps require you to create an account, trust a company's servers with your financial data, and eventually hit a paywall. Split Genesis does none of that.

| | Split Genesis | Splitwise | Tricount |
|--|:--:|:--:|:--:|
| No account required | ✅ | ❌ | ❌ |
| Fully offline | ✅ | ⚠️ | ⚠️ |
| Open source | ✅ | ❌ | ❌ |
| Self-hosted sync | ✅ | ❌ | ❌ |
| Free — no limits | ✅ | ⚠️ Freemium | ⚠️ Freemium |
| GDPR by design | ✅ | ❌ US servers | ❌ |

Split Genesis is what expense splitting should have been all along: simple math, no strings attached.

---

## Features

- ✅ **Offline-First** — works without internet, always, everywhere
- 👥 **Groups** — create multiple expense groups (trips, flatshares, events)
- 💸 **Smart Splitting** — equal, unequal, percentage-based, or by shares
- 📊 **Debt Overview** — see who owes what at a glance
- 🔄 **Settle Up** — mark debts as paid with one tap
- 🌍 **Multi-Currency** — support for different currencies per expense
- 🔒 **Privacy by Design** — no tracking, no ads, no analytics
- ☁️ **Optional Cloud Sync** — bring your own Supabase instance
- 📤 **Export** — export summaries as CSV or PDF
- 🌙 **Dark Mode** — because of course

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/home.png" alt="Home — all your groups at a glance" width="220" />
  &nbsp;&nbsp;
  <img src="docs/screenshots/group.png" alt="Group detail — who owes what" width="220" />
  &nbsp;&nbsp;
  <img src="docs/screenshots/add.png" alt="Add expense — fast and flexible" width="220" />
</p>

<p align="center">
  <em>Left: Groups overview &nbsp;·&nbsp; Center: Debt overview &nbsp;·&nbsp; Right: Add expense</em>
</p>

> 📸 More screenshots in [docs/screenshots/](docs/screenshots/)

---

## Installation

### iOS / Android / macOS (App Store / Play Store)
*Coming soon — TestFlight beta available. [Join the beta →](https://github.com/salahxiv/split-genesis/issues)*

### Build from Source

**Requirements:**
- Flutter 3.19+
- iOS 16+ / Android 8+ / macOS 13+
- Dart 3.3+

```bash
git clone https://github.com/salahxiv/split-genesis.git
cd split-genesis
flutter pub get
flutter run
```

No additional setup required for local-only mode. It just works.

---

## Self-Hosted Cloud Sync (Optional)

Want to sync across devices without trusting a third party? Host your own backend in minutes.

### Step 1: Set up Supabase

```bash
# Option A: Supabase Cloud (free tier — supabase.com)
# Create a project and copy your URL + anon key

# Option B: Self-hosted (recommended for privacy)
git clone https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
# Edit .env with your secrets
docker compose up -d
```

### Step 2: Run the Migration

```bash
supabase db push
# Or manually run: supabase/migrations/001_initial_schema.sql
```

### Step 3: Configure the App

In Split Genesis → Settings → Cloud Sync:
1. Enter your Supabase URL
2. Enter your `anon` key
3. Tap "Connect" — done ✓

Your data syncs only to **your** instance. We never see it.

---

## Privacy

Split Genesis is privacy-first by design:

- **No account required** — ever
- **All data stays local** by default
- **No tracking, no analytics, no ads**
- **Open source** — verify the code yourself
- **GDPR compliant by design** — no personal data leaves your device

→ [Full Privacy Policy](PRIVACY_POLICY.md)

---

## Contributing

Contributions welcome! Here's how:

```bash
git clone https://github.com/YOUR_USERNAME/split-genesis.git
cd split-genesis
git checkout -b feature/your-feature-name
flutter test
```

**Guidelines:**
- Follow existing code style (run `flutter analyze` before submitting)
- Add tests for new features
- Open an issue first for major features
- Update docs if you change behavior

→ [Open Issues](https://github.com/salahxiv/split-genesis/issues)  
→ [Good First Issues](https://github.com/salahxiv/split-genesis/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

---

## Roadmap

- [x] v1.0 — Core splitting, offline-first, local storage
- [ ] v1.1 — Optional Supabase sync
- [ ] v1.2 — Recurring expenses
- [ ] v1.3 — SEPA QR code for debt settlement
- [ ] v2.0 — Widgets, Shortcuts integration, Apple Watch

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Free to use, modify, and distribute. Attribution appreciated but not required.

---

<p align="center">
  Built with ❤️ and Flutter &nbsp;·&nbsp; No VC funding &nbsp;·&nbsp; No data harvesting &nbsp;·&nbsp; <a href="https://github.com/salahxiv/split-genesis/stargazers">⭐ Star if useful</a>
</p>
