import 'package:sqflite/sqflite.dart';
import '../../../core/database/api_first_repository.dart';
import '../models/member.dart';

class MemberRepository with ApiFirstRepository {
  Future<List<Member>> getMembersByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select('members', filters: {'group_id': groupId}),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          batch.insert(
            'members',
            {
              'id': row['id'],
              'name': row['name'],
              'group_id': row['group_id'],
              'updated_at': row['updated_at'],
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
          'members',
          where: 'group_id = ?',
          whereArgs: [groupId],
        );
        return maps.map((map) => Member.fromMap(map)).toList();
      },
    );
  }

  Future<Member> getMember(String id) async {
    final result = await fetchSingleAndCache(
      apiCall: () => api.selectSingle('members', filters: {'id': id}),
      cacheWriter: (database, row) async {
        await database.insert(
          'members',
          {
            'id': row['id'],
            'name': row['name'],
            'group_id': row['group_id'],
            'updated_at': row['updated_at'],
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query('members', where: 'id = ?', whereArgs: [id]);
        if (maps.isEmpty) return null;
        return Member.fromMap(maps.first);
      },
    );
    if (result == null) throw StateError('Member not found: $id');
    return result;
  }

  Future<void> insertMember(Member member) async {
    await writeThrough(
      apiCall: () => api.upsert('members', member.toApiMap()),
      sqliteCall: (database) async {
        await database.insert('members', member.toMap());
      },
      syncTable: 'members',
      syncId: member.id,
    );
  }

  Future<void> deleteMember(String id) async {
    await deleteThrough(
      apiCall: () => api.delete('members', id),
      sqliteCall: (database) async {
        await database.delete('members', where: 'id = ?', whereArgs: [id]);
      },
    );
  }
}
