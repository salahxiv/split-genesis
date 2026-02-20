import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/groups/models/group.dart';
import 'package:split_genesis/features/members/models/member.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';
import 'package:split_genesis/features/activity/models/activity_entry.dart';

void main() {
  group('toApiMap() contract tests', () {
    test('Group.toApiMap() never contains sync_status', () {
      final group = Group(
        id: 'g1',
        name: 'Test',
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );
      final map = group.toApiMap();
      expect(map.containsKey('sync_status'), isFalse);
      expect(map.containsKey('id'), isTrue);
      expect(map.containsKey('name'), isTrue);
    });

    test('Member.toApiMap() never contains sync_status', () {
      final member = Member(
        id: 'm1',
        name: 'Alice',
        groupId: 'g1',
        syncStatus: 'synced',
      );
      final map = member.toApiMap();
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('Expense.toApiMap() never contains sync_status', () {
      final expense = Expense(
        id: 'e1',
        description: 'Test',
        amount: 10.0,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );
      final map = expense.toApiMap();
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('SettlementRecord.toApiMap() never contains sync_status', () {
      final settlement = SettlementRecord(
        id: 's1',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amount: 20.0,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );
      final map = settlement.toApiMap();
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('ActivityEntry.toApiMap() never contains sync_status', () {
      final entry = ActivityEntry(
        id: 'a1',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'Test',
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );
      final map = entry.toApiMap();
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('ActivityEntry.toApiMap() passes metadata as raw Map not JSON string', () {
      final entry = ActivityEntry(
        id: 'a2',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'Test',
        timestamp: DateTime.now(),
        metadata: {'key': 'value'},
      );
      final apiMap = entry.toApiMap();
      final sqliteMap = entry.toMap();

      // API should have raw Map for Supabase JSONB
      expect(apiMap['metadata'], isA<Map>());
      // SQLite should have JSON string
      expect(sqliteMap['metadata'], isA<String>());
    });
  });

  group('fromMap() Supabase compatibility', () {
    test('Group.fromMap() handles Supabase timestamp format', () {
      final supabaseRow = {
        'id': 'g1',
        'name': 'Test',
        'created_at': '2024-01-15T10:30:00+00:00',
        'updated_at': '2024-01-15T10:30:00.123456+00:00',
        'share_code': 'ABCD1234',
        'currency': 'EUR',
        'type': 'trip',
      };
      final group = Group.fromMap(supabaseRow);
      expect(group.id, 'g1');
      expect(group.currency, 'EUR');
    });

    test('Member.fromMap() handles Supabase row', () {
      final row = {
        'id': 'm1',
        'name': 'Alice',
        'group_id': 'g1',
        'updated_at': '2024-01-15T10:30:00+00:00',
      };
      final member = Member.fromMap(row);
      expect(member.name, 'Alice');
      expect(member.syncStatus, 'pending');
    });

    test('Expense.fromMap() handles Supabase row with numeric amount', () {
      final row = {
        'id': 'e1',
        'description': 'Dinner',
        'amount': 50,
        'paid_by_id': 'm1',
        'group_id': 'g1',
        'created_at': '2024-01-15T10:30:00+00:00',
        'expense_date': '2024-01-14T00:00:00+00:00',
        'category': 'food',
        'split_type': 'equal',
        'currency': 'EUR',
      };
      final expense = Expense.fromMap(row);
      expect(expense.amount, 50.0);
      expect(expense.amount, isA<double>());
    });
  });

  group('Model data integrity', () {
    test('toMap -> fromMap roundtrip preserves all Group data', () {
      final original = Group(
        id: 'round-trip',
        name: 'Roundtrip Test',
        createdAt: DateTime(2024, 6, 15),
        shareCode: 'XYZW9999',
        createdByUserId: 'user-abc',
        currency: 'JPY',
        type: 'home',
        syncStatus: 'synced',
      );
      final restored = Group.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.shareCode, original.shareCode);
      expect(restored.createdByUserId, original.createdByUserId);
      expect(restored.currency, original.currency);
      expect(restored.type, original.type);
      expect(restored.syncStatus, original.syncStatus);
    });

    test('toMap -> fromMap roundtrip preserves all Expense data', () {
      final original = Expense(
        id: 'rt-exp',
        description: 'Roundtrip Expense',
        amount: 123.45,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 3, 10),
        expenseDate: DateTime(2024, 3, 9),
        category: 'transport',
        splitType: 'percent',
        currency: 'GBP',
        syncStatus: 'synced',
      );
      final restored = Expense.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.paidById, original.paidById);
      expect(restored.category, original.category);
      expect(restored.splitType, original.splitType);
      expect(restored.currency, original.currency);
    });

    test('ExpenseSplit and ExpensePayer have no sync_status', () {
      final split = ExpenseSplit(
        id: 's1',
        expenseId: 'e1',
        memberId: 'm1',
        amount: 10.0,
      );
      final payer = ExpensePayer(
        id: 'p1',
        expenseId: 'e1',
        memberId: 'm1',
        amount: 10.0,
      );

      expect(split.toMap().containsKey('sync_status'), isFalse);
      expect(payer.toMap().containsKey('sync_status'), isFalse);
    });
  });
}
