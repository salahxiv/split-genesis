import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';

void main() {
  group('Expense model', () {
    late Expense testExpense;

    setUp(() {
      testExpense = Expense(
        id: 'exp-1',
        description: 'Dinner',
        amount: 50.0,
        paidById: 'member-1',
        groupId: 'group-1',
        createdAt: DateTime(2024, 1, 15),
        expenseDate: DateTime(2024, 1, 14),
        category: 'food',
        splitType: 'equal',
        currency: 'EUR',
        syncStatus: 'synced',
      );
    });

    test('toMap() includes all fields', () {
      final map = testExpense.toMap();

      expect(map['id'], 'exp-1');
      expect(map['description'], 'Dinner');
      expect(map['amount'], 50.0);
      expect(map['paid_by_id'], 'member-1');
      expect(map['group_id'], 'group-1');
      expect(map['category'], 'food');
      expect(map['split_type'], 'equal');
      expect(map['currency'], 'EUR');
      expect(map['sync_status'], 'synced');
      expect(map['expense_date'], isNotNull);
    });

    test('toApiMap() removes sync_status', () {
      final apiMap = testExpense.toApiMap();

      expect(apiMap.containsKey('sync_status'), isFalse);
      expect(apiMap['id'], 'exp-1');
      expect(apiMap['amount'], 50.0);
      expect(apiMap['currency'], 'EUR');
    });

    test('fromMap() parses correctly', () {
      final map = testExpense.toMap();
      final restored = Expense.fromMap(map);

      expect(restored.id, testExpense.id);
      expect(restored.description, testExpense.description);
      expect(restored.amount, testExpense.amount);
      expect(restored.paidById, testExpense.paidById);
      expect(restored.category, testExpense.category);
      expect(restored.currency, testExpense.currency);
      expect(restored.expenseDate, testExpense.expenseDate);
    });

    test('expenseDate defaults to createdAt', () {
      final expense = Expense(
        id: 'e2',
        description: 'Test',
        amount: 10.0,
        paidById: 'p1',
        groupId: 'g1',
        createdAt: DateTime(2024, 3, 1),
      );

      expect(expense.expenseDate, DateTime(2024, 3, 1));
    });

    test('fromMap() defaults for missing optional fields', () {
      final map = {
        'id': 'e3',
        'description': 'Minimal',
        'amount': 25.0,
        'paid_by_id': 'p1',
        'group_id': 'g1',
        'created_at': '2024-01-01T00:00:00.000',
      };
      final expense = Expense.fromMap(map);

      expect(expense.category, 'general');
      expect(expense.splitType, 'equal');
      expect(expense.currency, 'USD');
      expect(expense.syncStatus, 'pending');
    });
  });

  group('Expense model edge cases', () {
    test('zero amount expense', () {
      final expense = Expense(
        id: 'e-zero',
        description: 'Free',
        amount: 0.0,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.amount, 0.0);
    });

    test('negative amount (refund)', () {
      final expense = Expense(
        id: 'e-neg',
        description: 'Refund',
        amount: -25.50,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.amount, -25.50);
    });

    test('very large amount', () {
      final expense = Expense(
        id: 'e-big',
        description: 'Big expense',
        amount: 999999.99,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.amount, 999999.99);
    });

    test('amount as integer from Supabase (50 not 50.0)', () {
      final map = {
        'id': 'e-int',
        'description': 'Integer amount',
        'amount': 50, // int, not double
        'paid_by_id': 'm1',
        'group_id': 'g1',
        'created_at': '2024-01-01T00:00:00.000',
      };
      final expense = Expense.fromMap(map);
      expect(expense.amount, 50.0);
      expect(expense.amount, isA<double>());
    });

    test('expenseDate before createdAt (backdated)', () {
      final expense = Expense(
        id: 'e-back',
        description: 'Backdated',
        amount: 10.0,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 6, 15),
        expenseDate: DateTime(2024, 1, 1),
      );
      expect(expense.expenseDate.isBefore(expense.createdAt), isTrue);
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.expenseDate, DateTime(2024, 1, 1));
    });

    test('expenseDate in the future', () {
      final futureDate = DateTime(2099, 12, 31);
      final expense = Expense(
        id: 'e-future',
        description: 'Future',
        amount: 10.0,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 1, 1),
        expenseDate: futureDate,
      );
      final restored = Expense.fromMap(expense.toMap());
      expect(restored.expenseDate, futureDate);
    });

    test('all split types serialize correctly', () {
      for (final type in ['equal', 'exact', 'percent', 'shares']) {
        final expense = Expense(
          id: 'e-$type',
          description: 'Split $type',
          amount: 100.0,
          paidById: 'm1',
          groupId: 'g1',
          createdAt: DateTime(2024, 1, 1),
          splitType: type,
        );
        final restored = Expense.fromMap(expense.toMap());
        expect(restored.splitType, type);
      }
    });

    test('missing expense_date in map defaults to createdAt', () {
      final map = {
        'id': 'e-nodate',
        'description': 'No date',
        'amount': 10.0,
        'paid_by_id': 'm1',
        'group_id': 'g1',
        'created_at': '2024-03-15T10:00:00.000',
      };
      final expense = Expense.fromMap(map);
      expect(expense.expenseDate, expense.createdAt);
    });

    test('ExpenseSplit with zero amount', () {
      final split = ExpenseSplit(
        id: 's-zero',
        expenseId: 'e1',
        memberId: 'm1',
        amount: 0.0,
      );
      final restored = ExpenseSplit.fromMap(split.toMap());
      expect(restored.amount, 0.0);
    });

    test('ExpensePayer with zero amount', () {
      final payer = ExpensePayer(
        id: 'p-zero',
        expenseId: 'e1',
        memberId: 'm1',
        amount: 0.0,
      );
      final restored = ExpensePayer.fromMap(payer.toMap());
      expect(restored.amount, 0.0);
    });
  });

  group('ExpenseSplit model', () {
    test('toMap() and fromMap() roundtrip', () {
      final split = ExpenseSplit(
        id: 'split-1',
        expenseId: 'exp-1',
        memberId: 'member-1',
        amount: 25.0,
      );

      final map = split.toMap();
      expect(map['id'], 'split-1');
      expect(map['expense_id'], 'exp-1');
      expect(map['member_id'], 'member-1');
      expect(map['amount'], 25.0);

      final restored = ExpenseSplit.fromMap(map);
      expect(restored.id, split.id);
      expect(restored.amount, split.amount);
    });

    test('fromMap() handles int amount', () {
      final map = {
        'id': 's1',
        'expense_id': 'e1',
        'member_id': 'm1',
        'amount': 10,
      };
      final split = ExpenseSplit.fromMap(map);
      expect(split.amount, 10.0);
      expect(split.amount, isA<double>());
    });
  });

  group('ExpensePayer model', () {
    test('toMap() and fromMap() roundtrip', () {
      final payer = ExpensePayer(
        id: 'payer-1',
        expenseId: 'exp-1',
        memberId: 'member-1',
        amount: 50.0,
      );

      final map = payer.toMap();
      expect(map['id'], 'payer-1');
      expect(map['expense_id'], 'exp-1');
      expect(map['member_id'], 'member-1');
      expect(map['amount'], 50.0);

      final restored = ExpensePayer.fromMap(map);
      expect(restored.id, payer.id);
      expect(restored.amount, payer.amount);
    });
  });
}
