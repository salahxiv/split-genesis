import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/groups/models/group.dart';

void main() {
  group('Group model', () {
    late Group testGroup;

    setUp(() {
      testGroup = Group(
        id: 'test-id',
        name: 'Test Group',
        createdAt: DateTime(2024, 1, 1),
        shareCode: 'ABCD1234',
        createdByUserId: 'user-1',
        currency: 'EUR',
        type: 'trip',
        syncStatus: 'pending',
      );
    });

    test('toMap() includes all fields', () {
      final map = testGroup.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Group');
      expect(map['share_code'], 'ABCD1234');
      expect(map['created_by_user_id'], 'user-1');
      expect(map['currency'], 'EUR');
      expect(map['type'], 'trip');
      expect(map['sync_status'], 'pending');
      expect(map['created_at'], isNotNull);
    });

    test('toApiMap() removes sync_status', () {
      final apiMap = testGroup.toApiMap();

      expect(apiMap.containsKey('sync_status'), isFalse);
      expect(apiMap['id'], 'test-id');
      expect(apiMap['name'], 'Test Group');
      expect(apiMap['currency'], 'EUR');
    });

    test('fromMap() parses correctly', () {
      final map = testGroup.toMap();
      final restored = Group.fromMap(map);

      expect(restored.id, testGroup.id);
      expect(restored.name, testGroup.name);
      expect(restored.shareCode, testGroup.shareCode);
      expect(restored.currency, testGroup.currency);
      expect(restored.type, testGroup.type);
      expect(restored.syncStatus, testGroup.syncStatus);
    });

    test('fromMap() handles missing optional fields with defaults', () {
      final minimalMap = {
        'id': 'min-id',
        'name': 'Minimal',
        'created_at': '2024-01-01T00:00:00.000',
      };
      final group = Group.fromMap(minimalMap);

      expect(group.currency, 'USD');
      expect(group.type, 'other');
      expect(group.syncStatus, 'pending');
    });

    test('copyWith() creates modified copy', () {
      final copy = testGroup.copyWith(name: 'New Name', currency: 'GBP');

      expect(copy.name, 'New Name');
      expect(copy.currency, 'GBP');
      expect(copy.id, testGroup.id);
      expect(copy.type, testGroup.type);
    });

    test('auto-generates share code if not provided', () {
      final group = Group(
        id: 'auto-code',
        name: 'Auto',
        createdAt: DateTime.now(),
      );

      expect(group.shareCode, isNotEmpty);
      expect(group.shareCode.length, 8);
    });
  });

  group('Group model edge cases', () {
    test('empty name string', () {
      final group = Group(
        id: 'g1',
        name: '',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Group.fromMap(group.toMap());
      expect(restored.name, '');
    });

    test('unicode/emoji in name', () {
      final group = Group(
        id: 'g2',
        name: 'Trip \u{1F30D} caf\u00E9 \u{1F389}',
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Group.fromMap(group.toMap());
      expect(restored.name, 'Trip \u{1F30D} caf\u00E9 \u{1F389}');
    });

    test('very long name (500 chars)', () {
      final longName = 'A' * 500;
      final group = Group(
        id: 'g3',
        name: longName,
        createdAt: DateTime(2024, 1, 1),
      );
      final restored = Group.fromMap(group.toMap());
      expect(restored.name.length, 500);
    });

    test('shareCode is always uppercase', () {
      final group = Group(
        id: 'g4',
        name: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );
      // Auto-generated share codes should be uppercase
      expect(group.shareCode, group.shareCode.toUpperCase());
    });

    test('createdAt with timezone offset format', () {
      final map = {
        'id': 'g5',
        'name': 'TZ test',
        'created_at': '2024-06-15T10:30:00+05:30',
      };
      final group = Group.fromMap(map);
      expect(group.createdAt.year, 2024);
      expect(group.createdAt.month, 6);
    });

    test('updatedAt null handling', () {
      final group = Group(
        id: 'g6',
        name: 'No update',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(group.updatedAt, isNull);
      // toMap should still have updated_at (generated from DateTime.now())
      final map = group.toMap();
      expect(map['updated_at'], isNotNull);
    });

    test('syncStatus synced vs pending roundtrip', () {
      final synced = Group(
        id: 'g7',
        name: 'Synced',
        createdAt: DateTime(2024, 1, 1),
        syncStatus: 'synced',
      );
      final restored = Group.fromMap(synced.toMap());
      expect(restored.syncStatus, 'synced');

      final pending = Group(
        id: 'g8',
        name: 'Pending',
        createdAt: DateTime(2024, 1, 1),
        syncStatus: 'pending',
      );
      final restored2 = Group.fromMap(pending.toMap());
      expect(restored2.syncStatus, 'pending');
    });

    test('fromMap with Supabase-style timestamps (+00:00)', () {
      final map = {
        'id': 'g9',
        'name': 'Supabase',
        'created_at': '2024-01-15T10:30:00.123456+00:00',
        'updated_at': '2024-01-15T11:00:00.654321+00:00',
      };
      final group = Group.fromMap(map);
      expect(group.createdAt.hour, 10);
      expect(group.updatedAt, isNotNull);
      expect(group.updatedAt!.hour, 11);
    });

    test('currency/type default when key missing vs null value', () {
      // Key missing
      final map1 = {
        'id': 'g10',
        'name': 'Missing keys',
        'created_at': '2024-01-01T00:00:00.000',
      };
      final g1 = Group.fromMap(map1);
      expect(g1.currency, 'USD');
      expect(g1.type, 'other');

      // Key present but null
      final map2 = {
        'id': 'g11',
        'name': 'Null values',
        'created_at': '2024-01-01T00:00:00.000',
        'currency': null,
        'type': null,
      };
      final g2 = Group.fromMap(map2);
      expect(g2.currency, 'USD');
      expect(g2.type, 'other');
    });
  });
}
