import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:split_genesis/core/database/api_first_repository.dart';
import 'package:split_genesis/core/database/database_helper.dart';
import 'package:split_genesis/core/database/supabase_data_source.dart';
import 'package:split_genesis/core/services/connectivity_service.dart';
import '../helpers/mock_helpers.dart';

/// Concrete class to test the mixin in isolation.
class _TestRepo with ApiFirstRepository {
  _TestRepo({
    required DatabaseHelper db,
    required SupabaseDataSource api,
    required ConnectivityService connectivity,
  }) {
    initDeps(db: db, api: api, connectivity: connectivity);
  }
}

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late _TestRepo repo;

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    repo = _TestRepo(db: mockDb, api: mockApi, connectivity: mockConnectivity);

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
  });

  group('fetchAndCache', () {
    test('online success: calls API, caches, then reads SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final apiRows = [
        {'id': '1', 'name': 'A'},
        {'id': '2', 'name': 'B'},
      ];
      var cacheWriterCalled = false;

      final result = await repo.fetchAndCache<String>(
        apiCall: () async => apiRows,
        cacheWriter: (db, rows) async {
          cacheWriterCalled = true;
          expect(rows, apiRows);
        },
        sqliteCall: () async => ['A', 'B'],
      );

      expect(result, ['A', 'B']);
      expect(cacheWriterCalled, isTrue);
    });

    test('online API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final result = await repo.fetchAndCache<String>(
        apiCall: () async => throw Exception('API down'),
        cacheWriter: (db, rows) async => fail('should not cache'),
        sqliteCall: () async => ['cached'],
      );

      expect(result, ['cached']);
    });

    test('offline: reads SQLite directly without calling API', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      var apiCalled = false;
      final result = await repo.fetchAndCache<String>(
        apiCall: () async {
          apiCalled = true;
          return [];
        },
        cacheWriter: (db, rows) async => fail('should not cache'),
        sqliteCall: () async => ['offline-data'],
      );

      expect(result, ['offline-data']);
      expect(apiCalled, isFalse);
    });
  });

  group('fetchSingleAndCache', () {
    test('online returns row: caches and reads SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final apiRow = {'id': '1', 'name': 'Test'};
      var cacheWriterCalled = false;

      final result = await repo.fetchSingleAndCache<String>(
        apiCall: () async => apiRow,
        cacheWriter: (db, row) async {
          cacheWriterCalled = true;
          expect(row, apiRow);
        },
        sqliteCall: () async => 'Test',
      );

      expect(result, 'Test');
      expect(cacheWriterCalled, isTrue);
    });

    test('online returns null: returns null without caching', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final result = await repo.fetchSingleAndCache<String>(
        apiCall: () async => null,
        cacheWriter: (db, row) async => fail('should not cache null'),
        sqliteCall: () async => 'should not reach',
      );

      expect(result, isNull);
    });

    test('online API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      final result = await repo.fetchSingleAndCache<String>(
        apiCall: () async => throw Exception('timeout'),
        cacheWriter: (db, row) async => fail('should not cache'),
        sqliteCall: () async => 'fallback',
      );

      expect(result, 'fallback');
    });

    test('offline: reads SQLite directly', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final result = await repo.fetchSingleAndCache<String>(
        apiCall: () async => fail('should not call API'),
        cacheWriter: (db, row) async => fail('should not cache'),
        sqliteCall: () async => 'offline',
      );

      expect(result, 'offline');
    });
  });

  group('writeThrough', () {
    test('online success: calls API, writes SQLite, marks synced', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockDatabase.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      var apiCalled = false;
      var sqliteCalled = false;

      await repo.writeThrough(
        apiCall: () async {
          apiCalled = true;
        },
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
        syncTable: 'groups',
        syncId: 'g1',
      );

      expect(apiCalled, isTrue);
      expect(sqliteCalled, isTrue);
      verify(() => mockDatabase.update(
            'groups',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: ['g1'],
          )).called(1);
    });

    test('online success without syncTable: no sync_status update', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      await repo.writeThrough(
        apiCall: () async {},
        sqliteCall: (db) async {},
      );

      verifyNever(() => mockDatabase.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ));
    });

    test('online API error: writes SQLite only (pending)', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      var sqliteCalled = false;

      await repo.writeThrough(
        apiCall: () async => throw Exception('server error'),
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
        syncTable: 'groups',
        syncId: 'g1',
      );

      expect(sqliteCalled, isTrue);
      verifyNever(() => mockDatabase.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ));
    });

    test('offline: writes SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      var apiCalled = false;
      var sqliteCalled = false;

      await repo.writeThrough(
        apiCall: () async {
          apiCalled = true;
        },
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
      );

      expect(apiCalled, isFalse);
      expect(sqliteCalled, isTrue);
    });
  });

  group('deleteThrough', () {
    test('online success: calls API and SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      var apiCalled = false;
      var sqliteCalled = false;

      await repo.deleteThrough(
        apiCall: () async {
          apiCalled = true;
        },
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
      );

      expect(apiCalled, isTrue);
      expect(sqliteCalled, isTrue);
    });

    test('online API error: still deletes from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);

      var sqliteCalled = false;

      await repo.deleteThrough(
        apiCall: () async => throw Exception('API error'),
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
      );

      expect(sqliteCalled, isTrue);
    });

    test('offline: deletes from SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);

      var apiCalled = false;
      var sqliteCalled = false;

      await repo.deleteThrough(
        apiCall: () async {
          apiCalled = true;
        },
        sqliteCall: (db) async {
          sqliteCalled = true;
        },
      );

      expect(apiCalled, isFalse);
      expect(sqliteCalled, isTrue);
    });
  });
}
