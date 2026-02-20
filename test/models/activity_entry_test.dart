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
}
