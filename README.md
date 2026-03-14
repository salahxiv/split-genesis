# Split Genesis

> **Fair splits. No signup. No cloud. Just math.**

Split Genesis is an open-source expense splitting app built with an offline-first philosophy. Track shared costs with friends, travel groups, or flatmates — privately, without giving your data to anyone.

---

## What is Split Genesis?

Split Genesis helps you answer the eternal question: *"Who owes whom, and how much?"*

Unlike other expense-splitting apps, Split Genesis:
- Requires **no account or signup**
- Stores all data **locally on your device**
- Offers **optional self-hosted sync** (your Supabase, your data)
- Is completely **free and open source**

---

## Features

- ✅ **Offline-First** — works without internet, always
- 👥 **Groups** — create multiple expense groups (trips, flatshares, events)
- 💸 **Smart Splitting** — equal, unequal, percentage-based, or by shares
- 📊 **Debt Overview** — see who owes what at a glance
- 🔄 **Settle Up** — mark debts as paid
- 🌍 **Multi-Currency** — support for different currencies per expense
- 🔒 **Privacy by Design** — no tracking, no ads, no analytics
- ☁️ **Optional Cloud Sync** — bring your own Supabase instance
- 📤 **Export** — export summaries as CSV or PDF
- 🌙 **Dark Mode** — because of course

---

## Screenshots

> 📸 *Screenshots coming soon*

| Home | Group Detail | Add Expense |
|------|-------------|-------------|
| ![Home](docs/screenshots/home.png) | ![Group](docs/screenshots/group.png) | ![Add](docs/screenshots/add.png) |

---

## Installation

### iOS / macOS (App Store)
*Coming soon — TestFlight beta available*

### Build from Source

**Requirements:**
- Xcode 15+
- iOS 16+ / macOS 13+
- Swift 5.9+

```bash
git clone https://github.com/salahxiv/split-genesis.git
cd split-genesis
open SplitGenesis.xcodeproj
```

Build and run in Xcode. No additional setup required for local-only mode.

---

## Self-Hosted Cloud Sync (Optional)

Want to sync across devices? Host your own backend in minutes.

### Step 1: Set up Supabase

```bash
# Option A: Supabase Cloud (free tier)
# Create a project at supabase.com

# Option B: Self-hosted (recommended for privacy)
git clone https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
# Edit .env with your secrets
docker compose up -d
```

### Step 2: Run the Migration

```bash
# In your Supabase dashboard or via CLI:
supabase db push
# Or manually run: supabase/migrations/001_initial_schema.sql
```

### Step 3: Configure the App

In Split Genesis → Settings → Cloud Sync:
1. Enter your Supabase URL (e.g. `https://your-project.supabase.co`)
2. Enter your Supabase `anon` key
3. Tap "Connect" — done ✓

Your data syncs only to **your** instance. We never see it.

---

## Privacy

Split Genesis is privacy-first by design:

- **No account required** — ever
- **All data stays local** by default
- **No tracking, no analytics, no ads**
- **Open source** — verify the code yourself

→ [Full Privacy Policy](PRIVACY_POLICY.md)

---

## Contributing

Contributions are welcome! Here's how to get started:

```bash
# Fork the repo, then:
git clone https://github.com/YOUR_USERNAME/split-genesis.git
cd split-genesis
git checkout -b feature/your-feature-name
```

**Guidelines:**
- Follow Swift best practices and existing code style
- Add tests for new features where possible
- Update docs if you change behavior
- Open an issue first for major features

→ [Open Issues](https://github.com/salahxiv/split-genesis/issues)
→ [Contributing Guide](CONTRIBUTING.md) *(coming soon)*

---

## Roadmap

- [ ] v1.0 — Core splitting, offline-first, local storage
- [ ] v1.1 — Optional Supabase sync
- [ ] v1.2 — Recurring expenses
- [ ] v2.0 — Widgets, Shortcuts integration

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Free to use, modify, and distribute. Attribution appreciated but not required.

---

<p align="center">
  Built with ❤️ and Swift · No VC funding · No data harvesting
</p>
