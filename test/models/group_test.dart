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
}
