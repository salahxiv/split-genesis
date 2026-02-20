import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:split_genesis/features/members/models/member.dart';
import 'package:split_genesis/features/members/repositories/member_repository.dart';
import '../helpers/mock_helpers.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late MemberRepository repo;

  final now = DateTime(2024, 1, 15);
  final testMemberMap = {
    'id': 'm1',
    'name': 'Alice',
    'group_id': 'g1',
    'updated_at': now.toIso8601String(),
    'sync_status': 'synced',
  };

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();

    repo = MemberRepository(
      db: mockDb,
      api: mockApi,
      connectivity: mockConnectivity,
    );

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit(noResult: true)).thenAnswer((_) async => []);
  });

  group('getMembersByGroup', () {
    test('online: calls api.select with group_id filter', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('members', filters: {'group_id': 'g1'}))
          .thenAnswer((_) async => [testMemberMap]);
      when(() => mockDatabase.query('members',
              where: 'group_id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => [testMemberMap]);

      final result = await repo.getMembersByGroup('g1');

      verify(() => mockApi.select('members', filters: {'group_id': 'g1'}))
          .called(1);
      expect(result, hasLength(1));
      expect(result.first.name, 'Alice');
    });

    test('offline: reads from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.query('members',
              where: 'group_id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => [testMemberMap]);

      final result = await repo.getMembersByGroup('g1');

      verifyNever(() => mockApi.select(any(), filters: any(named: 'filters')));
      expect(result, hasLength(1));
    });

    test('API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('members', filters: {'group_id': 'g1'}))
          .thenThrow(Exception('error'));
      when(() => mockDatabase.query('members',
              where: 'group_id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => [testMemberMap]);

      final result = await repo.getMembersByGroup('g1');

      expect(result, hasLength(1));
    });
  });

  group('getMember', () {
    test('online: returns member from SQLite after caching', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('members', filters: {'id': 'm1'}))
          .thenAnswer((_) async => testMemberMap);
      when(() => mockDatabase.insert('members', any(),
              conflictAlgorithm: ConflictAlgorithm.replace))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.query('members',
              where: 'id = ?', whereArgs: ['m1']))
          .thenAnswer((_) async => [testMemberMap]);

      final result = await repo.getMember('m1');

      expect(result.id, 'm1');
      expect(result.name, 'Alice');
    });

    test('throws StateError when not found', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('members', filters: {'id': 'missing'}))
          .thenAnswer((_) async => null);

      expect(
        () => repo.getMember('missing'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('insertMember', () {
    test('online: calls api.upsert with toApiMap()', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.upsert('members', any())).thenAnswer((_) async {});
      when(() => mockDatabase.insert('members', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'members',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final member = Member(id: 'm1', name: 'Alice', groupId: 'g1');

      await repo.insertMember(member);

      final captured =
          verify(() => mockApi.upsert('members', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['id'], 'm1');
      expect(captured['name'], 'Alice');
      expect(captured.containsKey('sync_status'), isFalse);
    });
  });

  group('deleteMember', () {
    test('online: calls api.delete and SQLite delete', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.delete('members', 'm1')).thenAnswer((_) async {});
      when(() => mockDatabase.delete('members',
              where: 'id = ?', whereArgs: ['m1']))
          .thenAnswer((_) async => 1);

      await repo.deleteMember('m1');

      verify(() => mockApi.delete('members', 'm1')).called(1);
      verify(() => mockDatabase.delete('members',
          where: 'id = ?', whereArgs: ['m1'])).called(1);
    });
  });
}
