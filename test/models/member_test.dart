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

  group('Member model edge cases', () {
    test('empty name', () {
      final member = Member(id: 'm1', name: '', groupId: 'g1');
      final restored = Member.fromMap(member.toMap());
      expect(restored.name, '');
    });

    test('unicode/emoji name', () {
      final member = Member(
        id: 'm2',
        name: 'Mar\u00EDa \u{1F600} caf\u00E9',
        groupId: 'g1',
      );
      final restored = Member.fromMap(member.toMap());
      expect(restored.name, 'Mar\u00EDa \u{1F600} caf\u00E9');
    });

    test('updatedAt null generates current time in toMap', () {
      final member = Member(id: 'm3', name: 'Test', groupId: 'g1');
      expect(member.updatedAt, isNull);
      final map = member.toMap();
      // toMap should fill in updated_at with DateTime.now()
      expect(map['updated_at'], isNotNull);
      expect(map['updated_at'], isA<String>());
      // Should be parseable
      expect(() => DateTime.parse(map['updated_at'] as String), returnsNormally);
    });

    test('fromMap with Supabase timestamps', () {
      final map = {
        'id': 'm4',
        'name': 'Supabase User',
        'group_id': 'g1',
        'updated_at': '2024-06-15T10:30:00.123456+00:00',
      };
      final member = Member.fromMap(map);
      expect(member.updatedAt, isNotNull);
      expect(member.updatedAt!.year, 2024);
      expect(member.updatedAt!.month, 6);
    });
  });
}
