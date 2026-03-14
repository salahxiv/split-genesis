import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';

void main() {
  group('SettlementRecord model', () {
    late SettlementRecord testSettlement;

    setUp(() {
      testSettlement = SettlementRecord(
        id: 'set-1',
        groupId: 'group-1',
        fromMemberId: 'member-1',
        toMemberId: 'member-2',
        amountCents: 3000,
        createdAt: DateTime(2024, 2, 1),
        fromMemberName: 'Alice',
        toMemberName: 'Bob',
        syncStatus: 'pending',
      );
    });

    test('toMap() includes all fields', () {
      final map = testSettlement.toMap();

      expect(map['id'], 'set-1');
      expect(map['group_id'], 'group-1');
      expect(map['from_member_id'], 'member-1');
      expect(map['to_member_id'], 'member-2');
      expect(map['amount'], 30.0);
      expect(map['from_member_name'], 'Alice');
      expect(map['to_member_name'], 'Bob');
      expect(map['sync_status'], 'pending');
    });

    test('toApiMap() removes sync_status', () {
      final apiMap = testSettlement.toApiMap();

      expect(apiMap.containsKey('sync_status'), isFalse);
      expect(apiMap['id'], 'set-1');
      expect(apiMap['amount'], 30.0);
      expect(apiMap['from_member_name'], 'Alice');
    });

    test('fromMap() roundtrip', () {
      final map = testSettlement.toMap();
      final restored = SettlementRecord.fromMap(map);

      expect(restored.id, testSettlement.id);
      expect(restored.groupId, testSettlement.groupId);
      expect(restored.fromMemberId, testSettlement.fromMemberId);
      expect(restored.toMemberId, testSettlement.toMemberId);
      expect(restored.amount, testSettlement.amount);
      expect(restored.fromMemberName, 'Alice');
      expect(restored.toMemberName, 'Bob');
    });

    test('fromMap() handles null member names', () {
      final map = {
        'id': 's1',
        'group_id': 'g1',
        'from_member_id': 'm1',
        'to_member_id': 'm2',
        'amount': 10.0,
        'created_at': '2024-01-01T00:00:00.000',
      };
      final s = SettlementRecord.fromMap(map);

      expect(s.fromMemberName, isNull);
      expect(s.toMemberName, isNull);
    });
  });

  group('SettlementRecord edge cases', () {
    test('zero amount settlement', () {
      final s = SettlementRecord(
        id: 's-zero',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountCents: 0,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = SettlementRecord.fromMap(s.toMap());
      expect(restored.amount, 0.0);
    });

    test('very large amount', () {
      final s = SettlementRecord(
        id: 's-big',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountCents: 99999999,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = SettlementRecord.fromMap(s.toMap());
      expect(restored.amount, 999999.99);
    });

    test('fromMemberId == toMemberId (self-settlement data)', () {
      final s = SettlementRecord(
        id: 's-self',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm1',
        amountCents: 5000,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = SettlementRecord.fromMap(s.toMap());
      expect(restored.fromMemberId, restored.toMemberId);
      expect(restored.amount, 50.0);
    });

    test('Supabase timestamp format in created_at', () {
      final map = {
        'id': 's-supa',
        'group_id': 'g1',
        'from_member_id': 'm1',
        'to_member_id': 'm2',
        'amount': 25.0,
        'created_at': '2024-06-15T10:30:00.123456+00:00',
      };
      final s = SettlementRecord.fromMap(map);
      expect(s.createdAt.year, 2024);
      expect(s.createdAt.month, 6);
      expect(s.createdAt.day, 15);
    });
  });
}
