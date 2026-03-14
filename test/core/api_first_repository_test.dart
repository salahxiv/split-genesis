import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/groups/models/group.dart';
import 'package:split_genesis/features/members/models/member.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';
import 'package:split_genesis/features/activity/models/activity_entry.dart';
import 'package:split_genesis/features/expenses/models/expense_comment.dart';

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
        amountCents: 1000,
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
        amountCents: 2000,
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

    test('ActivityEntry.toApiMap() passes metadata as raw Map not JSON string',
        () {
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

  group('toApiMap() preserves all non-sync fields', () {
    test('Group.toApiMap() contains all expected Supabase columns', () {
      final group = Group(
        id: 'g1',
        name: 'Trip',
        createdAt: DateTime(2024, 1, 1),
        shareCode: 'ABCD1234',
        createdByUserId: 'user-1',
        currency: 'EUR',
        type: 'trip',
        syncStatus: 'synced',
      );
      final map = group.toApiMap();
      expect(map.keys.toSet(), containsAll([
        'id', 'name', 'created_at', 'share_code',
        'created_by_user_id', 'currency', 'type', 'updated_at',
      ]));
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('Expense.toApiMap() contains all expected Supabase columns', () {
      final expense = Expense(
        id: 'e1',
        description: 'Dinner',
        amountCents: 5000,
        paidById: 'm1',
        groupId: 'g1',
        createdAt: DateTime(2024, 1, 1),
        category: 'food',
        splitType: 'equal',
        currency: 'EUR',
        syncStatus: 'synced',
      );
      final map = expense.toApiMap();
      expect(map.keys.toSet(), containsAll([
        'id', 'description', 'amount', 'paid_by_id', 'group_id',
        'created_at', 'expense_date', 'category', 'split_type',
        'currency', 'updated_at',
      ]));
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('toApiMap on model with syncStatus=synced still removes it', () {
      final member = Member(
        id: 'm1', name: 'Bob', groupId: 'g1', syncStatus: 'synced',
      );
      expect(member.toApiMap().containsKey('sync_status'), isFalse);

      final settlement = SettlementRecord(
        id: 's1', groupId: 'g1', fromMemberId: 'm1', toMemberId: 'm2',
        amountCents: 1000, createdAt: DateTime.now(), syncStatus: 'synced',
      );
      expect(settlement.toApiMap().containsKey('sync_status'), isFalse);
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

    test('fromMap handles null for every nullable field per model', () {
      // Group: createdByUserId, updatedAt nullable
      final group = Group.fromMap({
        'id': 'g1', 'name': 'T', 'created_at': '2024-01-01T00:00:00.000',
        'created_by_user_id': null, 'updated_at': null,
      });
      expect(group.createdByUserId, isNull);
      expect(group.updatedAt, isNull);

      // Member: updatedAt nullable
      final member = Member.fromMap({
        'id': 'm1', 'name': 'T', 'group_id': 'g1', 'updated_at': null,
      });
      expect(member.updatedAt, isNull);

      // Expense: updatedAt nullable
      final expense = Expense.fromMap({
        'id': 'e1', 'description': 'T', 'amount': 10.0,
        'paid_by_id': 'm1', 'group_id': 'g1',
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': null, 'expense_date': null,
      });
      expect(expense.updatedAt, isNull);

      // SettlementRecord: fromMemberName, toMemberName, updatedAt nullable
      final settlement = SettlementRecord.fromMap({
        'id': 's1', 'group_id': 'g1', 'from_member_id': 'm1',
        'to_member_id': 'm2', 'amount': 10.0,
        'created_at': '2024-01-01T00:00:00.000',
        'from_member_name': null, 'to_member_name': null, 'updated_at': null,
      });
      expect(settlement.fromMemberName, isNull);
      expect(settlement.toMemberName, isNull);
      expect(settlement.updatedAt, isNull);

      // ActivityEntry: memberName, metadata nullable
      final activity = ActivityEntry.fromMap({
        'id': 'a1', 'group_id': 'g1', 'type': 'expenseCreated',
        'description': 'T', 'timestamp': '2024-01-01T00:00:00.000',
        'member_name': null, 'metadata': null,
      });
      expect(activity.memberName, isNull);
      expect(activity.metadata, isNull);
    });
  });

  group('ExpenseComment consistency', () {
    test('ExpenseComment.toMap includes sync_status', () {
      final comment = ExpenseComment(
        id: 'c1',
        expenseId: 'e1',
        memberName: 'Alice',
        content: 'Test',
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );
      final map = comment.toMap();
      expect(map.containsKey('sync_status'), isTrue);
      expect(map['sync_status'], 'pending');
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
        amountCents: 12345,
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
        amountCents: 1000,
      );
      final payer = ExpensePayer(
        id: 'p1',
        expenseId: 'e1',
        memberId: 'm1',
        amountCents: 1000,
      );

      expect(split.toMap().containsKey('sync_status'), isFalse);
      expect(payer.toMap().containsKey('sync_status'), isFalse);
    });

    test('all models: toMap keys match expected Supabase column names', () {
      // Group columns
      final groupKeys = Group(
        id: 'g', name: 'n', createdAt: DateTime.now(),
      ).toMap().keys.toSet();
      expect(groupKeys, containsAll([
        'id', 'name', 'created_at', 'share_code', 'created_by_user_id',
        'currency', 'type', 'updated_at', 'sync_status',
      ]));

      // Member columns
      final memberKeys = Member(
        id: 'm', name: 'n', groupId: 'g',
      ).toMap().keys.toSet();
      expect(memberKeys, containsAll([
        'id', 'name', 'group_id', 'updated_at', 'sync_status',
      ]));

      // Expense columns
      final expenseKeys = Expense(
        id: 'e', description: 'd', amountCents: 100, paidById: 'm',
        groupId: 'g', createdAt: DateTime.now(),
      ).toMap().keys.toSet();
      expect(expenseKeys, containsAll([
        'id', 'description', 'amount', 'paid_by_id', 'group_id',
        'created_at', 'expense_date', 'category', 'split_type',
        'currency', 'updated_at', 'sync_status',
      ]));

      // SettlementRecord columns
      final settlementKeys = SettlementRecord(
        id: 's', groupId: 'g', fromMemberId: 'm1', toMemberId: 'm2',
        amountCents: 100, createdAt: DateTime.now(),
      ).toMap().keys.toSet();
      expect(settlementKeys, containsAll([
        'id', 'group_id', 'from_member_id', 'to_member_id', 'amount',
        'created_at', 'from_member_name', 'to_member_name',
        'updated_at', 'sync_status',
      ]));
    });
  });
}
