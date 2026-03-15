import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../database/supabase_data_source.dart';
import 'connectivity_service.dart';

/// SQLite-backed queue for offline pending changes.
///
/// When the device is offline, writes are stored here.
/// On reconnect, [flush] pushes them to Supabase in FIFO order
/// and returns the count of successfully synced changes.
///
/// Usage:
/// ```dart
/// // Enqueue on write (offline path):
/// await OfflineQueueService.instance.enqueue(
///   table: 'expenses',
///   entityId: expense.id,
///   operation: 'upsert',
///   payload: jsonEncode(expense.toApiMap()),
/// );
///
/// // Flush on reconnect (SyncService calls this):
/// final synced = await OfflineQueueService.instance.flush();
/// // SyncService then shows snackbar: '$synced Änderungen synchronisiert'
/// ```
class OfflineQueueService {
  static final OfflineQueueService instance = OfflineQueueService._();
  OfflineQueueService._();

  final _db = DatabaseHelper();
  final _api = SupabaseDataSource.instance;
  final _connectivity = ConnectivityService.instance;

  static const _maxRetries = 5;

  /// Stream that emits the count of changes synced after each successful flush.
  /// Consumers (e.g. app shell) listen to this to show the sync snackbar.
  final _syncedController = StreamController<int>.broadcast();
  Stream<int> get syncedStream => _syncedController.stream;

  // Note: The offline_queue table is created by DatabaseHelper (v10 migration)
  // to avoid a circular import (DatabaseHelper ↔ OfflineQueueService).

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Enqueue a pending change for later sync.
  ///
  /// Deduplicates by [table]+[entityId]+[operation]: if an entry already
  /// exists it is replaced with the newer [payload] (LWW at queue level).
  Future<void> enqueue({
    required String table,
    required String entityId,
    required String operation,
    required String payload,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'offline_queue',
      where: 'table_name = ? AND entity_id = ? AND operation = ?',
      whereArgs: [table, entityId, operation],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'offline_queue',
        {'payload': payload, 'created_at': now, 'retry_count': 0},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      debugPrint('[QUEUE] Updated entry: $table/$entityId');
    } else {
      await db.insert('offline_queue', {
        'table_name': table,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': now,
        'retry_count': 0,
      });
      debugPrint('[QUEUE] Enqueued: $table/$entityId');
    }
  }

  /// Returns the count of pending entries awaiting sync.
  Future<int> pendingCount() async {
    final db = await _db.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM offline_queue');
    return (result.first['cnt'] as num?)?.toInt() ?? 0;
  }

  /// Flush all pending entries to Supabase in FIFO order.
  ///
  /// - Successful entries are removed from the queue.
  /// - Failed entries increment retry_count; dropped after [_maxRetries].
  /// - Emits count on [syncedStream] so UI can show snackbar.
  /// - Returns number of successfully synced changes.
  Future<int> flush() async {
    if (!_connectivity.isOnline) {
      debugPrint('[QUEUE] flush(): offline — skipping');
      return 0;
    }

    final db = await _db.database;
    int synced = 0;

    List<Map<String, dynamic>> entries;
    try {
      entries = await db.query('offline_queue', orderBy: 'id ASC');
    } catch (e) {
      // offline_queue table might not exist yet (cold start before migration)
      debugPrint('[QUEUE] flush(): table not ready — $e');
      return 0;
    }

    debugPrint('[QUEUE] flush(): processing ${entries.length} pending entries');

    for (final row in entries) {
      final entryId = row['id'] as int;
      final table = row['table_name'] as String;
      final entityId = row['entity_id'] as String;
      final operation = row['operation'] as String;
      final payload = row['payload'] as String;
      final retryCount = (row['retry_count'] as num?)?.toInt() ?? 0;

      try {
        await _processEntry(
          table: table,
          entityId: entityId,
          operation: operation,
          payload: payload,
        );
        await db.delete('offline_queue', where: 'id = ?', whereArgs: [entryId]);
        synced++;
        debugPrint('[QUEUE] Synced: $table/$entityId');
      } catch (e) {
        debugPrint('[QUEUE] Error syncing $table/$entityId (retry $retryCount): $e');
        final newCount = retryCount + 1;
        if (newCount >= _maxRetries) {
          debugPrint('[QUEUE] Max retries — dropping $table/$entityId');
          await db
              .delete('offline_queue', where: 'id = ?', whereArgs: [entryId]);
        } else {
          await db.update(
            'offline_queue',
            {'retry_count': newCount},
            where: 'id = ?',
            whereArgs: [entryId],
          );
        }
      }
    }

    if (synced > 0) {
      _syncedController.add(synced);
      debugPrint('[QUEUE] flush() done: $synced synced');
    }

    return synced;
  }

  /// Clear all pending entries (e.g. on sign-out / account reset).
  Future<void> clear() async {
    final db = await _db.database;
    try {
      await db.delete('offline_queue');
    } catch (_) {}
    debugPrint('[QUEUE] Cleared all pending entries');
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  Future<void> _processEntry({
    required String table,
    required String entityId,
    required String operation,
    required String payload,
  }) async {
    switch (operation) {
      case 'upsert':
        final data = jsonDecode(payload) as Map<String, dynamic>;
        await _api.upsert(table, data);
        break;

      case 'delete':
        await _api.delete(table, entityId);
        break;

      case 'rpc':
        final params = jsonDecode(payload) as Map<String, dynamic>;
        final function = params['function'] as String;
        final args = (params['params'] as Map<String, dynamic>?) ?? {};
        await _api.rpc(function, params: args);
        break;

      default:
        debugPrint('[QUEUE] Unknown operation: $operation — dropping');
    }
  }
}
