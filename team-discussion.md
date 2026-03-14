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
