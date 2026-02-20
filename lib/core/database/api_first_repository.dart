import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../services/connectivity_service.dart';
import 'database_helper.dart';
import 'supabase_data_source.dart';

/// Mixin that provides "try API first, cache to SQLite, fallback to SQLite" pattern.
///
/// Repositories mix this in and call [fetchAndCache] for reads
/// and [writeThrough] for writes.
mixin ApiFirstRepository {
  late final DatabaseHelper db;
  late final SupabaseDataSource api;
  late final ConnectivityService connectivity;

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
  /// [cacheWriter] writes each row to SQLite.
  /// [sqliteCall] reads from local SQLite cache.
  Future<List<T>> fetchAndCache<T>({
    required Future<List<Map<String, dynamic>>> Function() apiCall,
    required Future<void> Function(Database db, List<Map<String, dynamic>> rows) cacheWriter,
    required Future<List<T>> Function() sqliteCall,
  }) async {
    if (!connectivity.isOnline) {
      return sqliteCall();
    }

    try {
      final rows = await apiCall();
      // Cache to SQLite in background
      final database = await db.database;
      await cacheWriter(database, rows);
      // Re-read from SQLite for consistent model parsing
      return sqliteCall();
    } catch (e) {
      debugPrint('[API-FIRST] fetchAndCache error, falling back to SQLite: $e');
      return sqliteCall();
    }
  }

  /// Read single item: tries API, caches, falls back to SQLite.
  Future<T?> fetchSingleAndCache<T>({
    required Future<Map<String, dynamic>?> Function() apiCall,
    required Future<void> Function(Database db, Map<String, dynamic> row) cacheWriter,
    required Future<T?> Function() sqliteCall,
  }) async {
    if (!connectivity.isOnline) {
      return sqliteCall();
    }

    try {
      final row = await apiCall();
      if (row == null) return null;
      final database = await db.database;
      await cacheWriter(database, row);
      return sqliteCall();
    } catch (e) {
      debugPrint('[API-FIRST] fetchSingleAndCache error, falling back to SQLite: $e');
      return sqliteCall();
    }
  }

  /// Write: tries API first (sync_status='synced'), falls back to SQLite-only (sync_status='pending').
  ///
  /// SQLite always gets written to, either as confirmed cache or pending-sync queue.
  Future<void> writeThrough({
    required Future<void> Function() apiCall,
    required Future<void> Function(Database db) sqliteCall,
    String? syncTable,
    String? syncId,
  }) async {
    final database = await db.database;

    if (!connectivity.isOnline) {
      // Offline: write to SQLite with pending status
      await sqliteCall(database);
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
