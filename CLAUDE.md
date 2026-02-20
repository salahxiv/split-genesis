# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Split Genesis is a Flutter mobile expense-splitting app (iOS/Android). It uses an offline-first architecture with SQLite as the local source of truth and Supabase for cloud sync and real-time collaboration.

## Common Commands

| Task | Command |
|---|---|
| Get dependencies | `flutter pub get` |
| Run the app | `flutter run` |
| Run tests | `flutter test` |
| Run a single test | `flutter test test/widget_test.dart` |
| Analyze/lint | `flutter analyze` |
| Build APK | `flutter build apk` |
| Build iOS | `flutter build ios` |

Linting extends `package:flutter_lints/flutter.yaml` (configured in `analysis_options.yaml`).

## Architecture

### Structure

Single Flutter app (not a monorepo). All application code lives under `lib/` with a feature-based organization:

- `lib/core/` — Shared infrastructure (database, sync, auth, theme, navigation, notifications)
- `lib/features/` — Feature modules: `groups/`, `members/`, `expenses/`, `balances/`, `settlements/`, `activity/`

Each feature follows: **models → repositories → providers → screens** (sometimes `widgets/` or `services/`).

### State Management

**Riverpod** (`flutter_riverpod`) with `AsyncNotifierProvider` and `FutureProvider.family`. Data flow:

`Screen (ConsumerWidget)` → watches `Provider` → `AsyncNotifier` calls `Repository` → `Repository` queries `DatabaseHelper`

### Data Layer

- **SQLite** (`sqflite`) is the local source of truth — schema version 7 with 7 tables
- **Supabase** for cloud backend (Postgres + Realtime + anonymous auth)
- **Repository pattern** — each feature has a `*Repository` wrapping `DatabaseHelper`; no direct DB access from providers
- **UUIDs** (v4 strings) for all entity IDs
- **Timestamps** stored as ISO 8601 strings in SQLite

### Sync Architecture

- Offline-first: UI reads from SQLite, sync happens in background
- All tables have `sync_status` column (`'pending'` or `'synced'`)
- `SyncService` handles push (local→cloud) and pull (cloud→local)
- Supabase Realtime subscriptions on all tables, debounced 500ms per group
- On connectivity restore, `pushPendingChanges()` flushes all pending rows
- Group sharing via 8-char alphanumeric codes + deep links (`splitgenesis://join/CODE`)

### Key Patterns

- **Singleton services** use `static final instance = Cls._()` pattern: `DatabaseHelper`, `SyncService`, `AuthService`, `NotificationService`, `DeepLinkService`, `ActivityLogger`
- **Performance logging** via `debugPrint('[PERF] ...')` with `Stopwatch`
- **Navigation** uses imperative `Navigator.push` with `slideRoute()` helper (no named routes)
- **Theme** is Material 3, iOS-inspired palette, with light + dark modes in `core/theme/app_theme.dart`

### Expense System

- Split types: Equal, Exact, Percent, Shares
- Multi-payer support (`expense_payers` table, added in schema v7)
- Add expense UI is a 3-step `PageView` bottom sheet wizard (Essentials → Split → Review)
- Debt simplification uses a greedy algorithm in `features/balances/services/debt_calculator.dart`

### Cloud Config

Supabase instance is self-hosted at `api.devsalah.com` (config in `core/config/supabase_config.dart`). Supabase SQL schema with RLS policies is in `supabase/migrations/001_initial_schema.sql`.

## Reference Documents

- `architecture_and_models.md` — Design doc with data models and algorithm details
- `market_analysis.md` — UX research and competitive analysis
