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
