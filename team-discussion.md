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

## SeniorDev Sprint 8 — 2026-03-14

### ✅ feat: QR Code für Gruppen-Beitreten (PR #37, Issue #9)
**Branch:** `feature/qr-code-group-join`

QR-basiertes Gruppen-Beitreten implementiert als nahtlose Alternative zur manuellen Code-Eingabe.

**Neue Dependencies (pubspec.yaml):**
- `mobile_scanner: ^5.2.3` — Kamera-basierter QR-Scanner
- `qr_flutter: ^4.1.0` — QR-Code-Generierung

**deep_link_service.dart:**
- Neuer `onGroupId`-Stream + `initialGroupId`-Property für QR-Deep-Links
- `handleScannedUri()` Helper für direkte QR-String-Verarbeitung
- Neues URL-Schema: `splitgenesis://join?groupId=UUID`

**sync_service.dart:**
- `findGroupById(String groupId)` für QR-basierte Remote-Suche ergänzt

**join_group_screen.dart:**
- QR-Scanner-Button in AppBar → öffnet Vollbild-MobileScanner
- Custom ScanFrame-Overlay-Painter (gedimmte Ecken, Rahmen-Marker)
- Parst `splitgenesis://join?groupId=UUID`, löst Gruppe auf
- Graceful fallback bei ungültigem QR-Code mit Retry-Option

**add_group_screen.dart:**
- Nach Gruppen-Erstellung: QR-Code-Screen vor Navigation zur Detail-Ansicht
- `QrImageView` mit Brand-Farben (primary eye, circle data modules)
- Share-Code auch unter QR als manuelle Fallback-Option

**QR-Format:** `splitgenesis://join?groupId=<UUID>`

---

*SeniorDev | Sprint 8 | 2026-03-14*
