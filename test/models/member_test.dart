import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/members/models/member.dart';

void main() {
  group('Member model', () {
    late Member testMember;

    setUp(() {
      testMember = Member(
        id: 'member-1',
        name: 'Alice',
        groupId: 'group-1',
        syncStatus: 'pending',
      );
    });

    test('toMap() includes all fields', () {
      final map = testMember.toMap();

      expect(map['id'], 'member-1');
      expect(map['name'], 'Alice');
      expect(map['group_id'], 'group-1');
      expect(map['sync_status'], 'pending');
      expect(map['updated_at'], isNotNull);
    });

    test('toApiMap() removes sync_status', () {
      final apiMap = testMember.toApiMap();

      expect(apiMap.containsKey('sync_status'), isFalse);
      expect(apiMap['id'], 'member-1');
      expect(apiMap['name'], 'Alice');
      expect(apiMap['group_id'], 'group-1');
    });

    test('fromMap() parses correctly', () {
      final map = testMember.toMap();
      final restored = Member.fromMap(map);

      expect(restored.id, testMember.id);
      expect(restored.name, testMember.name);
      expect(restored.groupId, testMember.groupId);
      expect(restored.syncStatus, 'pending');
    });

    test('fromMap() handles missing sync_status', () {
      final map = {
        'id': 'x',
        'name': 'Bob',
        'group_id': 'g1',
        'updated_at': '2024-01-01T00:00:00.000',
      };
      final member = Member.fromMap(map);

      expect(member.syncStatus, 'pending');
    });
  });
}
