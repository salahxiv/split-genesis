import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../services/connectivity_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/offline_queue_service.dart';
import 'database_helper.dart';
import 'supabase_data_source.dart';

/// Mixin that provides "try API first, cache to SQLite, fallback to SQLite" pattern.
///
/// Repositories mix this in and call [fetchAndCache] for reads
/// and [writeThrough] for writes.
///
/// Conflict resolution: [fetchAndCache] applies Last-Write-Wins (LWW) when
/// merging server rows into the local SQLite cache. [writeThrough] enqueues
/// offline writes to [OfflineQueueService] for deferred sync on reconnect.
mixin ApiFirstRepository {
  late final DatabaseHelper db;
  late final SupabaseDataSource api;
  late final ConnectivityService connectivity;

  // Shared singletons — not injected (no interface needed for conflict/queue)
  final _resolver = ConflictResolutionService.instance;
  final _queue = OfflineQueueService.instance;

  void initDeps({
    DatabaseHelper? db,
    SupabaseDataSource? api,
    ConnectivityService? connectivity,
  }) {
    this.db = db ?? DatabaseHelper();
    this.api = api ?? SupabaseDataSource.instance;
    this.connectivity = connectivity ?? ConnectivityService.instance;
  }

  /// Read: tries API first, caches results to SQLite, falls back to SQLite on error/offline.
  ///
  /// [apiCall] fetches from Supabase and returns raw rows.
  /// [cacheWriter] writes each row to SQLite (after LWW resolution).
  /// [sqliteCall] reads from local SQLite cache.
  ///
  /// LWW conflict resolution: before caching a server row, [fetchAndCache]
  /// checks the local SQLite version. If local.updated_at > server.updated_at,
  /// the local version is preserved and the server row is skipped.
  /// This prevents stale server data from overwriting a locally-pending change
  /// that hasn't been pushed yet (will be pushed by SyncService on next tick).
  ///
  /// [entityType] is used for LWW debug logging (e.g. 'expense', 'group').
  Future<List<T>> fetchAndCache<T>({
    required Future<List<Map<String, dynamic>>> Function() apiCall,
    required Future<void> Function(Database db, List<Map<String, dynamic>> rows) cacheWriter,
    required Future<List<T>> Function() sqliteCall,
    String table = '',    // Optional: enables LWW conflict resolution on fetch
    String entityType = 'row',
  }) async {
    if (!connectivity.isOnline) {
      return sqliteCall();
    }

    try {
      final serverRows = await apiCall();
      final database = await db.database;

      // LWW: filter out server rows where local version is newer (only if table is known)
      final rowsToCache = <Map<String, dynamic>>[];

      // Pre-load all local rows by ID to avoid N+1 queries
      Map<String, Map<String, dynamic>> localMap = {};
      if (table.isNotEmpty && serverRows.isNotEmpty) {
        final serverIds = serverRows
            .map((r) => r['id']?.toString())
            .where((id) => id != null)
            .toList();
        if (serverIds.isNotEmpty) {
          final placeholders = List.filled(serverIds.length, '?').join(',');
          final localRows = await database.query(
            table,
            where: 'id IN ($placeholders)',
            whereArgs: serverIds,
          );
          localMap = {for (var row in localRows) row['id'] as String: row};
        }
      }

      for (final serverRow in serverRows) {
        final id = serverRow['id']?.toString();
        if (id == null || table.isEmpty) {
          rowsToCache.add(serverRow);
          continue;
        }

        final localRow = localMap[id];
        if (localRow == null) {
          // No local version → accept server row
          rowsToCache.add(serverRow);
        } else {
          // Only apply LWW if local row is pending sync (offline change exists)
          final isPending = localRow['sync_status'] == 'pending';
          if (isPending) {
            final winner = _resolver.resolveRowWinner(
              local: localRow,
              server: serverRow,
              entityType: entityType,
            );
            final localWins = winner == ConflictWinner.local;
            if (localWins) {
              // Local wins: skip server row, keep local pending change
              debugPrint('[LWW-FETCH] $entityType $id: local pending wins — skip server row');
              continue;
            }
          }
          rowsToCache.add(serverRow);
        }
      }

      await cacheWriter(database, rowsToCache);
      // Re-read from SQLite for consistent model parsing
      return sqliteCall();
    } catch (e) {
      debugPrint('[API-FIRST] fetchAndCache error, falling back to SQLite: $e');
      return sqliteCall();
    }
  }

  /// Read single item: tries API, caches (with LWW), falls back to SQLite.
  Future<T?> fetchSingleAndCache<T>({
    required Future<Map<String, dynamic>?> Function() apiCall,
    required Future<void> Function(Database db, Map<String, dynamic> row) cacheWriter,
    required Future<T?> Function() sqliteCall,
    String table = '',
    String entityType = 'row',
  }) async {
    if (!connectivity.isOnline) {
      return sqliteCall();
    }

    try {
      final serverRow = await apiCall();
      if (serverRow == null) return null;
      final database = await db.database;

      // LWW check for single fetch
      final id = serverRow['id']?.toString();
      if (id != null && table.isNotEmpty) {
        final localResults = await database.query(
          table,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (localResults.isNotEmpty) {
          final localRow = localResults.first;
          final isPending = localRow['sync_status'] == 'pending';
          if (isPending) {
            final winner = _resolver.resolveRowWinner(
              local: localRow,
              server: serverRow,
              entityType: entityType,
            );
            final localWins = winner == ConflictWinner.local;
            if (localWins) {
              debugPrint('[LWW-FETCH] $entityType $id: local pending wins — skip server update');
              return sqliteCall();
            }
          }
        }
      }

      await cacheWriter(database, serverRow);
      return sqliteCall();
    } catch (e) {
      debugPrint('[API-FIRST] fetchSingleAndCache error, falling back to SQLite: $e');
      return sqliteCall();
    }
  }

  /// Write: tries API first (sync_status='synced'), falls back to SQLite-only (sync_status='pending').
  ///
  /// SQLite always gets written to, either as confirmed cache or pending-sync queue.
  ///
  /// Offline enhancement: when offline, the write is also enqueued in
  /// [OfflineQueueService] so it will be replayed on next reconnect.
  /// [queuePayload] is the JSON payload to enqueue (optional). If not
  /// provided, offline writes are still stored in SQLite via sync_status='pending'
  /// but won't be added to the typed offline queue.
  Future<void> writeThrough({
    required Future<void> Function() apiCall,
    required Future<void> Function(Database db) sqliteCall,
    String? syncTable,
    String? syncId,
    // Optional: typed offline-queue parameters for explicit queue-based retry
    String? queuePayload,     // JSON string of the row to upsert
    String? queueOperation,   // 'upsert' | 'delete' | 'rpc'
  }) async {
    final database = await db.database;

    if (!connectivity.isOnline) {
      // Offline: write to SQLite with pending status
      await sqliteCall(database);

      // Also enqueue for deferred sync if caller provided a payload
      if (syncTable != null && syncId != null && queuePayload != null) {
        await _queue.enqueue(
          table: syncTable,
          entityId: syncId,
          operation: queueOperation ?? 'upsert',
          payload: queuePayload,
        );
      }
      return;
    }

    try {
      // Online: write to API first
      await apiCall();
      // Then cache to SQLite with synced status
      await sqliteCall(database);
      // Mark as synced
      if (syncTable != null && syncId != null) {
        await database.update(
          syncTable,
          {'sync_status': 'synced'},
          where: 'id = ?',
          whereArgs: [syncId],
        );
      }
    } catch (e) {
      debugPrint('[API-FIRST] writeThrough API error, writing to SQLite only: $e');
      // Fallback: write to SQLite with pending status (default from model)
      await sqliteCall(database);

      // Enqueue for retry on reconnect
      if (syncTable != null && syncId != null && queuePayload != null) {
        await _queue.enqueue(
          table: syncTable,
          entityId: syncId,
          operation: queueOperation ?? 'upsert',
          payload: queuePayload,
        );
      }
    }
  }

  /// Delete: tries API first, always deletes from SQLite.
  Future<void> deleteThrough({
    required Future<void> Function() apiCall,
    required Future<void> Function(Database db) sqliteCall,
  }) async {
    final database = await db.database;

    if (connectivity.isOnline) {
      try {
        await apiCall();
      } catch (e) {
        debugPrint('[API-FIRST] deleteThrough API error: $e');
      }
    }

    await sqliteCall(database);
  }
}
