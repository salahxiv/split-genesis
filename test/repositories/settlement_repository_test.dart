import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:split_genesis/features/settlements/models/settlement_record.dart';
import 'package:split_genesis/features/settlements/repositories/settlement_repository.dart';
import '../helpers/mock_helpers.dart';

void main() {
  late MockDatabaseHelper mockDb;
  late MockSupabaseDataSource mockApi;
  late MockConnectivityService mockConnectivity;
  late MockDatabase mockDatabase;
  late MockBatch mockBatch;
  late SettlementRepository repo;

  final now = DateTime(2024, 1, 15);
  final testSettlementMap = {
    'id': 'st1',
    'group_id': 'g1',
    'from_member_id': 'm1',
    'to_member_id': 'm2',
    'amount': 50.00,
    'created_at': now.toIso8601String(),
    'from_member_name': 'Alice',
    'to_member_name': 'Bob',
    'updated_at': now.toIso8601String(),
    'sync_status': 'synced',
  };

  setUp(() {
    mockDb = MockDatabaseHelper();
    mockApi = MockSupabaseDataSource();
    mockConnectivity = MockConnectivityService();
    mockDatabase = MockDatabase();
    mockBatch = MockBatch();

    repo = SettlementRepository(
      db: mockDb,
      api: mockApi,
      connectivity: mockConnectivity,
    );

    when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    when(() => mockDatabase.batch()).thenReturn(mockBatch);
    when(() => mockBatch.commit(noResult: true)).thenAnswer((_) async => []);
  });

  group('getSettlementsByGroup', () {
    test('online: calls api.select with correct params', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('settlements',
              filters: {'group_id': 'g1'}, orderBy: 'created_at'))
          .thenAnswer((_) async => [testSettlementMap]);
      when(() => mockDatabase.query('settlements',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testSettlementMap]);

      final result = await repo.getSettlementsByGroup('g1');

      verify(() => mockApi.select('settlements',
          filters: {'group_id': 'g1'}, orderBy: 'created_at')).called(1);
      expect(result, hasLength(1));
      expect(result.first.amount, 50.00);
      expect(result.first.fromMemberName, 'Alice');
    });

    test('offline: reads from SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.query('settlements',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testSettlementMap]);

      final result = await repo.getSettlementsByGroup('g1');

      verifyNever(() => mockApi.select(any(),
          filters: any(named: 'filters'), orderBy: any(named: 'orderBy')));
      expect(result, hasLength(1));
    });

    test('API error: falls back to SQLite', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.select('settlements',
              filters: {'group_id': 'g1'}, orderBy: 'created_at'))
          .thenThrow(Exception('timeout'));
      when(() => mockDatabase.query('settlements',
              where: 'group_id = ?',
              whereArgs: ['g1'],
              orderBy: 'created_at DESC'))
          .thenAnswer((_) async => [testSettlementMap]);

      final result = await repo.getSettlementsByGroup('g1');

      expect(result, hasLength(1));
    });
  });

  group('insertSettlement', () {
    test('online: calls api.upsert with toApiMap()', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.upsert('settlements', any()))
          .thenAnswer((_) async {});
      when(() => mockDatabase.insert('settlements', any()))
          .thenAnswer((_) async => 1);
      when(() => mockDatabase.update(
            'settlements',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1);

      final settlement = SettlementRecord(
        id: 'st1',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountCents: 5000,
        createdAt: now,
        fromMemberName: 'Alice',
        toMemberName: 'Bob',
      );

      await repo.insertSettlement(settlement);

      final captured = verify(() => mockApi.upsert('settlements', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['id'], 'st1');
      expect(captured['amount'], 50.00);
      expect(captured.containsKey('sync_status'), isFalse);
    });

    test('offline: writes to SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.insert('settlements', any()))
          .thenAnswer((_) async => 1);

      final settlement = SettlementRecord(
        id: 'st2',
        groupId: 'g1',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountCents: 3000,
        createdAt: now,
      );

      await repo.insertSettlement(settlement);

      verifyNever(() => mockApi.upsert(any(), any()));
      verify(() => mockDatabase.insert('settlements', any())).called(1);
    });
  });

  group('deleteSettlement', () {
    test('online: calls api.delete and SQLite delete', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockApi.delete('settlements', 'st1'))
          .thenAnswer((_) async {});
      when(() => mockDatabase.delete('settlements',
              where: 'id = ?', whereArgs: ['st1']))
          .thenAnswer((_) async => 1);

      await repo.deleteSettlement('st1');

      verify(() => mockApi.delete('settlements', 'st1')).called(1);
      verify(() => mockDatabase.delete('settlements',
          where: 'id = ?', whereArgs: ['st1'])).called(1);
    });

    test('offline: deletes from SQLite only', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockDatabase.delete('settlements',
              where: 'id = ?', whereArgs: ['st1']))
          .thenAnswer((_) async => 1);

      await repo.deleteSettlement('st1');

      verifyNever(() => mockApi.delete(any(), any()));
    });
  });
}
