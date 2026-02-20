import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/activity/models/activity_entry.dart';

void main() {
  group('ActivityEntry model', () {
    late ActivityEntry testEntry;

    setUp(() {
      testEntry = ActivityEntry(
        id: 'act-1',
        groupId: 'group-1',
        type: ActivityType.expenseCreated,
        description: 'Alice added "Dinner" (\$50.00)',
        memberName: 'Alice',
        timestamp: DateTime(2024, 1, 15, 12, 0),
        metadata: {'amount': 50.0, 'category': 'food'},
        syncStatus: 'pending',
      );
    });

    test('toMap() encodes metadata as JSON string', () {
      final map = testEntry.toMap();

      expect(map['id'], 'act-1');
      expect(map['type'], 'expenseCreated');
      expect(map['description'], contains('Dinner'));
      expect(map['member_name'], 'Alice');
      expect(map['sync_status'], 'pending');
      // metadata should be JSON-encoded string for SQLite
      expect(map['metadata'], isA<String>());
      final decoded = jsonDecode(map['metadata'] as String);
      expect(decoded['amount'], 50.0);
    });

    test('toApiMap() removes sync_status and passes metadata as raw map', () {
      final apiMap = testEntry.toApiMap();

      expect(apiMap.containsKey('sync_status'), isFalse);
      expect(apiMap['id'], 'act-1');
      // API map should have raw metadata (not JSON string) for Supabase JSONB
      expect(apiMap['metadata'], isA<Map>());
      expect(apiMap['metadata']['amount'], 50.0);
    });

    test('fromMap() parses JSON-encoded metadata', () {
      final map = testEntry.toMap();
      final restored = ActivityEntry.fromMap(map);

      expect(restored.id, testEntry.id);
      expect(restored.type, ActivityType.expenseCreated);
      expect(restored.description, testEntry.description);
      expect(restored.memberName, 'Alice');
      expect(restored.metadata, isNotNull);
      expect(restored.metadata!['amount'], 50.0);
    });

    test('fromMap() handles null metadata', () {
      final map = {
        'id': 'a1',
        'group_id': 'g1',
        'type': 'settlementRecorded',
        'description': 'Settlement',
        'timestamp': '2024-01-01T00:00:00.000',
      };
      final entry = ActivityEntry.fromMap(map);

      expect(entry.metadata, isNull);
      expect(entry.type, ActivityType.settlementRecorded);
    });

    test('fromMap() handles unknown activity type gracefully', () {
      final map = {
        'id': 'a2',
        'group_id': 'g1',
        'type': 'unknownType',
        'description': 'Unknown',
        'timestamp': '2024-01-01T00:00:00.000',
      };
      final entry = ActivityEntry.fromMap(map);

      // Should fall back to expenseCreated
      expect(entry.type, ActivityType.expenseCreated);
    });

    test('all ActivityType enum values are serializable', () {
      for (final type in ActivityType.values) {
        final entry = ActivityEntry(
          id: 'test-${type.name}',
          groupId: 'g1',
          type: type,
          description: 'Test ${type.name}',
          timestamp: DateTime.now(),
        );

        final map = entry.toMap();
        final restored = ActivityEntry.fromMap(map);
        expect(restored.type, type);
      }
    });
  });

  group('ActivityEntry edge cases', () {
    test('empty metadata map {}', () {
      final entry = ActivityEntry(
        id: 'a-empty',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'Empty meta',
        timestamp: DateTime(2024, 1, 1),
        metadata: {},
      );
      final map = entry.toMap();
      expect(map['metadata'], '{}');
      final restored = ActivityEntry.fromMap(map);
      expect(restored.metadata, isNotNull);
      expect(restored.metadata, isEmpty);
    });

    test('deeply nested metadata', () {
      final entry = ActivityEntry(
        id: 'a-nested',
        groupId: 'g1',
        type: ActivityType.expenseUpdated,
        description: 'Nested meta',
        timestamp: DateTime(2024, 1, 1),
        metadata: {
          'a': {
            'b': {'c': 1}
          }
        },
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.metadata!['a']['b']['c'], 1);
    });

    test('metadata with list values', () {
      final entry = ActivityEntry(
        id: 'a-list',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'List meta',
        timestamp: DateTime(2024, 1, 1),
        metadata: {
          'items': [1, 2, 3]
        },
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.metadata!['items'], [1, 2, 3]);
    });

    test('very large metadata (100 keys)', () {
      final meta = <String, dynamic>{};
      for (int i = 0; i < 100; i++) {
        meta['key_$i'] = 'value_$i';
      }
      final entry = ActivityEntry(
        id: 'a-large',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'Large meta',
        timestamp: DateTime(2024, 1, 1),
        metadata: meta,
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.metadata!.length, 100);
      expect(restored.metadata!['key_99'], 'value_99');
    });

    test('empty description string', () {
      final entry = ActivityEntry(
        id: 'a-nodesc',
        groupId: 'g1',
        type: ActivityType.groupCreated,
        description: '',
        timestamp: DateTime(2024, 1, 1),
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.description, '');
    });

    test('unicode in description and memberName', () {
      final entry = ActivityEntry(
        id: 'a-unicode',
        groupId: 'g1',
        type: ActivityType.memberAdded,
        description: 'Mar\u00EDa added \u{1F355} for \u00A5500',
        memberName: 'Mar\u00EDa \u{1F600}',
        timestamp: DateTime(2024, 1, 1),
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.description, entry.description);
      expect(restored.memberName, entry.memberName);
    });

    test('timestamp at epoch (1970-01-01)', () {
      final entry = ActivityEntry(
        id: 'a-epoch',
        groupId: 'g1',
        type: ActivityType.groupCreated,
        description: 'Epoch test',
        timestamp: DateTime.utc(1970, 1, 1),
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.timestamp.year, 1970);
    });

    test('timestamp far future (2099-12-31)', () {
      final future = DateTime(2099, 12, 31, 23, 59, 59);
      final entry = ActivityEntry(
        id: 'a-future',
        groupId: 'g1',
        type: ActivityType.groupCreated,
        description: 'Future test',
        timestamp: future,
      );
      final restored = ActivityEntry.fromMap(entry.toMap());
      expect(restored.timestamp.year, 2099);
      expect(restored.timestamp.month, 12);
      expect(restored.timestamp.day, 31);
    });
  });
}
