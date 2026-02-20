import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:split_genesis/features/activity/models/activity_entry.dart';
import 'package:split_genesis/features/activity/repositories/activity_repository.dart';
import '../helpers/mock_helpers.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late ActivityRepository repo;

  final now = DateTime(2024, 1, 15);
  final testActivityMap = {
    'id': 'a1',
    'group_id': 'g1',
    'type': 'expenseCreated',
    'description': 'Alice added Lunch',
    'member_name': 'Alice',
    'timestamp': now.toIso8601String(),
    'metadata': '{"amount":25.50}',
    'sync_status': 'synced',
  };

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();

    repo = ActivityRepository(
      db: mockDb,
      api: mockApi,
      connectivity: mockConnectivity,
    );

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit(noResult: true)).thenAnswer((_) async => []);
  });

  group('getActivitiesByGroup', () {
    test('online: calls api.select with correct params', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      // Supabase returns JSONB as a Map, not a string
      final apiRow = {
        'id': 'a1',
        'group_id': 'g1',
        'type': 'expenseCreated',
        'description': 'Alice added Lunch',
        'member_name': 'Alice',
        'timestamp': now.toIso8601String(),
        'metadata': {'amount': 25.50},
      };
      when(() => mockApi.select('activity_log',
              filters: {'group_id': 'g1'}, orderBy: 'timestamp'))
          .thenAnswer((_) async => [apiRow]);
      when(() => mockDatabase.query('activity_log',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'timestamp DESC'))
          .thenAnswer((_) async => [testActivityMap]);

      final result = await repo.getActivitiesByGroup('g1');

      verify(() => mockApi.select('activity_log',
          filters: {'group_id': 'g1'}, orderBy: 'timestamp')).called(1);
      expect(result, hasLength(1));
      expect(result.first.description, 'Alice added Lunch');
      expect(result.first.type, ActivityType.expenseCreated);
    });

    test('cacheWriter jsonEncodes metadata from JSONB', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      final apiRow = {
        'id': 'a1',
        'group_id': 'g1',
        'type': 'expenseCreated',
        'description': 'Test',
        'member_name': 'Alice',
        'timestamp': now.toIso8601String(),
        'metadata': {'amount': 25.50},
      };
      when(() => mockApi.select('activity_log',
              filters: {'group_id': 'g1'}, orderBy: 'timestamp'))
          .thenAnswer((_) async => [apiRow]);
      when(() => mockDatabase.query('activity_log',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'timestamp DESC'))
          .thenAnswer((_) async => [testActivityMap]);

      await repo.getActivitiesByGroup('g1');

      // Verify batch.insert was called — the cacheWriter should jsonEncode the metadata
      final insertCall = verify(() => mockBatch.insert(
            'activity_log',
            captureAny(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ));
      insertCall.called(1);
      final cachedRow = insertCall.captured.single as Map<String, dynamic>;
      expect(cachedRow['metadata'], jsonEncode({'amount': 25.50}));
      expect(cachedRow['sync_status'], 'synced');
    });

    test('offline: reads from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.query('activity_log',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'timestamp DESC'))
          .thenAnswer((_) async => [testActivityMap]);

      final result = await repo.getActivitiesByGroup('g1');

      verifyNever(() => mockApi.select(any(),
          filters: any(named: 'filters'), orderBy: any(named: 'orderBy')));
      expect(result, hasLength(1));
    });

    test('API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('activity_log',
              filters: {'group_id': 'g1'}, orderBy: 'timestamp'))
          .thenThrow(Exception('error'));
      when(() => mockDatabase.query('activity_log',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'timestamp DESC'))
          .thenAnswer((_) async => [testActivityMap]);

      final result = await repo.getActivitiesByGroup('g1');

      expect(result, hasLength(1));
    });
  });

  group('insertActivity', () {
    test('online: calls api.upsert with toApiMap()', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.upsert('activity_log', any()))
          .thenAnswer((_) async {});
      when(() => mockDatabase.insert('activity_log', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'activity_log',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final entry = ActivityEntry(
        id: 'a1',
        groupId: 'g1',
        type: ActivityType.expenseCreated,
        description: 'Alice added Lunch',
        memberName: 'Alice',
        timestamp: now,
        metadata: {'amount': 25.50},
      );

      await repo.insertActivity(entry);

      final captured =
          verify(() => mockApi.upsert('activity_log', captureAny()))
              .captured
              .single as Map<String, dynamic>;
      expect(captured['id'], 'a1');
      expect(captured.containsKey('sync_status'), isFalse);
      // toApiMap sends metadata as Map (JSONB), not encoded string
      expect(captured['metadata'], isA<Map>());
    });

    test('offline: writes to SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.insert('activity_log', any()))
          .thenAnswer((_) async => 1);

      final entry = ActivityEntry(
        id: 'a2',
        groupId: 'g1',
        type: ActivityType.memberAdded,
        description: 'Bob joined',
        timestamp: now,
      );

      await repo.insertActivity(entry);

      verifyNever(() => mockApi.upsert(any(), any()));
    });
  });

  group('deleteActivitiesByGroup', () {
    test('online: calls api.deleteWhere with correct filter', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() =>
              mockApi.deleteWhere('activity_log', {'group_id': 'g1'}))
          .thenAnswer((_) async {});
      when(() => mockDatabase.delete('activity_log',
              where: 'group_id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => 5);

      await repo.deleteActivitiesByGroup('g1');

      verify(() =>
              mockApi.deleteWhere('activity_log', {'group_id': 'g1'}))
          .called(1);
      verify(() => mockDatabase.delete('activity_log',
          where: 'group_id = ?', whereArgs: ['g1'])).called(1);
    });

    test('offline: deletes from SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.delete('activity_log',
              where: 'group_id = ?', whereArgs: ['g1']))
          .thenAnswer((_) async => 5);

      await repo.deleteActivitiesByGroup('g1');

      verifyNever(() => mockApi.deleteWhere(any(), any()));
    });
  });
}
