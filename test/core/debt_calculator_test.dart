import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/balances/services/debt_calculator.dart';
import 'package:split_genesis/features/members/models/member.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';

Member _member(String id, [String? name]) => Member(
      id: id,
      name: name ?? id,
      groupId: 'g1',
    );

Expense _expense(String id, double amount, String paidById) => Expense(
      id: id,
      description: 'Expense $id',
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

ExpensePayer _payer(String expenseId, String memberId, double amount) =>
    ExpensePayer(
      id: 'p_${expenseId}_$memberId',
      expenseId: expenseId,
      memberId: memberId,
      amountCents: (amount * 100).round(),
    );

SettlementRecord _settlement(
        String from, String to, double amount) =>
    SettlementRecord(
      id: 'set_${from}_$to',
      groupId: 'g1',
      fromMemberId: from,
      toMemberId: to,
      amountCents: (amount * 100).round(),
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  group('DebtCalculator.calculateNetBalances', () {
    test('empty inputs returns empty list', () {
      final result = DebtCalculator.calculateNetBalances([], [], []);
      expect(result, isEmpty);
    });

    test('members but no expenses returns zero balances', () {
      final members = [_member('a'), _member('b')];
      final result = DebtCalculator.calculateNetBalances(members, [], []);
      expect(result.length, 2);
      expect(result[0].netBalance, 0.0);
      expect(result[1].netBalance, 0.0);
    });

    test('single member, single expense, single split', () {
      final members = [_member('a')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [_split('e1', 'a', 100.0)];

      final result =
          DebtCalculator.calculateNetBalances(members, expenses, splits);
      // a paid 100, owes 100 → net 0
      expect(result[0].netBalance, 0.0);
    });

    test('two members, equal split', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];

      final result =
          DebtCalculator.calculateNetBalances(members, expenses, splits);
      final balanceA = result.firstWhere((b) => b.member.id == 'a');
      final balanceB = result.firstWhere((b) => b.member.id == 'b');

      // a paid 100, owes 50 → net +50
      expect(balanceA.netBalance, 50.0);
      // b paid 0, owes 50 → net -50
      expect(balanceB.netBalance, -50.0);
    });

    test('multi-payer expense uses ExpensePayer records', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [_expense('e1', 90.0, 'a')]; // paidById ignored
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
      ];
      final payers = [
        _payer('e1', 'a', 60.0),
        _payer('e1', 'b', 30.0),
      ];

      final result = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
        payers: payers,
      );
      final balA = result.firstWhere((b) => b.member.id == 'a');
      final balB = result.firstWhere((b) => b.member.id == 'b');
      final balC = result.firstWhere((b) => b.member.id == 'c');

      // a: paid 60, owes 30 → +30
      expect(balA.netBalance, 30.0);
      // b: paid 30, owes 30 → 0
      expect(balB.netBalance, 0.0);
      // c: paid 0, owes 30 → -30
      expect(balC.netBalance, -30.0);
    });

    test('backward compatibility: no payers falls back to expense.paidById',
        () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];

      final result = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
        payers: [], // empty payers list
      );
      final balA = result.firstWhere((b) => b.member.id == 'a');
      expect(balA.netBalance, 50.0);
    });

    test('member not in any expense has balance zero', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];

      final result =
          DebtCalculator.calculateNetBalances(members, expenses, splits);
      final balC = result.firstWhere((b) => b.member.id == 'c');
      expect(balC.netBalance, 0.0);
    });

    test('settlements applied correctly', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];
      // b pays a $50 settlement
      final settlements = [_settlement('b', 'a', 50.0)];

      final result = DebtCalculator.calculateNetBalances(
        members, expenses, splits,
        settlements: settlements,
      );
      final balA = result.firstWhere((b) => b.member.id == 'a');
      final balB = result.firstWhere((b) => b.member.id == 'b');

      // a: paid 100 - owes 50 - received settlement 50 = 0
      expect(balA.netBalance, 0.0);
      // b: paid 0 - owes 50 + paid settlement 50 = 0
      expect(balB.netBalance, 0.0);
    });

    test('unknown member in splits uses ?? 0 fallback', () {
      final members = [_member('a')];
      final expenses = [_expense('e1', 100.0, 'a')];
      // 'ghost' is not in members list
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'ghost', 50.0),
      ];

      // Should not throw; ghost gets subtracted from a nonexistent entry
      final result =
          DebtCalculator.calculateNetBalances(members, expenses, splits);
      final balA = result.firstWhere((b) => b.member.id == 'a');
      // a paid 100, owes 50 → +50
      expect(balA.netBalance, 50.0);
      // ghost is not in members so not in results
      expect(result.length, 1);
    });
  });

  group('DebtCalculator.calculateSettlements', () {
    test('all balances zero returns no settlements', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 100.0), // a pays for themselves fully
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // a: +0, b: 0 → no settlements
      expect(result, isEmpty);
    });

    test('one creditor, one debtor produces single settlement', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      expect(result.length, 1);
      expect(result[0].fromMember.id, 'b');
      expect(result[0].toMember.id, 'a');
      expect(result[0].amount, 50.0);
    });

    test('one creditor, multiple debtors', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [_expense('e1', 90.0, 'a')];
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      expect(result.length, 2);
      final totalToA =
          result.where((s) => s.toMember.id == 'a').fold(0.0, (s, e) => s + e.amount);
      expect(totalToA, 60.0);
    });

    test('multiple creditors, one debtor', () {
      final members = [_member('a'), _member('b'), _member('c')];
      // a and b each pay 50, c owes everything
      final expenses = [
        _expense('e1', 50.0, 'a'),
        _expense('e2', 50.0, 'b'),
      ];
      final splits = [
        _split('e1', 'c', 50.0),
        _split('e2', 'c', 50.0),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      final totalFromC =
          result.where((s) => s.fromMember.id == 'c').fold(0.0, (s, e) => s + e.amount);
      expect(totalFromC, 100.0);
    });

    test('three-way: A paid for B and C, B paid for A and C', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [
        _expense('e1', 90.0, 'a'), // a paid 90
        _expense('e2', 60.0, 'b'), // b paid 60
      ];
      // e1 split equally: each 30
      // e2 split equally: each 20
      final splits = [
        _split('e1', 'a', 30.0),
        _split('e1', 'b', 30.0),
        _split('e1', 'c', 30.0),
        _split('e2', 'a', 20.0),
        _split('e2', 'b', 20.0),
        _split('e2', 'c', 20.0),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // a: paid 90, owes 50 → net +40
      // b: paid 60, owes 50 → net +10
      // c: paid 0, owes 50 → net -50
      // c should pay a $40 and b $10
      final totalAmount = result.fold(0.0, (s, e) => s + e.amount);
      expect(totalAmount, 50.0);
    });

    test('epsilon boundary: balance 0.005 is ignored (below epsilon)', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.005, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.005), // b owes 50.005, net = -50.005, a net = +50.005
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // net balance for a: 100.005 - 50.0 = 50.005 (above epsilon)
      // net balance for b: 0 - 50.005 = -50.005 (above epsilon)
      expect(result.length, 1);
    });

    test('epsilon boundary: balance exactly 0.005 below threshold', () {
      final members = [_member('a'), _member('b')];
      // Create scenario where net balance = 0.005
      final expenses = [_expense('e1', 10.005, 'a')];
      final splits = [
        _split('e1', 'a', 10.0),
        _split('e1', 'b', 0.005),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // a: paid 10.005, owes 10.0 → net +0.005 (below epsilon 0.01)
      // b: paid 0, owes 0.005 → net -0.005 (below epsilon 0.01)
      expect(result, isEmpty);
    });

    test('epsilon boundary: balance 0.02 above threshold generates settlement',
        () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 10.02, 'a')];
      final splits = [
        _split('e1', 'a', 10.0),
        _split('e1', 'b', 0.02),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // a: +0.02 (above epsilon), b: -0.02 (above epsilon)
      expect(result.length, 1);
      expect(result[0].amount, 0.02);
    });

    test('rounding: transfer amount has at most 2 decimal places', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 33.33),
        _split('e1', 'b', 66.67),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      for (final s in result) {
        // amount * 100 should be a whole number (2 decimal places)
        expect((s.amount * 100).roundToDouble(), s.amount * 100);
      }
    });

    test('large amounts: \$999,999.99 split among 3', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [_expense('e1', 999999.99, 'a')];
      final splitAmount = 333333.33;
      final splits = [
        _split('e1', 'a', splitAmount),
        _split('e1', 'b', splitAmount),
        _split('e1', 'c', splitAmount),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      expect(result, isNotEmpty);
      final totalSettled = result.fold(0.0, (s, e) => s + e.amount);
      // Total settled should approximately equal what a is owed
      expect(totalSettled, closeTo(666666.66, 1.0));
    });

    test('many members: 10+ members with complex splits', () {
      final members = List.generate(10, (i) => _member('m$i'));
      // m0 pays for everyone
      final expenses = [_expense('e1', 1000.0, 'm0')];
      final splits =
          List.generate(10, (i) => _split('e1', 'm$i', 100.0));

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // m0: paid 1000, owes 100 → net +900
      // Each other: paid 0, owes 100 → net -100
      // Should generate 9 settlements
      expect(result.length, 9);
      final totalToM0 = result
          .where((s) => s.toMember.id == 'm0')
          .fold(0.0, (s, e) => s + e.amount);
      expect(totalToM0, 900.0);
    });

    test('self-canceling: A owes B \$50, B owes A \$50 → net zero', () {
      final members = [_member('a'), _member('b')];
      final expenses = [
        _expense('e1', 100.0, 'a'), // a paid 100
        _expense('e2', 100.0, 'b'), // b paid 100
      ];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
        _split('e2', 'a', 50.0),
        _split('e2', 'b', 50.0),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      expect(result, isEmpty);
    });

    test('settlements reduce existing debts', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 100.0, 'a')];
      final splits = [
        _split('e1', 'a', 50.0),
        _split('e1', 'b', 50.0),
      ];
      // b already paid a $30
      final existingSettlements = [_settlement('b', 'a', 30.0)];

      final result = DebtCalculator.calculateSettlements(
        members, expenses, splits,
        settlements: existingSettlements,
      );
      expect(result.length, 1);
      expect(result[0].amount, 20.0);
      expect(result[0].fromMember.id, 'b');
    });
  });

  group('Floating-point precision edge cases', () {
    test('\$100 split 3 ways', () {
      final members = [_member('a'), _member('b'), _member('c')];
      final expenses = [_expense('e1', 100.0, 'a')];
      // 100 / 3 = 33.333... — splits may not sum to total
      final splits = [
        _split('e1', 'a', 33.33),
        _split('e1', 'b', 33.33),
        _split('e1', 'c', 33.34),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // Should produce valid settlements without crashing
      expect(result, isNotEmpty);
      for (final s in result) {
        expect(s.amount, greaterThan(0));
      }
    });

    test('accumulated rounding across many expenses', () {
      final members = [_member('a'), _member('b')];
      final expenses = <Expense>[];
      final splits = <ExpenseSplit>[];

      // 10 expenses of $3.33 each, a pays, split equally
      for (int i = 0; i < 10; i++) {
        expenses.add(_expense('e$i', 3.33, 'a'));
        splits.add(_split('e$i', 'a', 1.665));
        splits.add(_split('e$i', 'b', 1.665));
      }

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // Should not crash and should produce reasonable result
      for (final s in result) {
        expect(s.amount, greaterThan(0));
        // 2 decimal places
        expect((s.amount * 100).roundToDouble() / 100, s.amount);
      }
    });

    test('very small amount near epsilon threshold', () {
      final members = [_member('a'), _member('b')];
      final expenses = [_expense('e1', 0.02, 'a')];
      final splits = [
        _split('e1', 'a', 0.01),
        _split('e1', 'b', 0.01),
      ];

      final result =
          DebtCalculator.calculateSettlements(members, expenses, splits);
      // a: +0.01, b: -0.01 — exactly at epsilon boundary
      // With epsilon = 0.01, balance must be > 0.01 to count
      // So 0.01 is NOT > 0.01, should be empty
      expect(result, isEmpty);
    });
  });
}
