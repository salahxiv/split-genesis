import 'package:sqflite/sqflite.dart';
import '../../../core/database/api_first_repository.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/supabase_data_source.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/group.dart';

class GroupRepository with ApiFirstRepository {
  GroupRepository({DatabaseHelper? db, SupabaseDataSource? api, ConnectivityService? connectivity}) {
    initDeps(db: db, api: api, connectivity: connectivity);
  }
  Future<List<Group>> getAllGroups() async {
    return fetchAndCache(
      apiCall: () => api.select('groups', orderBy: 'created_at'),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          batch.insert(
            'groups',
            {
              'id': row['id'],
              'name': row['name'],
              'share_code': row['share_code'],
              'created_at': row['created_at'],
              'updated_at': row['updated_at'],
              'created_by_user_id': row['created_by_user_id'],
              'currency': row['currency'] ?? 'USD',
              'type': row['type'] ?? 'other',
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query('groups', orderBy: 'created_at DESC');
        return maps.map((map) => Group.fromMap(map)).toList();
      },
    );
  }

  Future<Group> getGroup(String id) async {
    final result = await fetchSingleAndCache(
      apiCall: () => api.selectSingle('groups', filters: {'id': id}),
      cacheWriter: (database, row) async {
        await database.insert(
          'groups',
          {
            'id': row['id'],
            'name': row['name'],
            'share_code': row['share_code'],
            'created_at': row['created_at'],
            'updated_at': row['updated_at'],
            'created_by_user_id': row['created_by_user_id'],
            'currency': row['currency'] ?? 'USD',
            'type': row['type'] ?? 'other',
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query('groups', where: 'id = ?', whereArgs: [id]);
        if (maps.isEmpty) return null;
        return Group.fromMap(maps.first);
      },
    );
    if (result == null) throw StateError('Group not found: $id');
    return result;
  }

  Future<void> insertGroup(Group group) async {
    final uid = AuthService.instance.userId;
    final apiMap = group.toApiMap();
    apiMap['created_by_user_id'] = group.createdByUserId ?? uid;
    apiMap['member_user_ids'] = uid != null ? [uid] : [];

    await writeThrough(
      apiCall: () => api.upsert('groups', apiMap),
      sqliteCall: (database) async {
        await database.insert('groups', group.toMap());
      },
      syncTable: 'groups',
      syncId: group.id,
    );
  }

  Future<void> updateGroupName(String id, String name) async {
    // BUG-05 fix: fetch the full group first so we can do a complete upsert.
    // A partial upsert (id + name only) may violate NOT NULL constraints on
    // the server or silently null out required fields like currency/type.
    Group? existingGroup;
    try {
      existingGroup = await getGroup(id);
    } catch (_) {
      // If we can't fetch the group (e.g. offline), fall through to SQLite-only update
    }

    final now = DateTime.now();
    await writeThrough(
      apiCall: () async {
        if (existingGroup != null) {
          final fullMap = existingGroup.copyWith(name: name, updatedAt: now).toApiMap();
          await api.upsert('groups', fullMap);
        } else {
          // Partial update as last resort — only name + updated_at
          await api.upsert('groups', {
            'id': id,
            'name': name,
            'updated_at': now.toIso8601String(),
          });
        }
      },
      sqliteCall: (database) async {
        await database.update(
          'groups',
          {'name': name, 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      },
      syncTable: 'groups',
      syncId: id,
    );
  }

  Future<void> deleteGroup(String id) async {
    await deleteThrough(
      apiCall: () => api.delete('groups', id),
      sqliteCall: (database) async {
        await database.delete('groups', where: 'id = ?', whereArgs: [id]);
      },
    );
  }

  Future<Group?> getGroupByShareCode(String code) async {
    return fetchSingleAndCache(
      apiCall: () => api.selectSingle(
        'groups',
        filters: {'share_code': code.toUpperCase()},
      ),
      cacheWriter: (database, row) async {
        await database.insert(
          'groups',
          {
            'id': row['id'],
            'name': row['name'],
            'share_code': row['share_code'],
            'created_at': row['created_at'],
            'updated_at': row['updated_at'],
            'created_by_user_id': row['created_by_user_id'],
            'currency': row['currency'] ?? 'USD',
            'type': row['type'] ?? 'other',
            'sync_status': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query(
          'groups',
          where: 'share_code = ?',
          whereArgs: [code.toUpperCase()],
        );
        if (maps.isEmpty) return null;
        return Group.fromMap(maps.first);
      },
    );
  }
}
