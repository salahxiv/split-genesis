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
