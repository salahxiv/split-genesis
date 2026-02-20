import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/api_first_repository.dart';
import '../models/activity_entry.dart';

class ActivityRepository with ApiFirstRepository {
  Future<List<ActivityEntry>> getActivitiesByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select(
        'activity_log',
        filters: {'group_id': groupId},
        orderBy: 'timestamp',
      ),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          batch.insert(
            'activity_log',
            {
              'id': row['id'],
              'group_id': row['group_id'],
              'type': row['type'],
              'description': row['description'],
              'member_name': row['member_name'],
              'timestamp': row['timestamp'],
              'metadata': row['metadata'] != null ? jsonEncode(row['metadata']) : null,
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
          'activity_log',
          where: 'group_id = ?',
          whereArgs: [groupId],
          orderBy: 'timestamp DESC',
        );
        return maps.map((m) => ActivityEntry.fromMap(m)).toList();
      },
    );
  }

  Future<void> insertActivity(ActivityEntry entry) async {
    await writeThrough(
      apiCall: () => api.upsert('activity_log', entry.toApiMap()),
      sqliteCall: (database) async {
        await database.insert('activity_log', entry.toMap());
      },
      syncTable: 'activity_log',
      syncId: entry.id,
    );
  }

  Future<void> deleteActivitiesByGroup(String groupId) async {
    await deleteThrough(
      apiCall: () => api.deleteWhere('activity_log', {'group_id': groupId}),
      sqliteCall: (database) async {
        await database.delete(
          'activity_log',
          where: 'group_id = ?',
          whereArgs: [groupId],
        );
      },
    );
  }
}
