import 'package:sqflite/sqflite.dart';
import '../../../core/database/api_first_repository.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/supabase_data_source.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/settlement_record.dart';

class SettlementRepository with ApiFirstRepository {
  SettlementRepository({DatabaseHelper? db, SupabaseDataSource? api, ConnectivityService? connectivity}) {
    initDeps(db: db, api: api, connectivity: connectivity);
  }
  Future<List<SettlementRecord>> getSettlementsByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select(
        'settlements',
        filters: {'group_id': groupId},
        orderBy: 'created_at',
      ),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          batch.insert(
            'settlements',
            {
              'id': row['id'],
              'group_id': row['group_id'],
              'from_member_id': row['from_member_id'],
              'to_member_id': row['to_member_id'],
              'amount': row['amount'],
              'created_at': row['created_at'],
              'updated_at': row['updated_at'],
              'from_member_name': row['from_member_name'],
              'to_member_name': row['to_member_name'],
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query(
          'settlements',
          where: 'group_id = ?',
          whereArgs: [groupId],
          orderBy: 'created_at DESC',
        );
        return maps.map((map) => SettlementRecord.fromMap(map)).toList();
      },
    );
  }

  Future<void> insertSettlement(SettlementRecord settlement) async {
    await writeThrough(
      apiCall: () => api.upsert('settlements', settlement.toApiMap()),
      sqliteCall: (database) async {
        await database.insert('settlements', settlement.toMap());
      },
      syncTable: 'settlements',
      syncId: settlement.id,
    );
  }

  Future<void> deleteSettlement(String id) async {
    await deleteThrough(
      apiCall: () => api.delete('settlements', id),
      sqliteCall: (database) async {
        await database.delete('settlements', where: 'id = ?', whereArgs: [id]);
      },
    );
  }
}
