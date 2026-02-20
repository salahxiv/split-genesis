import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:split_genesis/features/groups/models/group.dart';
import 'package:split_genesis/features/groups/repositories/group_repository.dart';
import '../helpers/mock_helpers.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late GroupRepository repo;

  final now = DateTime(2024, 1, 15);
  final testGroupMap = {
    'id': 'g1',
    'name': 'Trip',
    'created_at': now.toIso8601String(),
    'share_code': 'ABCD1234',
    'created_by_user_id': 'u1',
    'currency': 'USD',
    'type': 'trip',
    'updated_at': now.toIso8601String(),
    'sync_status': 'synced',
  };

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();

    repo = GroupRepository(
      db: mockDb,
      api: mockApi,
      connectivity: mockConnectivity,
    );

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit(noResult: true)).thenAnswer((_) async => []);
  });

  group('getAllGroups', () {
    test('online: calls api.select with correct params', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('groups', orderBy: 'created_at'))
          .thenAnswer((_) async => [testGroupMap]);
      when(() => mockDatabase.query('groups', orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testGroupMap]);

      final result = await repo.getAllGroups();

      verify(() => mockApi.select('groups', orderBy: 'created_at')).called(1);
      expect(result, hasLength(1));
      expect(result.first.id, 'g1');
      expect(result.first.name, 'Trip');
    });

    test('offline: reads from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.query('groups', orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testGroupMap]);

      final result = await repo.getAllGroups();

      verifyNever(() => mockApi.select(any(), orderBy: any(named: 'orderBy')));
      expect(result, hasLength(1));
    });

    test('API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('groups', orderBy: 'created_at'))
          .thenThrow(Exception('network error'));
      when(() => mockDatabase.query('groups', orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testGroupMap]);

      final result = await repo.getAllGroups();

      expect(result, hasLength(1));
    });
  });

  group('getGroup', () {
    test('online: calls api.selectSingle with correct filter', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('groups', filters: {'id': 'g1'}))
          .thenAnswer((_) async => testGroupMap);
      when(() => mockDatabase.insert('groups', any(),
              conflictAlgorithm: ConflictAlgorithm.replace))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.query('groups',
              where: 'id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => [testGroupMap]);

      final result = await repo.getGroup('g1');

      verify(() => mockApi.selectSingle('groups', filters: {'id': 'g1'}))
          .called(1);
      expect(result.id, 'g1');
    });

    test('throws StateError when not found', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('groups', filters: {'id': 'missing'}))
          .thenAnswer((_) async => null);

      expect(
        () => repo.getGroup('missing'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('insertGroup', () {
    test('online: calls api.upsert with group data', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.upsert('groups', any())).thenAnswer((_) async {});
      when(() => mockDatabase.insert('groups', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'groups',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final group = Group(
        id: 'g1',
        name: 'Trip',
        createdAt: now,
        shareCode: 'ABCD1234',
        currency: 'USD',
        type: 'trip',
      );

      await repo.insertGroup(group);

      final captured =
          verify(() => mockApi.upsert('groups', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['id'], 'g1');
      expect(captured['name'], 'Trip');
      expect(captured.containsKey('member_user_ids'), isTrue);
    });

    test('offline: writes to SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.insert('groups', any()))
          .thenAnswer((_) async => 1);

      final group = Group(
        id: 'g2',
        name: 'Offline Group',
        createdAt: now,
      );

      await repo.insertGroup(group);

      verifyNever(() => mockApi.upsert(any(), any()));
      verify(() => mockDatabase.insert('groups', any())).called(1);
    });
  });

  group('updateGroupName', () {
    test('online: upserts id, name, and updated_at', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.upsert('groups', any())).thenAnswer((_) async {});
      when(() => mockDatabase.update(
            'groups',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      await repo.updateGroupName('g1', 'New Name');

      final captured =
          verify(() => mockApi.upsert('groups', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['id'], 'g1');
      expect(captured['name'], 'New Name');
      expect(captured.containsKey('updated_at'), isTrue);
    });
  });

  group('deleteGroup', () {
    test('online: calls api.delete', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.delete('groups', 'g1')).thenAnswer((_) async {});
      when(() => mockDatabase.delete('groups',
              where: 'id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => 1);

      await repo.deleteGroup('g1');

      verify(() => mockApi.delete('groups', 'g1')).called(1);
      verify(() =>
              mockDatabase.delete('groups', where: 'id = ?', whereArgs: ['g1']))
          .called(1);
    });

    test('offline: deletes from SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.delete('groups',
              where: 'id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => 1);

      await repo.deleteGroup('g1');

      verifyNever(() => mockApi.delete(any(), any()));
      verify(() =>
              mockDatabase.delete('groups', where: 'id = ?', whereArgs: ['g1']))
          .called(1);
    });
  });

  group('getGroupByShareCode', () {
    test('uppercases input and uses correct filter', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('groups',
              filters: {'share_code': 'ABCD1234'}))
          .thenAnswer((_) async => testGroupMap);
      when(() => mockDatabase.insert('groups', any(),
              conflictAlgorithm: ConflictAlgorithm.replace))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.query('groups',
              where: 'share_code = ?', whereArgs: ['ABCD1234']))
          .thenAnswer((_) async => [testGroupMap]);

      final result = await repo.getGroupByShareCode('abcd1234');

      verify(() => mockApi.selectSingle('groups',
          filters: {'share_code': 'ABCD1234'})).called(1);
      expect(result, isNotNull);
      expect(result!.shareCode, 'ABCD1234');
    });

    test('returns null when not found', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.selectSingle('groups',
              filters: {'share_code': 'XXXX0000'}))
          .thenAnswer((_) async => null);

      final result = await repo.getGroupByShareCode('xxxx0000');

      expect(result, isNull);
    });
  });
}
