import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/expenses/repositories/expense_repository.dart';
import '../helpers/mock_helpers.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late MockTransaction mockTxn;
  late ExpenseRepository repo;

  final now = DateTime(2024, 1, 15);
  final testExpenseMap = {
    'id': 'e1',
    'description': 'Lunch',
    'amount': 25.50,
    'paid_by_id': 'm1',
    'group_id': 'g1',
    'created_at': now.toIso8601String(),
    'expense_date': now.toIso8601String(),
    'category': 'food',
    'split_type': 'equal',
    'currency': 'USD',
    'updated_at': now.toIso8601String(),
    'sync_status': 'synced',
  };

  final testSplitMap = {
    'id': 's1',
    'expense_id': 'e1',
    'member_id': 'm1',
    'amount': 12.75,
  };

  final testPayerMap = {
    'id': 'p1',
    'expense_id': 'e1',
    'member_id': 'm1',
    'amount': 25.50,
  };

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();
    mockTxn = MockTransaction();
    mockDatabase.mockTransaction = mockTxn;

    repo = ExpenseRepository(
      db: mockDb,
      api: mockApi,
      connectivity: mockConnectivity,
    );

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit(noResult: true)).thenAnswer((_) async => []);
  });

  group('getExpensesByGroup', () {
    test('online: calls api.select with correct params', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('expenses',
              filters: {'group_id': 'g1'}, orderBy: 'created_at'))
          .thenAnswer((_) async => [testExpenseMap]);
      when(() => mockDatabase.query('expenses',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testExpenseMap]);

      final result = await repo.getExpensesByGroup('g1');

      verify(() => mockApi.select('expenses',
          filters: {'group_id': 'g1'}, orderBy: 'created_at')).called(1);
      expect(result, hasLength(1));
      expect(result.first.description, 'Lunch');
      expect(result.first.amount, 25.50);
    });

    test('offline: reads from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.query('expenses',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testExpenseMap]);

      final result = await repo.getExpensesByGroup('g1');

      expect(result, hasLength(1));
    });
  });

  group('insertExpense', () {
    test('online: calls api.rpc with upsert_expense', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.rpc<void>('upsert_expense', params: any(named: 'params')))
          .thenAnswer((_) async {});
      when(() => mockTxn.insert('expenses', any()))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.insert('expense_splits', any()))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.insert('expense_payers', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'expenses',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final expense = Expense(
        id: 'e1',
        description: 'Lunch',
        amountCents: 2550,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: now,
      );
      final split = ExpenseSplit(
        id: 's1',
        expenseId: 'e1',
        memberId: 'm2',
        amountCents: 1275,
      );
      final payer = ExpensePayer(
        id: 'p1',
        expenseId: 'e1',
        memberId: 'm1',
        amountCents: 2550,
      );

      await repo.insertExpense(expense, [split], payers: [payer]);

      final captured = verify(() => mockApi.rpc<void>('upsert_expense',
              params: captureAny(named: 'params')))
          .captured
          .single as Map<String, dynamic>;
      expect(captured.containsKey('p_expense'), isTrue);
      expect(captured.containsKey('p_splits'), isTrue);
      expect(captured.containsKey('p_payers'), isTrue);
    });

    test('offline: writes to SQLite only via transaction', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockTxn.insert('expenses', any()))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.insert('expense_splits', any()))
          .thenAnswer((_) async => 1);

      final expense = Expense(
        id: 'e2',
        description: 'Dinner',
        amountCents: 4000,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: now,
      );
      final split = ExpenseSplit(
        id: 's2',
        expenseId: 'e2',
        memberId: 'm2',
        amountCents: 2000,
      );

      await repo.insertExpense(expense, [split]);

      verifyNever(
          () => mockApi.rpc<void>(any(), params: any(named: 'params')));
      verify(() => mockTxn.insert('expenses', any())).called(1);
      verify(() => mockTxn.insert('expense_splits', any())).called(1);
    });
  });

  group('updateExpense', () {
    test('online: calls api.rpc and updates SQLite via transaction', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.rpc<void>('upsert_expense', params: any(named: 'params')))
          .thenAnswer((_) async {});
      when(() => mockTxn.update('expenses', any(),
              where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.delete('expense_splits',
              where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.delete('expense_payers',
              where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
          .thenAnswer((_) async => 1);
      when(() => mockTxn.insert('expense_splits', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'expenses',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final expense = Expense(
        id: 'e1',
        description: 'Updated Lunch',
        amountCents: 3000,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: now,
      );
      final split = ExpenseSplit(
        id: 's1',
        expenseId: 'e1',
        memberId: 'm2',
        amountCents: 1500,
      );

      await repo.updateExpense(expense, [split]);

      verify(() =>
              mockApi.rpc<void>('upsert_expense', params: any(named: 'params')))
          .called(1);
    });
  });

  group('getSplitsByExpense', () {
    test('online: fetches from api and caches', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() =>
              mockApi.select('expense_splits', filters: {'expense_id': 'e1'}))
          .thenAnswer((_) async => [testSplitMap]);
      when(() => mockDatabase.query('expense_splits',
              where: 'expense_id = ?', whereArgs: ['e1']))
          .thenAnswer((_) async => [testSplitMap]);

      final result = await repo.getSplitsByExpense('e1');

      expect(result, hasLength(1));
      expect(result.first.amount, 12.75);
    });
  });

  group('getPayersByExpense', () {
    test('online: fetches from api and caches', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() =>
              mockApi.select('expense_payers', filters: {'expense_id': 'e1'}))
          .thenAnswer((_) async => [testPayerMap]);
      when(() => mockDatabase.query('expense_payers',
              where: 'expense_id = ?', whereArgs: ['e1']))
          .thenAnswer((_) async => [testPayerMap]);

      final result = await repo.getPayersByExpense('e1');

      expect(result, hasLength(1));
      expect(result.first.amount, 25.50);
    });
  });

  group('getSplitsByGroup', () {
    test('online: calls correct Supabase view', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('expense_splits_by_group',
              filters: {'group_id': 'g1'}))
          .thenAnswer((_) async => [testSplitMap]);
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [testSplitMap]);

      final result = await repo.getSplitsByGroup('g1');

      verify(() => mockApi.select('expense_splits_by_group',
          filters: {'group_id': 'g1'})).called(1);
      expect(result, hasLength(1));
    });
  });

  group('getPayersByGroup', () {
    test('online: calls correct Supabase view', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('expense_payers_by_group',
              filters: {'group_id': 'g1'}))
          .thenAnswer((_) async => [testPayerMap]);
      when(() => mockDatabase.rawQuery(any(), any()))
          .thenAnswer((_) async => [testPayerMap]);

      final result = await repo.getPayersByGroup('g1');

      verify(() => mockApi.select('expense_payers_by_group',
          filters: {'group_id': 'g1'})).called(1);
      expect(result, hasLength(1));
    });
  });

  group('deleteExpense', () {
    test('online: calls api.delete and SQLite delete', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.delete('expenses', 'e1')).thenAnswer((_) async {});
      when(() => mockDatabase.delete('expenses',
              where: 'id = ?', whereArgs: ['e1']))
          .thenAnswer((_) async => 1);

      await repo.deleteExpense('e1');

      verify(() => mockApi.delete('expenses', 'e1')).called(1);
    });
  });

  group('memberHasExpenses', () {
    test('online: calls RPC and returns result', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.rpc<bool>('member_has_expenses',
              params: {'p_member_id': 'm1'}))
          .thenAnswer((_) async => true);

      final result = await repo.memberHasExpenses('m1');

      expect(result, isTrue);
      verify(() => mockApi.rpc<bool>('member_has_expenses',
          params: {'p_member_id': 'm1'})).called(1);
    });

    test('online RPC error: falls back to SQLite 3-table check', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.rpc<bool>('member_has_expenses',
              params: {'p_member_id': 'm1'}))
          .thenThrow(Exception('RPC error'));
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expenses WHERE paid_by_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 0}]);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expense_payers WHERE member_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 0}]);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expense_splits WHERE member_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 1}]);

      final result = await repo.memberHasExpenses('m1');

      expect(result, isTrue);
    });

    test('offline: checks all 3 SQLite tables', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expenses WHERE paid_by_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 0}]);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expense_payers WHERE member_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 0}]);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expense_splits WHERE member_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 0}]);

      final result = await repo.memberHasExpenses('m1');

      expect(result, isFalse);
      verifyNever(
          () => mockApi.rpc<bool>(any(), params: any(named: 'params')));
    });

    test('SQLite fallback: returns true on first match (expenses)', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.rawQuery(
              'SELECT COUNT(*) as count FROM expenses WHERE paid_by_id = ?',
              ['m1']))
          .thenAnswer((_) async => [{'count': 2}]);

      final result = await repo.memberHasExpenses('m1');

      expect(result, isTrue);
      // Should short-circuit, not check other tables
      verifyNever(() => mockDatabase.rawQuery(
          'SELECT COUNT(*) as count FROM expense_payers WHERE member_id = ?',
          any()));
    });
  });
}
