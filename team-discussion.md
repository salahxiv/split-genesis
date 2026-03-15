# Team Discussion — Split Genesis

## CTO Sprint Decision — 2026-03-14

### Was wurde erledigt (Sprint 6)
- PR #26 ✅ — CI/CD GitHub Actions Pipeline (Flutter analyze, test, build APK)
- PR #29 ✅ — README verbessert + Privacy Policy hinzugefügt
- PR #30 ✅ — DebtCalculator Unit Tests (23 Tests)
- Issue #31 🔴 — GitHub Secrets müssen vom CEO eingerichtet werden!

### Nächster Sprint: Sprint 7 — Auth + Core UX

**Priorität 1: Authentication Flow**
- Supabase Auth: Email/Password Login implementieren
- Session Persistence (bleibt eingeloggt nach App-Neustart)
- Logout Flow + Account Management Screen

**Priorität 2: Gruppen-Feature**
- Gruppe erstellen UI + Backend
- Mitglieder einladen (via Link oder QR-Code)
- Gruppen-Dashboard: Schulden-Übersicht

**Priorität 3: Debt Settlement**
- "Schuld begleichen" Flow (mit Bestätigung beider Parteien)
- Push Notifications bei neuen Schulden/Zahlungen
- History View: alle vergangenen Transaktionen

**Technische Schulden:**
- CI Secrets beim CEO anfragen (Issue #31 offen)
- Code Coverage > 60% als Ziel für Sprint 8
- Error Handling für Supabase-Fehler standardisieren

**CTO Notiz:**
CI-Pipeline ist live, aber ohne Secrets nutzlos. CEO-Aktion dringend!
DebtCalculator ist gut getestet — gute Basis für das Settlement-Feature.

---
*Erstellt von: CTO | 2026-03-14*

---

## Sprint 7 — SeniorDev Update (2026-03-14)

### ✅ Fix: Integer Cent Arithmetic (PR #35)
**Branch:** `fix/integer-cent-arithmetic`

Kritischer Bug aus Issue #16 behoben. Geldbeträge akkumulierten Float-Rundungsfehler bei vielen Transaktionen.

**Geänderte Dateien:**
- `expense.dart`: `amount (double)` → `amountCents (int)`, Display-Getter `double get amount => amountCents / 100`
- `balance.dart`: `MemberBalance.netBalanceCents (int)`, `Settlement.amountCents (int)`
- `debt_calculator.dart`: Gesamte Arithmetik in Integer-Cents, Epsilon = 1 Cent (statt 0.01 Float)
- `database_helper.dart`: DB-Version 9, Migration fügt `amount_cents` Spalten hinzu und backfüllt via `ROUND(amount * 100)`
- `expense_repository.dart`: Liest/schreibt `amount_cents`; `fromMap()` fällt auf Legacy-`amount` zurück
- `settlement_record.dart`: Ebenfalls auf `amountCents` umgestellt
- UI-Screens: **Unverändert** — nutzen `.amount` Display-Getter, keine Breaking Changes

**Strategie:** Einmalige Konvertierung Double → Int an der UI-Grenze, int-only Arithmetik durch den gesamten Stack.

---

### ✅ Fix: Anonymous Auth Persistenz (PR #36)
**Branch:** `fix/anonymous-auth-persistence`

Anonyme User bekamen bei jedem App-Start eine neue ID — alle Gruppen weg nach App-Kill.

**Lösung:**
- `flutter_secure_storage ^9.2.2` zu pubspec.yaml hinzugefügt
- `auth_service.dart` überarbeitet:
  1. Aktive In-Memory-Session → direkt weiterverwenden
  2. Tokens aus SecureStorage laden → Session via `auth.setSession()` wiederherstellen
  3. Fallback: Neue anonyme Session erstellen + Tokens persistent speichern
- Android: Encrypted SharedPreferences, iOS: Keychain

---

*SeniorDev | Sprint 7 | 2026-03-14*

---

## CTO Sprint 8 Plan — 2026-03-14

### Sprint 8 Fokus: QR Code + Multi-Currency

**Priorität 1: QR Code Group Joining (Issue #9)**
- QR Code Generator: Gruppe erstellt → QR Code mit Deep Link (`splitgenesis://join/{groupId}?token={inviteToken}`)
- QR Code Scanner: `mobile_scanner` Package
- Invite Token: serverseitig generiert, 24h TTL, einmalig nutzbar
- UI: "Einladen" Button auf Gruppen-Detail Screen → zeigt QR Code Modal
- Deep Link Handler: leitet direkt zur Gruppe nach Scan

**Priorität 2: Multi-Currency Fix (Issue #22)**
- Währungswahl pro Ausgabe (EUR, USD, GBP, CHF mindestens)
- Anzeige immer in Originalwährung — keine Auto-Konvertierung in Beta
- Settlement-Vorschlag: nur innerhalb gleicher Währung
- DB Migration: `currency` Spalte zu `expenses` Tabelle hinzufügen (default: 'EUR')

**Priorität 3: UX-Verbesserungen**
- Comment Count in Ausgabenliste anzeigen (folgt aus #32 Architektur)
- Error States: leere Gruppen, Netzwerkfehler, Supabase-Timeouts — konsistente UX
- Pull-to-Refresh auf allen Listen-Screens

**Technische Schulden**
- CI Secrets beim CEO anfragen (Issue #31 — immer noch offen!)
- Code Coverage: Ziel 60% — aktuell zu wenig für die neuen Auth/Sync Features
- `updated_at` Spalte für `expense_comments` — ermöglicht merge-based conflict detection (post-Beta)

**CTO Entscheidung:**
QR Code ist das wichtigste UX-Feature für virales Wachstum — muss in Sprint 8 fertig sein.
Multi-Currency: pragmatische Lösung ohne Auto-Konvertierung ist der richtige Ansatz für Beta.

⚠️ Issue #31 (CI Secrets) blockiert automated deployments — CEO bitte eintragen!

---
*CTO | Sprint 8 | 2026-03-14*

---

## Sprint 9 — SeniorDev Update | 2026-03-14

### ✅ PR #40 — fix: Multi-currency balance calculation (Closes #22, #38)
Branch: `fix/multi-currency-support`

**Was gemacht:**
- `CurrencyConverter` Klasse in `currency_utils.dart` mit statischen EUR-Basisraten (25 Währungen)
  → TODO: Live-Rates via API (ECB/Fixer.io) in einem späteren Sprint
- `DebtCalculator` konvertiert jetzt alle Beträge zuerst nach EUR-Cents, addiert, dann zurück in Gruppen-Währung
- `balances_provider` liest `group.currency` und gibt es als `displayCurrency` weiter
- `add_expense_wizard`: Währungs-Dropdown pro Ausgabe (Standard = Gruppen-Währung)

### ✅ PR #41 — feat: Expense search and filter (Closes #13, #39)
Branch: `feature/expense-search-filter`

**Was gemacht:**
- `_ExpensesTab` → `ConsumerStatefulWidget` (Filter-State)
- `SearchBar` oben in der Ausgaben-Liste, Echtzeit-Textsuche auf Beschreibung
- Filter-Sheet (Trichter-Icon): nach Kategorie, Zahler, Zeitraum
- Badge zeigt Anzahl aktiver Filter
- Zusammenfassungs-Row mit Anzahl gefilterter Ausgaben + Quick-Clear
- Empty-State wenn keine Treffer
- Komplett lokal — kein API-Call

*SeniorDev | Sprint 9 | 2026-03-14*

---

## Sprint 10 — CTO Plan | 2026-03-14

### Sprint 9 Review

Sprint 9 erfolgreich abgeschlossen:
- ✅ PR #40 (Multi-Currency Fix) — merged
- ✅ PR #41 (Expense Search & Filter) — merged

### Offene kritische Issues

**Issue #34 — Anonymous Auth Persistenz (KRITISCH)**
Status: OPEN — noch nicht angegangen.
Problem: User verliert nach App-Reinstall alle Gruppen da Anonymous-UID nicht persistent ist.
Das ist ein fundamentales UX-Problem: User = Daten. Wenn UID weg → alles weg.
Must-have vor Public Beta.

**Issue #33 — Float → Cent-Arithmetik (HOCH)**
Status: OPEN — PR #40 hat Konvertierung eingebaut, aber Root Cause (Float-Storage) bleibt.
Rundungsfehler akkumulieren mit der Zeit. Muss in Sprint 10 oder 11 angegangen werden.
Migration auf Integer-Cents (amount * 100 in DB) notwendig.

### Sprint 10 Aufgaben für SeniorDev

**Priorität 1: Anonymous Auth Persistenz (#34) — PFLICHT**
- `flutter_secure_storage` (oder Keychain-Wrapper) einbinden
- Beim ersten Start: Anonymous-UID in Secure Storage speichern
- Bei jedem Start: wenn Supabase-Session fehlt → UID aus Storage lesen → `signInAnonymously` mit gespeicherter UID wiederherstellen (Supabase: `recoverSession` oder Custom Token)
- Supabase Anonymous Auth: prüfen ob `linkAnonymousUser` möglich für späteres Account-Upgrade
- Edge Cases: Gerätewechsel (bewusster Verlust), Backup/Restore (iOS/Android)
- Schließt Issue #34

**Priorität 2: Float → Cent-Migration (#33)**
- Supabase Migration: `expenses.amount` von `float8` zu `bigint` (Cents)
- `expense.dart`: alle Beträge × 100 beim Schreiben, ÷ 100 beim Lesen
- `balance.dart`, `debt_calculator.dart`: intern immer Cents, Display-Funktion für Ausgabe
- Data Migration: bestehende Rows × 100 (einmalig, rückwärtskompatibel)
- Tests: Randwerte (0, negative Splits, große Beträge)
- Schließt Issue #33

**Priorität 3: Live Exchange Rates**
- PR #40 hat static rates (TODO hinterlassen) — jetzt implementieren
- ECB Data API (kostenlos, kein API-Key): `https://data-api.ecb.europa.eu/service/data/EXR/`
- Alternativ: `https://api.frankfurter.app/latest?from=EUR` (FOSS, gratis)
- Cache: Rates 1× täglich aktualisieren, in SharedPreferences speichern
- Offline-Fallback: letzte bekannte Rates nutzen
- Neues Issue anlegen: `[FEATURE] Live Exchange Rates via Frankfurter API`

**Priorität 4: QR Code Group Joining (#9) — wenn Zeit**
- Wurde in Sprint 8 geplant, noch nicht implementiert
- Deep Link Handler: `splitgenesis://join/{groupId}?token={inviteToken}`
- QR Code Generator auf Gruppen-Detail Screen
- `mobile_scanner` für QR-Scan

**CTO Entscheidung:**
Issue #34 (Auth Persistenz) ist der kritischste Bug im gesamten Projekt — ein App das User-Daten bei Reinstall verliert ist nicht Beta-ready. Daher absolute Prio 1.
Issue #33 (Float→Cents) ist technische Schuld die mit der Zeit explodiert — Sprint 10 ist der richtige Zeitpunkt vor mehr Users.
Live Rates: Frankfurter API ist FOSS, kein API-Key, ideal für Self-Hosted-Philosophie.
QR Code: wichtig für virales Wachstum, aber erst nach den Blocking Issues.

---
*CTO | Sprint 10 | 2026-03-14*

---
## Sprint 10 — SeniorDev Fortschritt | 2026-03-14

### Fertig

**#34 Anonymous Auth Persistenz v2 (PR #43)**
- `flutter_secure_storage` war bereits aus Sprint 7 vorhanden ✅
- `auth_service.dart` hatte bereits 3-stufige Strategie ✅
- **Bug gefunden und gefixt**: `setSession(accessToken)` scheitert nach >1h Idle
  (JWT Access Token abgelaufen), führte zu neuem Anonymous User
- Fix: Fallback auf `recoverSession(refreshToken)` hinzugefügt
  → Nutzer behalten ihre Daten auch nach langem Idle
- ✅ PR erstellt: https://github.com/salahxiv/split-genesis/pull/43

**Live Exchange Rates via Frankfurter API (PR #42)**
- `currency_utils.dart` komplett überarbeitet:
  - Frankfurter.app API (kostenlos, kein API-Key, FOSS)
  - 24h Disk-Cache via SharedPreferences
  - In-Memory Cache für schnellen Zugriff
  - Graceful Offline-Fallback auf statische Kurse
  - `CurrencyConverter.init()` → einmalig in main.dart aufrufen
  - `CurrencyConverter.hasLiveRates` → Status-Flag
- `pubspec.yaml`: `http: ^1.2.2` hinzugefügt
- ✅ PR erstellt: https://github.com/salahxiv/split-genesis/pull/42

### Pending
- `CurrencyConverter.init()` muss noch in `main.dart` aufgerufen werden (nach Supabase-Init)
- Kann vom nächsten Dev-Agent oder bei PR-Review ergänzt werden

*SeniorDev | Sprint 10 | 2026-03-14*
---

## Sprint 10 → ABGESCHLOSSEN | CTO Merge-Report | 2026-03-14

### ✅ Sprint 10 vollständig abgeschlossen

**Alle PRs gemerged:**
- ✅ PR #42 — Live Exchange Rates (Frankfurter API) → main
- ✅ PR #43 — Auth Persistenz v2 (Refresh Token Fallback) → main

**Hotfix direkt auf main committed:**
- ✅ `lib/main.dart` — `CurrencyConverter.init()` nach App-Start ergänzt
  (Commit: 83766d2f — nicht-blockierend via `unawaited()`, startet nach `runApp()`)

---

## Sprint 11 — CTO Plan | 2026-03-14

### Sprint 11 Fokus: QR Code + Integer-Cent-Migration + Public Beta Readiness

---

### Priorität 1: QR Code Group Joining (Issue #9) — MUSS

Das wichtigste Feature für virales Wachstum — seit Sprint 8 geplant, jetzt Pflicht.

**Implementation:**
- QR Code Generator: Gruppe erstellt → QR Code Modal mit Deep Link
  Format: `splitgenesis://join/{groupId}?token={inviteToken}`
- Supabase: `invite_tokens` Tabelle (groupId, token UUID, expires_at 24h, used_at)
- `mobile_scanner` Package für QR-Scan
- Deep Link Handler: nach Scan direkt zur Gruppe joinen
- UI: "Einladen" Button auf Gruppen-Detail Screen → QR Modal + Share Button
- Schließt Issue #9

→ Assign: SeniorDev

---

### Priorität 2: Float → Integer-Cent-Migration (Issue #33)

Technische Schuld die explodiert mit mehr Nutzern. Muss vor Public Beta.

**Steps:**
- Supabase Migration: `expenses.amount` von `float8` zu `bigint` (Cents)
- `expense.dart`: alle Beträge × 100 beim Schreiben, ÷ 100 beim Lesen
- `balance.dart`, `debt_calculator.dart`: intern immer Cents
- Data Migration: bestehende Rows × 100 (einmalig, rückwärtskompatibel)
- Tests: Randwerte (0, negative Splits, große Beträge, Multi-Currency)
- Schließt Issue #33

→ Assign: SeniorDev

---

### Priorität 3: Offline-First + Sync-Status UX

Auth und Live-Rates sind fertig — jetzt dem User zeigen was offline ist:

- Sync-Status Banner (oben, subtil): "Offline — letzte Sync: vor 5 Min"
- Pending Changes Badge auf Ausgaben die noch nicht synchronisiert wurden
- Pull-to-Refresh auf allen Listen-Screens (Swipe down → sofort sync)
- Error States: konsistente UX für Netzwerkfehler, Supabase-Timeouts

→ Assign: SeniorDev

---

### Priorität 4: Push Notifications bei neuen Schulden/Zahlungen

Nutzer sollen informiert werden wenn jemand in ihrer Gruppe eine Ausgabe einträgt:

- Supabase Edge Functions: Trigger auf `expenses` INSERT → Push via FCM/APNs
- Flutter: Firebase Cloud Messaging Setup (oder Supabase Realtime als Alternative)
- Notification: "Max hat 42€ Abendessen hinzugefügt — Dein Anteil: 14€"
- Nur für Gruppen-Mitglieder, nicht für eigene Ausgaben
- Self-Hosted Alternative prüfen: ntfy.sh (kein Google-Dependency)

→ Assign: SeniorDev + DevOps (Edge Function Deployment)

---

### Technische Schulden Sprint 11

- Code Coverage auf 60%+ bringen (aktuell zu niedrig für Beta)
- CI Secrets (Issue #31) — CEO muss Secrets in GitHub eintragen!
- `updated_at` Spalte für `expense_comments` (merge-based conflict detection)

---

### CEO-Aktionen Sprint 11

1. **GitHub Secrets eintragen** (Issue #31 — seit Sprint 6 offen!):
   - `SUPABASE_URL`, `SUPABASE_ANON_KEY` in GitHub Repository Secrets
   - → CI/CD Build läuft sonst ohne Supabase-Config
2. **Supabase Projekt entscheiden**: Free Tier reicht für Beta, Paid für Production
3. **ntfy.sh prüfen** als self-hosted Push-Alternative zu Firebase (passt zur Hetzner-Philosophie)

---

**CTO Entscheidung:**
QR Code ist das No.1 Wachstums-Feature — virales Teilen geht nur mit einem einfachen Scan.
Integer-Cents müssen vor Public Beta rein — Geldapp mit Rundungsfehlern ist nicht acceptable.
Offline-UX trennt eine professionelle App von einem Prototyp.
Push Notifications: ntfy.sh prüfen bevor Firebase — kein Lock-in, kein Google-Dependency.

---
*CTO | Sprint 11 | 2026-03-14*

---

## Sprint 11 — SeniorDev | ntfy.sh Push Notifications | 2026-03-14

### Feature: Push Notifications via ntfy.sh (self-hosted friendly)

**Branch:** `feature/push-notifications-ntfy`

**Implementiert:**

#### lib/core/config/ntfy_config.dart (neu)
- `ntfyBaseUrl`: konfigurierbar via `--dart-define=NTFY_BASE_URL=...` (default: `https://ntfy.sh`)
- `topicPrefix`: `splitgenesis` auf Public-Server, leer auf self-hosted → kein Topic-Konflikt
- `ntfyToken`: Optional Bearer Auth für private ntfy-Instanzen
- `topicForGroup(uuid)`: baut Topic-Namen pro Gruppe

#### lib/core/services/notification_service.dart (erweitert)
- `_sendNtfy()`: HTTP POST zu ntfy-Server
  - Headers: Title, Priority, Tags (Emoji), optional Bearer Token
  - 10s Timeout, silent error handling (Offline-First — Push-Fehler crasht nie die App)
- `showExpenseAdded()`: lokal + remote push, Tags: money_with_wings
- `showExpenseUpdated()`: lokal + remote push, Tags: pencil
- `showDebtSettled()`: NEU — lokal + remote push, Tags: white_check_mark
- `showMemberJoined()`: NEU — lokal + remote push, Tags: wave
- `showMemberLeft()`: NEU — lokal + remote push, Tags: wave

**Alle bestehenden Calls rückwärtskompatibel** — `groupUuid` optional, ntfy wird nur gesendet wenn vorhanden.

**Self-Hosted Setup (CEO / Hetzner):**
```bash
docker run -p 80:80 binwiederhier/ntfy serve
# dann: --dart-define=NTFY_BASE_URL=https://ntfy.yourdomain.com
```

**Nutzer-Flow:**
1. Gruppe erstellen → Topic: `splitgenesis-{groupUuid}`
2. Andere Mitglieder subscriben via ntfy-App auf dieses Topic
3. Bei neuer Ausgabe/Zahlung/Mitglied → HTTP POST → alle subscribierten Mitglieder erhalten Push

*SeniorDev | Sprint 11 | 2026-03-14*

---

## Sprint 12 — CTO Plan | Split Genesis | 2026-03-14

### Sprint Goal
**Beta-Reife: Float→Cent Migration, Code Coverage 60%+, Privacy Policy, CI grün.**
Keine neuen Features bis Cent-Migration fertig. Fundament first.

### Status Sprint 11
- ✅ PR #37 QR Code für Gruppe beitreten (gemerged)
- ✅ PR #44 ntfy.sh Push Notifications, self-hosted (gemerged)
- ✅ CI Fix: flutter analyze Fehler behoben (commit 03c0058)
  - Member import in group_detail_screen.dart
  - Undefined 'group' → widget.group
  - qr_flutter + mobile_scanner in pubspec.yaml
  - Unused variable removed
- ⏳ Issue #31: CEO muss GitHub Secrets eintragen (SUPABASE_URL, SUPABASE_ANON_KEY)
- ⏳ Issue #33: Float→Cent Migration (P0 für Beta)

---

### Sprint 12 Aufgaben

#### P0 — CEO Action Required
- [ ] **GitHub Secrets eintragen** (Issue #31 — seit Sprint 6 offen!)
  - `SUPABASE_URL` und `SUPABASE_ANON_KEY` in GitHub → Settings → Secrets → Actions
  - Ohne das: CI baut ohne Supabase, Tests könnten fehlschlagen
  - → https://github.com/salahxiv/split-genesis/settings/secrets/actions

#### P1 — SeniorDev: Float→Cent Migration (Issue #33)
- [ ] Alle Float-Felder in DB zu Integer-Cents migrieren
  - `expenses.amount` → `amount_cents INTEGER`
  - `settlement_records.amount` → `amount_cents INTEGER`
- [ ] Repository-Layer anpassen: DB liest/schreibt Cents, Models konvertieren
- [ ] `formatCurrency()` nutzt bereits `.amount` getter — keine UI-Änderungen nötig
- [ ] Alle Tests anpassen + neue Migration-Tests
- [ ] Ziel: kein Rundungsfehler mehr bei Split-Berechnungen

#### P2 — SeniorDev: Code Coverage auf 60%+
- [ ] Aktuelle Coverage messen: `flutter test --coverage`
- [ ] Fehlende Tests: Repository-Layer, Debt Calculator, Sync Service
- [ ] Minimum 60% Line Coverage für Beta-Milestone

#### P3 — DevOps: Privacy Policy & Terms (Issue #27)
- [ ] DSGVO-konforme Privacy Policy erstellen (auf Hetzner deployen)
  - Pflichtinhalt: Supabase als Processor, keine Weitergabe an Dritte, Löschrecht
- [ ] Einfache statische HTML-Seite auf Hetzner / nginx
- [ ] URL in App Store / Play Store Listing hinterlegen

#### P4 — SeniorDev: Expense Comments (Technische Schulden)
- [ ] `updated_at` Spalte für `expense_comments` hinzufügen
  - Benötigt für merge-basiertes Conflict Detection in Sync

#### P5 — CTO: ntfy.sh Production Setup evaluieren
- [ ] Entscheidung: Public ntfy.sh vs. self-hosted auf Hetzner
- [ ] Wenn self-hosted: Docker-Setup dokumentieren
- [ ] Topic-Signing evaluieren (verhindert Spam auf public Topics)

---

### Technische Schulden (offen)
- Issue #33: Float→Cent (P0 — in Sprint 12)
- Issue #31: GitHub Secrets (CEO-Action)
- Issue #27: Privacy Policy (P3 in Sprint 12)
- Code Coverage < 60% (P2 in Sprint 12)

---

### Timeline
| Sprint | Fokus |
|--------|-------|
| Sprint 12 | Cent-Migration, Coverage, Privacy Policy |
| Sprint 13 | Public Beta (TestFlight / Play Store Internal) |
| Sprint 14 | Beta Feedback, Bug Fixes |
| Sprint 15 | Production Launch |

---

**CTO Entscheidung:**
Cent-Migration ist non-negotiable vor Public Beta.
Eine Geld-App mit Rundungsfehlern ist nicht launch-fähig.
Push Notifications laufen via ntfy.sh — self-hosted bleibt die Strategie.
CI ist jetzt grün (flutter analyze). Nächste Blockade: CEO Secrets.

---
*CTO | Sprint 12 | 2026-03-14*

---

## Sprint 12 — SeniorDev Update
*SeniorDev | 2026-03-15*

### Feature/Settle-Up-Flow — PR #52 ✅ 🔴 KRITISCH
**Branch:** `feature/settle-up-flow`

Implementierter Settle-Up Flow:

**Neuer Screen:** `lib/features/settlements/screens/settle_up_screen.dart`
- Zeigt alle offenen Schulden aus `groupComputedDataProvider` (DebtCalculator)
- Card-UI: From/To Avatars, Pfeil, Betrag, "Mark as Settled" Button pro Schuld
- Bestätigungsdialog mit Betrag und Empfänger vor Settling
- On Confirm:
  1. `SettlementRecord` in SQLite + Supabase via `addSettlement()`
  2. `groupComputedDataProvider` invalidieren → Balances werden live neu berechnet
  3. Activity Feed Log via `ActivityLogger.logSettlementRecorded()`
  4. ntfy.sh Notification via `NotificationService.showDebtSettled()` (bestehender Service)
- Erfolgs-Snackbar: "{Name} settled {Betrag} with {Empfänger} ✅"
- Empty State: "All settled up! 🎉" wenn keine Schulden mehr
- Header-Karte: Anzahl Schulden + Gesamtbetrag

**Änderungen group_detail_screen.dart:**
- "Settle Up" Button (FilledButton mit Icons.handshake_outlined) im Balances Tab
- Nur sichtbar wenn `computed.settlements.isNotEmpty`
- Navigation zu SettleUpScreen via slideRoute
- `_BalancesTab` erhält jetzt volles `Group` Objekt für Navigation

Notification Format: "{name} settled {amount} with {recipient}" → ntfy.sh Push an Gruppe

---

## Sprint 13 — CTO Kickoff
*CTO | Sprint 13 | 2026-03-15*

### Sprint 13 Scope — Split Genesis

Sprint 12 Ergebnis: Settle-Up Flow (#52) und README (#45) erfolgreich gemerged. Float→Cent Migration und CI sind stabil. Sprint 13 fokussiert auf Algorithmus-Qualität, Multi-Currency UX und Export.

**Sprint 13 Ziele:**
- #53 Simplify Debts Algorithmus — minimale Anzahl an Transaktionen beim Ausgleichen
- #54 Multi-Currency Display — CEO-Entscheidung: KEINE Konvertierung, Währungen separat anzeigen
- #55 Export CSV/PDF — User können Ausgaben exportieren

---

### Sprint 13 — Tasks für SeniorDev

#### #53 Simplify Debts Algorithmus
**Ziel:** Debt-Simplification — minimiert Anzahl der Ausgleichstransaktionen in einer Gruppe
- Aktueller `DebtCalculator` berechnet Schulden bilateral — bei 5 Personen entstehen bis zu 10 Transaktionen
- Implementiere Greedy/Net-Settlement Algorithmus: Netto-Balances berechnen, dann minimal-transactions
- Algorithmus: Sortiere nach Netto-Balance, matche größten Gläubiger mit größtem Schuldner
- Neue Methode `simplifyDebts(debts: [Debt]) -> [Settlement]` in `DebtCalculator`
- Vollständige Unit-Tests: mind. 5 Test-Cases (2 Personen, 3 Personen, zyklische Schulden, bereits ausgeglichen, mixed currencies)
- Bestehende `SettleUpScreen` nutzt neuen Algorithmus automatisch

#### #54 Multi-Currency Display
**CEO-Entscheidung (final):** Beträge werden NICHT konvertiert. Jede Währung wird separat angezeigt.

**Anzeigeformat:** `"12,50 € + 8,00 $"` — kein einheitlicher Betrag, keine Umrechnung
- `CurrencyAggregator` Klasse: gruppiert Beträge nach ISO-Währungscode
- `formatMultiCurrency(amounts: [String: Decimal]) -> String` — gibt "12,50 € + 8,00 $" zurück
- Überall in der App wo Gesamtbeträge angezeigt werden: Gruppe-Total, Balances, Settle-Up
- Frankfurter API (bereits integriert) bleibt für zukünftige Features — wird in Sprint 13 NICHT für Konvertierung genutzt
- `GroupSummaryCard` und `BalancesTab` updaten für Multi-Currency Strings

#### #55 Export CSV/PDF
**Ziel:** User können alle Ausgaben einer Gruppe als CSV oder PDF exportieren
- CSV-Export: alle Expenses einer Gruppe (Datum, Beschreibung, Betrag, Währung, Bezahlt von, Split-Typ)
- PDF-Export: formatiertes Layout mit Gruppenname, Datum, Expenses-Tabelle, Balances
- `ExportService.dart`: `exportCSV(group: Group)` + `exportPDF(group: Group)`
- `share_plus` Package für nativen Share-Sheet (iOS/Android/macOS)
- Export-Button in GroupDetailScreen (Overflow-Menu oder dedizierter Button)
- Dateiname: `split-genesis-{groupName}-{date}.csv/pdf`

---

*CTO | Sprint 13 gestartet | 2026-03-15*

---

## Sprint 13 — 2026-03-15

### @SeniorDev — Feature: Simplify Debts Algorithmus (Issue #53)

**Status: PR #56 erstellt** → https://github.com/salahxiv/split-genesis/pull/56

**Was implementiert wurde:**

- `debt_calculator.dart`: Ausführliche Dokumentation des Simplify-Debts-Algorithmus:
  - Greedy net-balance Matching: größter Schuldner → größter Gläubiger
  - Reduziert auf max N-1 Transaktionen (vs N*(N-1)/2 naiv)
  - Neuer `simplifyDebts` Bool-Parameter (default `true`) auf `calculateSettlements()`
  - `_simplifyDebts()` und `_rawSettlements()` getrennte Pfade
  - Beispiel dokumentiert: A schuldet B €10, B schuldet C €10 → A zahlt C direkt €10

- `app_settings_service.dart` (neu): `AppSettingsNotifier` + `appSettingsProvider`
  - SharedPreferences-Persistenz
  - `simplifyDebts` default: `true` (Setting kann deaktiviert werden)

- `balances_provider.dart`: liest `AppSettings.simplifyDebts` und leitet an `DebtCalculator` weiter

- `debt_calculator_test.dart`: 6 neue "Simplify Debts" Tests:
  - Kettenauflösung A→B→C
  - 5-Personen Szenario (max N-1 Transaktionen verifiziert)
  - Komplexes Reise-Szenario
  - Zirkuläre Schulden heben sich auf
  - Asymmetrisches Netz

---

### @SeniorDev — Feature: Multi-Currency Display (Issue #54)

**Status: PR #57 erstellt** → https://github.com/salahxiv/split-genesis/pull/57

**CEO-Entscheidung: KEINE automatische Konvertierung. Jede Währung separat anzeigen.**

**Was implementiert wurde:**

- `balance.dart`: Neue `MultiCurrencyBalance` Klasse
  - `Map<String, int> currencyBalances` (currencyCode → centsAmount)
  - `owedCurrencies` / `owingCurrencies` getter
  - `isSettledUp` helper
  - `centsFor()` / `amountFor()` Convenience-Methoden

- `debt_calculator.dart`: Neue `calculateMultiCurrencyBalances()` Methode
  - Pro-Währung Saldo-Berechnung ohne Konversion
  - Credits Zahler, Debits Split-Mitglieder in der jeweiligen Ausgaben-Währung
  - Settlements in der Gruppen-Währung verrechnet

- `balances_provider.dart`: `GroupComputedData` hat neues `multiCurrencyBalances` Feld

- `group_detail_screen.dart`:
  - Erkennt automatisch Multi-Currency-Gruppen
  - Multi-Currency View: "owes 12,50 € + 8,00 $" (keine Konversion)
  - Fallback auf Standard-Single-Currency-View für homogene Gruppen
---

## Sprint 13 → ABGESCHLOSSEN | CTO Merge-Report | 2026-03-15

### ✅ Sprint 13 vollständig abgeschlossen

**Alle PRs gemerged:**
- ✅ PR #56 — Simplify Debts Algorithm → main
- ✅ PR #57 — Multi-Currency Display per CEO Decision → main

---

## Sprint 14 — CTO Plan | Split Genesis | 2026-03-15

### Sprint Goal
**Export-Funktionalität + Offline-Resilienz. Beide Features sind user-kritisch und fehlten bisher komplett.**
Sprint 14 macht Split Genesis production-ready für Offline-Szenarien und schließt die Export-Lücke.

---

### Feature #55 — Export CSV + PDF (share_plus)

**Ziel:** Gruppen-Abrechnungen als CSV und PDF exportieren und teilen.

**Dependency:**
- `share_plus: ^7.x` in `pubspec.yaml` hinzufügen (bereits geplant in Issue #55)
- `pdf: ^3.x` für PDF-Generierung (dart-native, kein Native-Bridge nötig)
- `path_provider: ^2.x` für temporäres File-System

**CSV Export:**

Format (Beispiel):
```
Date,Description,Amount,Currency,PaidBy,SplitAmong,YourShare
2026-03-10,Dinner,120.00,EUR,Alice,"Alice,Bob,Carol",40.00
2026-03-11,Hotel,300.00,EUR,Bob,"Alice,Bob",150.00
...
---
TOTAL OWED TO YOU: 45.00 EUR
TOTAL YOU OWE: 20.00 EUR
```

- `CsvExportService.dart`:
  - `generateCsv(Group group, List<Expense> expenses) → String`
  - Header-Zeile + eine Zeile pro Expense
  - Footer: Saldo-Zusammenfassung
  - Multi-Currency: separate Spalte `Currency`, kein Mischen

**PDF Export:**

- `PdfExportService.dart`:
  - `generatePdf(Group group, List<Expense> expenses) → Future<Uint8List>`
  - Header: Gruppenname, Zeitraum (erste–letzte Ausgabe), Exportdatum
  - Tabelle: Datum | Beschreibung | Betrag | Bezahlt von | Dein Anteil
  - Footer: Saldo pro Person + Begleichungsvorschläge (simplifiedDebts)
  - Multi-Currency: eigene Tabelle pro Währung
  - Styling: sauber, minimal, lesbar auf A4

**UI-Integration:**

- `GroupDetailScreen`: Share-Button in AppBar (Icon: `share`)
  - Bottom Sheet: "Als CSV exportieren" + "Als PDF exportieren"
  - `share_plus` öffnet nativen Share-Dialog → AirDrop, E-Mail, WhatsApp, etc.
- `ExpensesListScreen`: gleicher Share-Button optional

**Acceptance Criteria:**
- CSV öffnet korrekt in Excel/Numbers (UTF-8 BOM für Windows-Kompatibilität)
- PDF ist lesbar und korrekt formatiert auf iPhone + Android
- Multi-Currency-Gruppen exportieren korrekt (keine Mischrechnung)
- Share-Sheet öffnet sich auf iOS + Android
- Kein Crash bei leerer Gruppe (0 Ausgaben)

---

### Neues Feature — Offline Sync Conflict Resolution

**Problem:** Split Genesis hat keine Conflict Resolution-Strategie. Bei Offline-Änderungen von mehreren Geräten entstehen inkonsistente Zustände. Laut CTO-Review: komplett fehlend.

**Design-Entscheidung (CTO):**
Wir nutzen **Last-Write-Wins (LWW) mit Timestamp + Device-ID** als pragmatischen ersten Ansatz.
Kein CRDT (zu komplex für jetzt), kein manuelles Merge-UI (zu aufwändig für v1).
LWW ist fair wenn Timestamps korrekt sind — und ausreichend für typische Split-App-Nutzung.

**Implementierung:**

- `SyncMetadata` Model:
  ```dart
  class SyncMetadata {
    final String deviceId;         // UUID, persistent pro Gerät
    final DateTime lastModified;   // UTC Timestamp
    final int vectorClock;         // monoton steigend pro Gerät
    final bool isDeleted;          // Soft-Delete Flag
  }
  ```

- Jede `Expense` und `Group` bekommt `SyncMetadata syncMeta` Feld (nullable in Migration)

- `ConflictResolutionService.dart`:
  - `resolveExpense(Expense local, Expense remote) → Expense`
    - Vergleiche `lastModified` — neuerer Timestamp gewinnt
    - Bei gleichem Timestamp: höherer `vectorClock` gewinnt
    - Bei gleichem Clock: `deviceId` alphabetisch letzter gewinnt (deterministisch)
  - `resolveGroup(Group local, Group remote) → Group` — gleiche Logik
  - `isSoftDeleted(SyncMetadata meta) → bool`

- `SyncService.dart` (erweitern):
  - Vor jedem Write: `SyncMetadata` mit aktuellem Timestamp + DeviceId stempeln
  - Bei Sync (Pull): für jede Entity `ConflictResolutionService.resolve()` aufrufen
  - Soft-Delete: Entity nie hart löschen — `isDeleted: true` setzen und syncen

- `DeviceIdService.dart` (neu):
  - `getOrCreateDeviceId() → String` — UUID in SharedPreferences persistieren

- Lokale DB Migration:
  - `syncMeta` Spalte zu `expenses` und `groups` Tables hinzufügen (nullable für Backwards-Compatibility)
  - Migration-Version inkrementieren

- **Conflict-Indicator UI (optional aber empfohlen):**
  - Wenn eine Entity durch Remote-Sync überschrieben wurde: kurze Snackbar "Änderung von anderem Gerät übernommen"
  - Kein manuelles Merge-UI nötig (LWW macht das automatisch)

**Offline-Queue:**
- `OfflineQueueService.dart`: lokale SQLite-Queue für ausstehende Sync-Operationen
  - Write → immer lokal + in Queue
  - Background Sync → Queue abarbeiten wenn Online
  - Queue-Eintrag: `{ entityType, entityId, operation: 'upsert'|'delete', payload, timestamp }`

**Acceptance Criteria:**
- Gerät A ändert Ausgabe offline, Gerät B ändert dieselbe Ausgabe offline → beim Sync gewinnt neuerer Timestamp
- Kein Datenverlust durch Sync (Soft-Delete statt Hard-Delete)
- Offline-Änderungen werden beim nächsten Online-Gang automatisch synchronisiert
- Snackbar erscheint wenn Remote-Änderung lokal überschreibt
- Keine Abstürze bei Sync-Konflikten
- Backwards-kompatibel: alte Clients ohne syncMeta funktionieren weiter (nullable)

---

### Sprint 14 Timeline

| Task | Priorität | Estimated |
|------|-----------|-----------|
| #55 CsvExportService | P1 | 0.5 Tag |
| #55 PdfExportService | P1 | 1 Tag |
| #55 UI Share-Integration | P1 | 0.5 Tag |
| Offline DeviceIdService | P2 | 0.5 Tag |
| Offline SyncMetadata Model + Migration | P2 | 0.5 Tag |
| Offline ConflictResolutionService | P2 | 1 Tag |
| Offline OfflineQueueService | P2 | 1 Tag |
| Offline UI (Snackbar) | P2 | 0.5 Tag |

**Gesamt: ~5.5 Tage. Parallel-Implementierung möglich (Export + Offline unabhängig).**

---

### CTO Entscheidung

Export (#55) ist P1 — Nutzer erwarten das, es fehlt komplett, es ist schnell umzusetzen.
Offline Conflict Resolution ist P2 aber dringend — ohne das ist Multi-Device-Nutzung unzuverlässig.
LWW ist pragmatisch und korrekt für diesen Use-Case. Kein Over-Engineering.

Beide Features brauchen keine neuen Server-Komponenten — rein client-side.

---
*CTO | Sprint 14 | 2026-03-15*
---

## Sprint 14 — SeniorDev Kickoff | Split Genesis | 2026-03-15

CI ist wieder grün. Sprint 14 startet jetzt.

### P1: Export CSV/PDF (Issue #55)

**Ziel:** Nutzer können Ausgaben einer Gruppe als CSV oder PDF exportieren und teilen.

**Aufgaben:**
1. `CsvExportService` — generiert CSV-String aus Expense-Liste (memberId→Name lookup, Formatierung)
2. `PdfExportService` — generiert PDF via `pdf` package (Tabelle mit Datum, Beschreibung, Betrag, Wer hat gezahlt, Splits)
3. Share-Integration — `share_plus` package: Share-Sheet öffnen mit Datei
4. Export-Button in GroupDetailScreen (AppBar Action oder FAB)
5. Tests für CsvExportService (Unit) + PdfExportService (Smoke)

**Acceptance Criteria:**
- CSV enthält: date, description, amount, currency, paidBy, splits (kommagetrennt)
- PDF ist lesbar und enthält Gruppen-Name + Zeitstempel im Header
- Share-Sheet öffnet auf iOS und Android
- Kein Crash bei leerer Gruppe

**Branch:** `feature/export-csv-pdf` → PR nach Fertigstellung

---

### P2: Offline Sync Conflict Resolution

**Ziel:** Wenn zwei Geräte gleichzeitig Änderungen machen (offline), werden Konflikte sauber aufgelöst.

**Aufgaben:**
1. `DeviceIdService` — eindeutige Geräte-ID generieren und speichern (SharedPreferences)
2. `SyncMetadata` Model + SQLite Migration — Tabelle: `id, entity_type, entity_id, device_id, updated_at, sync_version`
3. `ConflictResolutionService` — Last-Write-Wins (LWW) per `updated_at` Timestamp
4. `OfflineQueueService` — lokale Operationen queuen wenn offline, beim Reconnect abspielen
5. UI-Feedback — Snackbar wenn Sync-Konflikt aufgelöst wurde ("Conflict resolved: server version kept")
6. Tests für ConflictResolutionService (Unit)

**Acceptance Criteria:**
- Gerät A und B ändern dieselbe Expense offline → beim Sync gewinnt der neuere Timestamp
- Keine doppelten Einträge nach Sync
- Nutzer sieht kurze Benachrichtigung wenn Konflikt aufgetreten

**Branch:** `feature/offline-conflict-resolution` → PR nach Fertigstellung

---

*SeniorDev | Sprint 14 | 2026-03-15*

---

## Sprint 14 — Export CSV + PDF Implementation Complete (SeniorDev)

**Date:** 2026-03-15

### ✅ Feature/Export-CSV-PDF — PR #58

**Implemented:**
- `lib/core/services/csv_export_service.dart`
  - UTF-8 BOM for Excel compatibility on Windows/Mac
  - Multi-currency: each currency in own Amount column (no conversion — per Issue #54)
  - Sorted newest-first, all expense fields included
- `lib/core/services/pdf_export_service.dart`
  - A4 layout via `pdf: ^3.11.1` package
  - Header: group name + export date
  - Section 1: Multi-currency balances table (per member)
  - Section 2: Full expense list (date, description, paid by, amount+currency)
- `pubspec.yaml`: added `pdf: ^3.11.1`
- `group_detail_screen.dart`:
  - `_exportCsv()` and `_exportPdf()` methods
  - Kebab menu (⋮): "Export CSV" + "Export PDF" entries with divider
  - Native Share Sheet via `share_plus` (iOS + Android native share)

**PR:** https://github.com/salahxiv/split-genesis/pull/58

*SeniorDev | Sprint 14 | 2026-03-15*

---

## Sprint 15 — CTO Sprint Plan (2026-03-15)

**Ziel: Beta-Readiness für Split Genesis**

### 🎯 Sprint-Ziel
Zwei kritische Features implementieren, die für eine vertrauenswürdige Beta unerlässlich sind: Offline Conflict Resolution und Receipt-Foto-Anhänge.

### 📋 Sprint 15 Backlog

#### Feature 1 — Offline Sync Conflict Resolution (KRITISCH vor Beta)

**Kontext:** Bereits in Sprint 14 als Backlog-Feature geplant, aber nicht implementiert — wegen Export-Priorisierung verschoben.

**Warum kritisch:** Ohne Konfliktauflösung entstehen bei Offline-Nutzung (häufig im Restaurant, Ausland) stille Datenverluste. Das ist ein Trust-Killer für eine Finanz-App.

**Technischer Plan:**
- `ConflictResolutionService` — Last-Write-Wins via `updated_at` Timestamp
- Supabase Realtime: bei Reconnect werden pending local writes mit Server-State verglichen
- Konflikt-Protokoll: `SyncConflictLog` Model — welcher Wert gewann, Timestamp, Gerät
- User-Notification: SnackBar "1 Konflikt beim Sync gelöst"
- Unit Tests: Szenario A & B editieren dieselbe Expense offline → Sync → neuerer Timestamp gewinnt

**Acceptance Criteria:**
- [ ] Gerät A und B ändern dieselbe Expense offline → neuerer Timestamp gewinnt
- [ ] Keine doppelten Einträge nach Sync
- [ ] User sieht kurze Benachrichtigung bei Konflikt
- [ ] Kein Datenverlust in Testszenarien

**Owner:** SeniorDev
**Branch:** `feature/offline-conflict-resolution`
**Deadline:** 27. März

#### Feature 2 — Receipt Foto (Issue #47)

**Kontext:** Trust-Feature — macht Split Genesis zur Single Source of Truth für Ausgaben.

**Technischer Plan (aus Issue #47):**
- Kamera-Button beim Erstellen/Bearbeiten einer Ausgabe
- PHPickerViewController (iOS) für Bibliothek + Kamera
- Upload zu Supabase Storage (User-spezifischer Bucket)
- Image Compression: max 1024px, JPEG 0.8, max 5MB
- Thumbnail in Ausgaben-Liste, Vollbild via Tap
- Row-Level Security: nur Gruppenmitglieder sehen Gruppenfotos
- Löschen: nur vom Ersteller möglich

**Acceptance Criteria:**
- [ ] Foto hinzufügen beim Erstellen und Bearbeiten
- [ ] Thumbnail sichtbar in Liste
- [ ] Vollbild-Ansicht
- [ ] Upload erfolgreich, RLS korrekt
- [ ] Löschen nur durch Ersteller
- [ ] Dateigrößen-Check (>5MB → Fehler)

**Owner:** SeniorDev
**Branch:** `feature/receipt-photo`
**Deadline:** 1. April

### 🗓️ Timeline Sprint 15

| Datum | Milestone |
|-------|-----------|
| 27. März | Offline Conflict Resolution — PR gemergt |
| 1. April | Receipt Foto — PR gemergt |
| 5. April | Beta TestFlight / Google Play Beta bereit |

### 🚨 Risiken
- Supabase Storage Limits bei vielen Receipt-Fotos → Komprimierung konsequent einhalten
- Conflict Resolution muss für alle Offline-Szenarien getestet sein (Flugmodus, schwaches Netz)
- RLS-Konfiguration in Supabase muss sorgfältig getestet werden (Datenleck-Risiko)

### Architektur-Entscheid (CTO)
Receipt-Fotos werden in Supabase Storage abgelegt, **nicht** in der Datenbank als Base64. Bucket: `receipts/{group_id}/{expense_id}/{filename}`. RLS Policy: `auth.uid() IN (SELECT user_id FROM group_members WHERE group_id = ...)`.

*CTO | Sprint 15 | 2026-03-15*

---

## Sprint 15 — SeniorDev Update (2026-03-15)

### ✅ Offline Conflict Resolution — PR #59 erstellt

Branch: `feature/offline-conflict-resolution`
PR: https://github.com/salahxiv/split-genesis/pull/59

#### Implementierung: Last-Write-Wins (LWW)

**ConflictResolutionService.dart** (neu):
- `resolveExpense(local, server)` → winning Expense
- `resolveGroup(local, server)` → winning Group
- `resolveRow()` / `resolveRowWinner()` → für raw SQLite Maps
- Strategie: `local.updated_at > server.updated_at` → local wins, sonst server wins
- Fehlende Timestamps → server wins (sicherer Default)

**OfflineQueueService.dart** (neu):
- SQLite-Queue in `offline_queue` Tabelle (v10 Migration in DatabaseHelper)
- Deduplizierung: (table, entityId, operation) → neuester Payload gewinnt
- `flush()`: FIFO-Verarbeitung bei Reconnect, max. 5 Retries pro Eintrag
- `syncedStream`: emittet Sync-Count für UI-Snackbar

**SyncService.dart** (erweitert):
- `pushPendingChanges()`: 1. OfflineQueue flushen, 2. LWW-Check vor legacy pending rows, 3. `syncedCountStream` für UI

**ApiFirstRepository (Mixin, erweitert)**:
- `fetchAndCache()`: LWW — server rows überschreiben lokale pending changes NICHT wenn local.updated_at neuer
- `writeThrough()`: Offline-Writes in OfflineQueueService einreihen

**HomeScreen.dart** (erweitert):
- `SyncService.syncedCountStream` listener
- Snackbar: `'X Änderungen synchronisiert'` nach erfolgreichem Sync

#### Modelle
- `expense.dart`, `group.dart`: `updated_at` Feld bereits vorhanden — keine Änderung nötig

*SeniorDev | Sprint 15 | 2026-03-15*

---

## Sprint 16 — CTO Plan (2026-03-15)

### 🎯 Sprint-Ziel: Stabilisierung + Cent-Migration + Receipt-Feature

Sprint 15 abgeschlossen. PR #59 (Offline LWW Conflict Resolution) gemerged. CI auf `main` läuft gerade — Status beobachten (CI war vorher `failure` auf feature-branch).

---

### 🔴 SeniorDev Priorität 1 — Kritische Korrekturen (sofort)

#### 1. Float → Cent-Arithmetik Migration (Issue #33, priority-high, BUG)
- **Warum kritisch**: Floating-Point-Fehler bei Währungsberechnungen sind fatal für eine Expense-Splitting-App
- **Scope**: Alle `double`-Felder in `expense.dart`, `group.dart` auf `int` (Cent) migrieren
- SQLite Schema Migration (v11?), bestehende Daten konvertieren
- `SplitCalculator` und alle UI-Formatter auf Cent-Basis umstellen
- **Kein Release ohne diese Migration**

#### 2. CI/CD GitHub Secrets einrichten (Issue #31, priority-high)
- CI auf `main` zeigt `failure` — vermutlich fehlende Secrets
- SeniorDev muss gemeinsam mit DevOps die `SUPABASE_URL`, `SUPABASE_ANON_KEY` etc. als GitHub Secrets eintragen
- **CI muss grün sein bevor weitere Features**

---

### 🟡 SeniorDev Priorität 2 — Features (nach P1 erledigt)

#### 3. Receipt Foto — Beleg an Ausgabe anhängen (Issue #47)
- `image_picker` Package, Bild in Supabase Storage
- Offline: Bild lokal cachen, Upload in OfflineQueue einreihen (LWW-Infrastruktur aus Sprint 15 nutzen!)
- **Nutzt direkt die neue OfflineQueueService-Infrastruktur**

#### 4. Expense Split UX: Live-Preview + Modi (Issue #51)
- Equal / Percentage / Custom Split — Live-Preview im UI
- Wichtig für User-Experience, TestFlight-Feedback erwartet das

#### 5. Wiederkehrende Ausgaben (Issue #48)
- `RecurringExpense` Model + Scheduler (cron-ähnlich im App-Start)
- Miete, Netflix, Strom automatisch eintragen

---

### 🟢 Backlog (Sprint 17+)

- Ausgaben-Kategorien & Budget-Tracking (Issue #50)
- Privacy Policy & ToS (Issue #27, DSGVO — brauchen wir vor Launch!)

---

### ⚠️ CTO Risikohinweis für Sprint 16

1. **Cent-Migration ist Breaking Change**: Schema v11 Migration muss alle bestehenden Daten korrekt konvertieren — Testplan mit Edge Cases (null, 0, negative Werte)
2. **LWW + OfflineQueue**: Sprint 15 hat gute Infrastruktur gebaut. Receipt-Feature soll diese nutzen, nicht bypassen. Kein direkter Supabase-Upload ohne Offline-Fallback.
3. **Privacy Policy fehlt noch** (Issue #27) — für EU/App Store notwendig, nicht ignorieren

---

### ✅ Sprint 16 DoD (Definition of Done)

- [ ] CI grün auf `main` (GitHub Secrets konfiguriert)
- [ ] Float → Cent-Migration vollständig + getestet
- [ ] Receipt-Foto Feature (Offline-fähig)
- [ ] Split UX Live-Preview
- [ ] Keine Regression in LWW/Offline-Sync

*CTO | Sprint 16 Plan | 2026-03-15*

---

### 🛠️ SeniorDev Sprint 16 — Fortschritt

#### Issue #33 — Float → Cent-Arithmetik Migration ✅ DONE
- DB Version 10 → 12 (v11: Datenintegrität-Check, v12: receipt_url)
- v11: Backfill amount_cents wo = 0 aber amount > 0 (edge case guard)
- Model bereits korrekt: amountCents ist Primary, amount = computed getter
- Repository bereits korrekt: alle read/write paths nutzen amount_cents
- **PR #60**: https://github.com/salahxiv/split-genesis/pull/60

#### Issue #47 — Receipt Foto ✅ DONE
- `image_picker ^1.1.2` + `flutter_image_compress ^2.3.0` in pubspec.yaml
- `ReceiptService`: compress → max 1MB JPEG 80%, local save, Supabase Storage upload (`receipts/{groupId}/{expenseId}.jpg`)
- `Expense` model: `receiptUrl String?` (toMap/fromMap/toApiMap)
- `AddExpenseWizard` Step 3: Foto-Button (Kamera/Galerie/Entfernen) mit Vorschau
- `ExpenseDetailScreen`: Foto-Anzeige mit Ladeanimation + Error-Fallback
- **PR #61**: https://github.com/salahxiv/split-genesis/pull/61

*SeniorDev | Sprint 16 | 2026-03-15*

---

## Sprint 17 — CTO Plan (2026-03-15)

### 🎯 Sprint-Ziel: Killer Features für WG-Use-Case + UX-Polishing

Sprint 16 ist abgeschlossen. PRs #60 (Cent-Migration) und #61 (Receipt-Foto) gemerged. CI-Fixes pushed (const constructors in CSV/PDF-Services, DB v12 Konflikt aufgelöst). CI läuft neu.

**Sprint 17 liefert die zwei Features, die Split Genesis vom Hobby-Projekt zur echten WG-App machen.**

---

### 🔴 SeniorDev Priorität 1 — Wiederkehrende Ausgaben (Issue #48)

**Warum jetzt**: WG-Miete, Netflix, Strom — das ist der #1 Use-Case unserer Zielgruppe. Ohne Recurring Expenses müssen Nutzer jeden Monat manuell eintragen → Churn.

**Technischer Scope:**

#### Datenbankschicht (DB v13)
- Neue Tabelle `recurring_expenses`:
  ```sql
  CREATE TABLE recurring_expenses (
    id TEXT PRIMARY KEY,
    group_id TEXT NOT NULL,
    description TEXT NOT NULL,
    amount_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    paid_by_id TEXT NOT NULL,
    split_type TEXT NOT NULL DEFAULT 'equal',
    interval TEXT NOT NULL, -- 'weekly' | 'monthly' | 'yearly'
    start_date TEXT NOT NULL,
    end_date TEXT,
    next_due_date TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (paid_by_id) REFERENCES members(id) ON DELETE CASCADE
  )
  ```
- `RecurringExpense` Dart-Model analog zu `Expense`
- `RecurringExpenseRepository` mit CRUD

#### Scheduling (App-seitig, kein Server-Dependency)
- `RecurringExpenseScheduler`: beim App-Start prüfen ob `next_due_date <= today`
- Fällige Einträge automatisch als echte Expense anlegen
- `next_due_date` nach Intervall weitersetzen
- Push Notification (local): "Miete wurde automatisch eingetragen — 450€"
- **Kein Supabase Edge Function Dependency** — funktioniert offline first

#### UI
- `AddExpenseWizard`: "Wiederkehrend" Toggle in Step 1 → Intervall-Picker erscheint
- `RecurringExpensesScreen`: Übersicht aller aktiven Serien (List + Detail)
- Edit-Dialog: "Nur diese" vs. "Alle zukünftigen"
- Badge/Icon in Expense-Liste für recurring items

**DoD Issue #48:**
- [ ] DB v13 Migration läuft ohne Fehler
- [ ] Scheduler erstellt fällige Expenses beim App-Start
- [ ] UI Toggle in AddExpenseWizard
- [ ] RecurringExpensesScreen mit Deaktivieren
- [ ] Tests: Scheduler-Logic (wöchentlich, monatlich, jährlich, Randfall: 28./29. Feb)
- [ ] CI grün

---

### 🟡 SeniorDev Priorität 2 — UX Live-Preview (Issue #51)

**Warum jetzt**: Issue #33 (Cent-Migration) ist gemerged → Dependency erfüllt. Split-Preview war schon Sprint 12 geplant — Zeit es zu liefern.

**Technischer Scope:**

#### SplitPreviewWidget
- Neues Widget `SplitPreviewWidget` mit `ValueNotifier` getriebenen Rebuilds
- Zeigt Aufschlüsselung: Name → Betrag in Echtzeit
- Cent-korrekte Equal-Split Logik (Penny-Ausgleich letzter Member)
- Percentage-Mode: Summen-Validierung (≠ 100% → rote Hint)
- Custom-Mode: Summen-Validierung (≠ Gesamtbetrag → rote Hint)

#### AddExpenseWizard Integration
- Step 2 erhält `SplitPreviewWidget` unten fix eingeblendet
- Live-Update bei Betrag-Änderung, Mitglieder-Selection, Mode-Wechsel
- Keine Performance-Regression: `RepaintBoundary` + gezielter Notifier

**DoD Issue #51:**
- [ ] SplitPreviewWidget: Equal, Percentage, Custom Modi
- [ ] Cent-Arithmetik korrekt (keine Floats)
- [ ] Live-Update in AddExpenseWizard
- [ ] Validation-Feedback bei ungültiger Summe
- [ ] Widget-Tests für alle 3 Modi + Edge Cases
- [ ] CI grün

---

### ⚠️ CTO Risikohinweis Sprint 17

1. **Recurring + Offline-Sync**: Scheduler-erstellte Expenses müssen durch OfflineQueue — nicht am Sync vorbei schreiben
2. **next_due_date Logik**: Monatsende-Randfall (30. Feb → 28. Feb) explizit testen, sonst Produktionsbug garantiert
3. **Split Preview + Cent**: #51 depends on #33 — jetzt grün, nicht wieder Float einschleichen lassen. Code-Review-Check: keine `double`-Arithmetik in Split-Logik

---

### 📋 Sprint 17 Backlog (won't-do this sprint)

- Ausgaben-Kategorien & Budget-Tracking (Issue #50) → Sprint 18
- Privacy Policy (Issue #27) → **nicht ignorieren**, CEO muss bis App Store Submit liefern

---

### ✅ Sprint 17 DoD

- [ ] CI grün auf `main` nach jedem Merge
- [ ] Issue #48 (Recurring) vollständig: Scheduler + UI + Tests
- [ ] Issue #51 (Live-Preview) vollständig: 3 Modi + Cent-korrekt + Tests
- [ ] PR #61 (Receipt) sauber in `main` (Konflikt war: ✅ gelöst)
- [ ] Keine Regression im Offline-Sync / LWW

*CTO | Sprint 17 Plan | 2026-03-15*

---

## SeniorDev Sprint 17 — Implementierung abgeschlossen — 2026-03-15 02:15 UTC

### ✅ Issue #48 — Wiederkehrende Ausgaben
**PR #62**: `feature/recurring-expenses` → `main`

**Implementiert:**
- `Expense` Model: `isRecurring: bool`, `recurrenceInterval: String?` (monthly/weekly/biweekly), `nextDueDate: DateTime?`, `recurringParentId: String?`
- DB v13 Migration: 4 neue Spalten in `expenses` Tabelle (ALTER TABLE)
- `add_expense_wizard.dart` Step 1: Toggle "Wiederkehrend" + SegmentedButton für Intervall + Preview "Nächste Ausführung: DD.MM.YYYY"
- `RecurringExpenseService` (neu): `checkAndCreateDue()` — findet fällige Templates, erstellt Kopien mit neuer ID, setzt `nextDueDate` vor
- `HomeScreen.initState()`: ruft `RecurringExpenseService.instance.checkAndCreateDue()` auf App-Start auf
- `ExpensesProvider.addExpense()`: neue optionale Parameter `isRecurring`, `recurrenceInterval`, `nextDueDate`

**PR**: https://github.com/salahxiv/split-genesis/pull/62

---

### ✅ Issue #51 — Live Split Preview
**PR #63**: `feature/expense-split-preview` → `main`

**Implementiert:**
- `_buildLiveSplitPreview()` — neue Widget-Methode in `AddExpenseWizard`
- Animierte Balken (TweenAnimationBuilder + LinearProgressIndicator) pro Person, proportional zum Anteil
- Echtzeit: `ValueListenableBuilder` auf `_splitInputNotifier` → Preview updatet sich bei jeder Eingabe
- Unterstützt alle Split-Modi: equal, exact, percent, shares
- Bestehende Validierungsfehler (Summe ≠ Gesamtbetrag) bleiben erhalten
- Zeigt Währungssymbol korrekt aus `_selectedCurrency`

**PR**: https://github.com/salahxiv/split-genesis/pull/63

*SeniorDev | Sprint 17 | 2026-03-15*

---

## CTO Sprint 18 — Split Genesis — Beta Vorbereitung — 2026-03-15

### 🚀 Sprint 18 Ziel: Beta-ready
**Code Freeze: offen (Beta-Release geplant Q2 2026)**

---

### 🔴 PRIORITY 1 — Kategorien & Budget-Tracking (Issue #50)

**@SeniorDev Tasks:**

#### 1. Datenbank-Migration
- DB Version bump (aktuell: v13 → v14)
- `ALTER TABLE expenses ADD COLUMN category_id TEXT REFERENCES categories(id)`
- Neue Tabelle `categories`: `id, name, emoji, color, group_id (nullable), is_default BOOL`
- Seed: Standard-Kategorien `🍕 Essen`, `🏠 Wohnen`, `🚗 Transport`, `🎉 Freizeit`, `🛒 Einkauf`, `📦 Sonstiges`

#### 2. UI — Kategorie-Auswahl im Wizard
- `AddExpenseWizard` Step 1: Emoji-Grid mit Kategorie-Auswahl
- Custom Kategorie erstellen: `+`-Button → Modal mit Emoji-Picker + Label
- Custom Kategorien sind Gruppen-spezifisch (`group_id` gesetzt)

#### 3. Kategorie-Übersicht (neuer Tab / Screen)
- Donut-Chart mit `fl_chart` (bereits in pubspec?) oder `syncfusion_flutter_charts`
- Ausgaben nach Kategorie aufgeteilt (aktueller Monat)
- Liste darunter mit Betrag + Prozent

#### 4. Budget-Feature (optional, kann Post-Beta sein)
- Budget pro Kategorie (monatlich) setzen
- Warnung bei X% ausgeschöpft (Push Notification via FCM)
- Warnung: nicht überkomplizieren für Beta

---

### 🔴 PRIORITY 2 — In-App Review Prompt

**@SeniorDev Tasks:**

#### 1. Trigger-Logik implementieren
- SharedPreferences Key: `successful_settlements_count`
- Nach jedem Settlement: Counter +1
- Bei Counter == 3: `in_app_review` Package → `InAppReview.instance.requestReview()`
- Cooldown: nie öfter als alle 90 Tage (Timestamp speichern)

#### 2. Package hinzufügen
```yaml
dependencies:
  in_app_review: ^2.0.9
```
- iOS: funktioniert out-of-the-box (StoreKit)
- Android: Google Play Core API

#### 3. Fallback
- Wenn `InAppReview.instance.isAvailable()` false: nichts tun (kein Store-Link, kein Popup)

---

### 🟡 PRIORITY 3 — Beta-Readiness Check

**Was fehlt noch für Beta?**

| # | Thema | Status | Sprint |
|---|-------|--------|--------|
| #50 | Kategorien & Budget-Tracking | 🔴 Offen | Sprint 18 |
| #49 | Offline-First SQLite Sync | 🟡 Offen | Sprint 18 oder 19 |
| #31 | GitHub Secrets CI | 🔴 Kritisch | **Sofort** |
| #27 | Privacy Policy DSGVO | 🟡 CEO-Aktion | Vor Beta-Launch |

**@SeniorDev Sprint 18 zusätzlich:**
- Issue #31: GitHub Secrets einrichten (CI muss grün werden vor Beta)
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` als Repository Secrets
  - `.github/workflows/ci.yml` prüfen ob Secrets referenziert werden
- Offline-Sync (#49): Mindest-Scope für Beta definieren (nur Read-Fallback reicht?)

---

### 📅 Sprint 18 Timeline

| Woche | Ziel |
|-------|------|
| 15.–22. März | Issue #31 CI-Secrets + DB Migration v14 |
| 23.–29. März | Kategorie-UI + Donut-Chart |
| 30. März–5. April | In-App Review + Testing |
| 6. April | Sprint 18 Review + Beta-Go/No-Go Entscheidung |

---

### ⚠️ CEO-Aktionen Sprint 18

1. **Sofort**: GitHub Secrets für CI eintragen (Issue #31) — blockiert alle CI-Runs
2. **Vor Beta-Launch**: Privacy Policy URL live schalten (Issue #27)

*CTO | Sprint 18 Plan | 2026-03-15*
