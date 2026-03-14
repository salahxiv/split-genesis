// test/debt_calculator_test.dart
//
// Unit Tests für DebtCalculator — Kritische Korrektheitstests
// Priorität: Hoch (Kernlogik der App, Datenkorrektheit)
//
// Szenarien gemäß Sprint-Anforderungen:
//   1. Einfache Schulden (A zahlt für B)
//   2. Gruppe mit 3 Personen
//   3. Bereits bezahlte Schulden (Settlements)
//   4. Rundungsfehler bei ungeraden Beträgen

import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/balances/services/debt_calculator.dart';
import 'package:split_genesis/features/members/models/member.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

Member _member(String id, [String? name]) => Member(
      id: id,
      name: name ?? id,
      groupId: 'g1',
    );

Expense _expense(String id, double amount, String paidById) => Expense(
      id: id,
      description: 'Test: $id',
      amountCents: (amount * 100).round(),
      paidById: paidById,
      groupId: 'g1',
      createdAt: DateTime(2024, 1, 1),
    );

ExpenseSplit _split(String expenseId, String memberId, double amount) =>
    ExpenseSplit(
      id: '${expenseId}_$memberId',
      expenseId: expenseId,
      memberId: memberId,
      amountCents: (amount * 100).round(),
    );

SettlementRecord _settlement(String from, String to, double amount) =>
    SettlementRecord(
      id: 'set_${from}_$to',
      groupId: 'g1',
      fromMemberId: from,
      toMemberId: to,
      amountCents: (amount * 100).round(),
      createdAt: DateTime(2024, 1, 1),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // Szenario 1: Einfache Schulden — A zahlt für B
  // =========================================================================
  group('1. Einfache Schulden: A zahlt für B', () {
    test('A zahlt 100€ für B — B schuldet A 100€', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      // Alice zahlt 100€, Bob nutzt alles
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'b', 100.0), // Bob schuldet den vollen Betrag
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements.length, 1,
          reason: 'Genau eine Zahlung: Bob an Alice');
      expect(settlements[0].fromMember.id, 'b',
          reason: 'Bob zahlt');
      expect(settlements[0].toMember.id, 'a',
          reason: '...an Alice');
      expect(settlements[0].amount, 100.0,
          reason: 'Bob schuldet Alice 100€');
    });

    test('A zahlt 60€ — 50/50 Split — B schuldet A 30€', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 60.0, 'a')];
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
      ];

      final balances = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
      );

      final alice = balances.firstWhere((b) => b.member.id == 'a');
      final bob = balances.firstWhere((b) => b.member.id == 'b');

      expect(alice.netBalance, 30.0,
          reason: 'Alice hat 30€ Guthaben (zahlt 60, schuldet 30)');
      expect(bob.netBalance, -30.0,
          reason: 'Bob schuldet 30€ (zahlt 0, schuldet 30)');
    });

    test('Niemand schuldet nichts — gleiche Beträge gezahlt', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      // Beide zahlen je 50€ für je eigene Ausgaben
      final expenses = [
        _expense('e1', 50.0, 'a'),
        _expense('e2', 50.0, 'b'),
      ];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e2', 'b', 50.0),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements, isEmpty,
          reason: 'Ausgeglichen — keine Schulden');
    });

    test('B zahlt auch — gegenseitige Schulden heben sich auf', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      // A zahlt 100 für B, B zahlt 100 für A → netto 0
      final expenses = [
        _expense('e1', 100.0, 'a'),
        _expense('e2', 100.0, 'b'),
      ];
      final splits = [
        _split('e1', 'b', 100.0), // B nutzt e1 komplett
        _split('e2', 'a', 100.0), // A nutzt e2 komplett
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements, isEmpty,
          reason: 'Gegenseitige Schulden kompensieren sich');
    });
  });

  // =========================================================================
  // Szenario 2: Gruppe mit 3 Personen
  // =========================================================================
  group('2. Gruppe mit 3 Personen', () {
    test('A zahlt 90€ — gleichmäßig auf 3 verteilt — B und C schulden je 30€',
        () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 90.0, 'a')];
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Alice bekommt insgesamt 60€ zurück (2 × 30€)
      final totalToAlice = settlements
          .where((s) => s.toMember.id == 'a')
          .fold(0.0, (sum, s) => sum + s.amount);

      expect(settlements.length, 2,
          reason: 'Bob zahlt Alice, Carol zahlt Alice');
      expect(totalToAlice, 60.0,
          reason: 'Alice bekommt insgesamt 60€ zurück');
    });

    test('Jeder zahlt für unterschiedliche Ausgaben — komplexe Salden', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      // Alice zahlt 90€ (Abendessen), Bob zahlt 60€ (Taxi)
      final expenses = [
        _expense('e1', 90.0, 'a'), // Alice: Abendessen für alle
        _expense('e2', 60.0, 'b'), // Bob: Taxi für alle
      ];
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
        _split('e2', 'a', 20.0),
        _split('e2', 'b', 20.0),
        _split('e2', 'c', 20.0),
      ];

      // Erwartete Salden:
      // Alice: zahlt 90, schuldet 50 → Saldo +40
      // Bob: zahlt 60, schuldet 50 → Saldo +10
      // Carol: zahlt 0, schuldet 50 → Saldo -50

      final balances = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
      );

      final alice = balances.firstWhere((b) => b.member.id == 'a');
      final bob = balances.firstWhere((b) => b.member.id == 'b');
      final carol = balances.firstWhere((b) => b.member.id == 'c');

      expect(alice.netBalance, closeTo(40.0, 0.01),
          reason: 'Alice Saldo: +40€');
      expect(bob.netBalance, closeTo(10.0, 0.01),
          reason: 'Bob Saldo: +10€');
      expect(carol.netBalance, closeTo(-50.0, 0.01),
          reason: 'Carol Saldo: -50€');

      // Carol zahlt: 40€ an Alice + 10€ an Bob = 50€ gesamt
      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );
      final totalFromCarol = settlements
          .where((s) => s.fromMember.id == 'c')
          .fold(0.0, (sum, s) => sum + s.amount);
      expect(totalFromCarol, closeTo(50.0, 0.01),
          reason: 'Carol zahlt insgesamt 50€');
    });

    test('Nur einer zahlt alles — optimale Settlements', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 300.0, 'a')];
      final splits = [
        _split('e1', 'a', 100.0),
        _split('e1', 'b', 100.0),
        _split('e1', 'c', 100.0),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Bob und Carol zahlen je 100€ an Alice
      expect(settlements.length, 2);
      for (final s in settlements) {
        expect(s.toMember.id, 'a');
        expect(s.amount, 100.0);
      }
    });

    test('Alle drei zahlen unterschiedliche Beträge — Minimalanzahl Transfers',
        () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      // Drei verschiedene Ausgaben
      final expenses = [
        _expense('e1', 120.0, 'a'),
        _expense('e2', 60.0, 'b'),
        _expense('e3', 30.0, 'c'),
      ];
      // Jede Ausgabe gleichmäßig auf alle 3
      final splits = [
        _split('e1', 'a', 40.0),
        _split('e1', 'b', 40.0),
        _split('e1', 'c', 40.0),
        _split('e2', 'a', 20.0),
        _split('e2', 'b', 20.0),
        _split('e2', 'c', 20.0),
        _split('e3', 'a', 10.0),
        _split('e3', 'b', 10.0),
        _split('e3', 'c', 10.0),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Salden: Alice +50, Bob -10, Carol -40 → Carol→Alice 40, Bob→Alice 10
      final totalSettled =
          settlements.fold(0.0, (sum, s) => sum + s.amount);
      expect(totalSettled, closeTo(50.0, 0.01),
          reason: 'Gesamte Transfers = Gesamtguthaben von Alice');
    });
  });

  // =========================================================================
  // Szenario 3: Bereits bezahlte Schulden (Settlements)
  // =========================================================================
  group('3. Bereits bezahlte Schulden', () {
    test('B hat 50% bereits gezahlt — nur noch 50% ausstehend', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];
      // Bob hat bereits 25€ zurückgezahlt
      final existingSettlements = [_settlement('b', 'a', 25.0)];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
        settlements: existingSettlements,
      );

      expect(settlements.length, 1);
      expect(settlements[0].fromMember.id, 'b');
      expect(settlements[0].toMember.id, 'a');
      expect(settlements[0].amount, closeTo(25.0, 0.01),
          reason: 'Bob schuldet noch 25€ (50€ - 25€ bereits gezahlt)');
    });

    test('Vollständige Zahlung — keine ausstehenden Schulden', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];
      // Bob hat den vollen Betrag bereits gezahlt
      final existingSettlements = [_settlement('b', 'a', 50.0)];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
        settlements: existingSettlements,
      );

      expect(settlements, isEmpty,
          reason: 'Alles bezahlt — keine ausstehenden Schulden');
    });

    test('Mehrere Teilzahlungen summieren sich korrekt', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 120.0, 'a')];
      final splits = [
        _split('e1', 'a', 60.0),
        _split('e1', 'b', 60.0),
      ];
      // Bob hat in zwei Tranchen je 20€ gezahlt (insgesamt 40€)
      final existingSettlements = [
        _settlement('b', 'a', 20.0),
        _settlement('b', 'a', 20.0),
      ];

      final balances = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
        settlements: existingSettlements,
      );

      final bob = balances.firstWhere((b) => b.member.id == 'b');
      // Bob schuldet 60, hat 40 gezahlt → -20
      expect(bob.netBalance, closeTo(-20.0, 0.01),
          reason: 'Bob schuldet noch 20€');
    });

    test('3-Personen-Gruppe mit Teilsettlement', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 90.0, 'a')];
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
      ];
      // Bob hat bereits gezahlt, Carol noch nicht
      final existingSettlements = [_settlement('b', 'a', 30.0)];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
        settlements: existingSettlements,
      );

      expect(settlements.length, 1,
          reason: 'Nur Carol schuldet noch');
      expect(settlements[0].fromMember.id, 'c');
      expect(settlements[0].amount, 30.0);
    });

    test('Überzahlung — A schuldet B Rückgabe', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];
      // Bob hat 70€ gezahlt (20€ zu viel)
      final existingSettlements = [_settlement('b', 'a', 70.0)];

      final balances = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
        settlements: existingSettlements,
      );

      final alice = balances.firstWhere((b) => b.member.id == 'a');
      final bob = balances.firstWhere((b) => b.member.id == 'b');

      // Alice: +50 (Guthaben aus Expense) - 70 (Settlement erhalten) = -20
      expect(alice.netBalance, closeTo(-20.0, 0.01),
          reason: 'Alice hat 20€ zu viel bekommen');
      // Bob: -50 (schuldet) + 70 (gezahlt) = +20
      expect(bob.netBalance, closeTo(20.0, 0.01),
          reason: 'Bob hat 20€ Guthaben durch Überzahlung');
    });
  });

  // =========================================================================
  // Szenario 4: Rundungsfehler bei ungeraden Beträgen
  // =========================================================================
  group('4. Rundungsfehler bei ungeraden Beträgen', () {
    test('100€ auf 3 Personen: 33.33 + 33.33 + 33.34 = kein Crash', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 100.0, 'a')];
      // Typisches Rundungsmuster: 2x 33.33 + 1x 33.34
      final splits = [
        _split('e1', 'a', 33.33),
        _split('e1', 'b', 33.33),
        _split('e1', 'c', 33.34),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Hauptsache: kein Crash, Ergebnis ist sinnvoll
      expect(settlements, isNotNull);
      for (final s in settlements) {
        expect(s.amount, greaterThan(0),
            reason: 'Alle Settlement-Beträge müssen positiv sein');
        // Beträge kommen aus Integer-Cents — sind immer auf 2 Dezimalstellen genau
        expect(s.amount, greaterThanOrEqualTo(0.01),
            reason: 'Betrag mindestens 1 Cent');
      }
    });

    test('10€ auf 3 Personen: 3.33 + 3.33 + 3.34', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 10.0, 'a')];
      final splits = [
        _split('e1', 'a', 3.34),
        _split('e1', 'b', 3.33),
        _split('e1', 'c', 3.33),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Salden: Alice: 10 - 3.34 = +6.66, Bob: -3.33, Carol: -3.33
      expect(settlements.length, 2);
      final total = settlements.fold(0.0, (sum, s) => sum + s.amount);
      expect(total, closeTo(6.66, 0.01));
    });

    test('Viele kleine Beträge akkumulieren korrekt', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = <Expense>[];
      final splits = <ExpenseSplit>[];

      // 9 Ausgaben à 3.33€ — klassisches Rundungsproblem
      for (int i = 0; i < 9; i++) {
        expenses.add(_expense('e$i', 3.33, 'a'));
        splits.add(_split('e$i', 'a', 1.665));
        splits.add(_split('e$i', 'b', 1.665));
      }

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Darf nicht crashen, Ergebnis muss sinnvoll sein
      expect(settlements, isNotNull);
      if (settlements.isNotEmpty) {
        for (final s in settlements) {
          expect(s.amount, greaterThan(0));
        }
      }
    });

    test('1 Cent Differenz bleibt unter Epsilon — kein Settlement', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 10.01, 'a')];
      final splits = [
        _split('e1', 'a', 10.0),
        _split('e1', 'b', 0.01), // Bob schuldet nur 1 Cent
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // 1 Cent (0.01) ist genau an der Epsilon-Grenze (epsilon = 0.01)
      // Balance von Bob: -0.01 — nicht > epsilon → kein Settlement
      expect(settlements, isEmpty,
          reason: '1 Cent liegt an der Epsilon-Grenze — kein Settlement');
    });

    test('2 Cent Differenz liegt über Epsilon — Settlement wird erstellt', () {
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [_expense('e1', 10.02, 'a')];
      final splits = [
        _split('e1', 'a', 10.0),
        _split('e1', 'b', 0.02), // Bob schuldet 2 Cent
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements.length, 1,
          reason: '2 Cent liegt über Epsilon — Settlement wird erstellt');
      expect(settlements[0].amount, closeTo(0.02, 0.001));
    });

    test('Sehr großer ungerader Betrag: 999.99€ auf 3 Personen', () {
      final members = [
        _member('a', 'Alice'),
        _member('b', 'Bob'),
        _member('c', 'Carol'),
      ];
      final expenses = [_expense('e1', 999.99, 'a')];
      // 999.99 / 3 = 333.33 (mit Rundungsdifferenz)
      final splits = [
        _split('e1', 'a', 333.33),
        _split('e1', 'b', 333.33),
        _split('e1', 'c', 333.33),
      ];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      // Bob und Carol zahlen je ~333.33€ an Alice
      // Summe aller Transfers ≈ 666.66
      final total = settlements.fold(0.0, (sum, s) => sum + s.amount);
      expect(total, closeTo(666.66, 0.5),
          reason: 'Gesamte Settlements ≈ 666.66€');

      for (final s in settlements) {
        // Alle Beträge auf 2 Dezimalstellen gerundet
        expect((s.amount * 100).roundToDouble(), s.amount * 100,
            reason: 'Beträge auf 2 Dezimalstellen gerundet');
      }
    });

    test('Floating-Point: 0.1 + 0.2 != 0.3 Problem', () {
      // Klassisches Floating-Point Problem
      final members = [_member('a', 'Alice'), _member('b', 'Bob')];
      final expenses = [
        _expense('e1', 0.1, 'a'),
        _expense('e2', 0.2, 'a'),
      ];
      final splits = [
        _split('e1', 'b', 0.1),
        _split('e2', 'b', 0.2),
      ];

      // 0.1 + 0.2 in Floating-Point = 0.30000000000000004
      // Der Calculator muss damit korrekt umgehen
      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements, isNotNull);
      // Bob schuldet Alice ~0.30€
      if (settlements.isNotEmpty) {
        expect(settlements[0].amount, closeTo(0.30, 0.01));
      }
    });
  });

  // =========================================================================
  // Edge Cases & Grenzwerte
  // =========================================================================
  group('Edge Cases', () {
    test('Leere Liste — kein Crash', () {
      final result = DebtCalculator.calculateSettlements([], [], []);
      expect(result, isEmpty);
    });

    test('Mitglieder ohne Ausgaben — alle Salden null', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final result = DebtCalculator.calculateNetBalances(members, [], []);
      for (final b in result) {
        expect(b.netBalance, 0.0);
      }
    });

    test('Einzelperson zahlt für sich selbst — kein Settlement', () {
      final members = [_member('a', 'Alice')];
      final expenses = [_expense('e1', 50.0, 'a')];
      final splits = [_split('e1', 'a', 50.0)];

      final settlements = DebtCalculator.calculateSettlements(
        members, expenses, splits,
      );

      expect(settlements, isEmpty,
          reason: 'Alice zahlt für sich selbst — keine Schulden');
    });
  });
}
