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
