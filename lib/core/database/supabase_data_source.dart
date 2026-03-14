import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataSource {
  static final SupabaseDataSource instance = SupabaseDataSource._();
  SupabaseDataSource._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
  }) async {
    final sw = Stopwatch()..start();
    var query = _client.from(table).select();

    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    List<dynamic> result;
    if (orderBy != null) {
      result = await query.order(orderBy, ascending: ascending);
    } else {
      result = await query;
    }

    debugPrint('[API] SELECT $table (${filters ?? ''}): ${sw.elapsedMilliseconds}ms, ${result.length} rows');
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> selectSingle(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    var query = _client.from(table).select();
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    return await query.maybeSingle();
  }

  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final sw = Stopwatch()..start();
    await _client.from(table).upsert(data);
    debugPrint('[API] UPSERT $table (${data['id']}): ${sw.elapsedMilliseconds}ms');
  }

  Future<void> upsertMany(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final sw = Stopwatch()..start();
    await _client.from(table).upsert(rows);
    debugPrint('[API] UPSERT $table (${rows.length} rows): ${sw.elapsedMilliseconds}ms');
  }

  Future<void> delete(String table, String id) async {
    final sw = Stopwatch()..start();
    await _client.from(table).delete().eq('id', id);
    debugPrint('[API] DELETE $table ($id): ${sw.elapsedMilliseconds}ms');
  }

  Future<void> deleteWhere(String table, Map<String, dynamic> filters) async {
    final sw = Stopwatch()..start();
    var query = _client.from(table).delete();
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    await query;
    debugPrint('[API] DELETE $table ($filters): ${sw.elapsedMilliseconds}ms');
  }

  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params}) async {
    final sw = Stopwatch()..start();
    final result = await _client.rpc(functionName, params: params);
    debugPrint('[API] RPC $functionName: ${sw.elapsedMilliseconds}ms');
    return result as T;
  }

  /// Sync a batch of comments to Supabase (upsert, last-write-wins for Beta).
  Future<void> syncComments(List<Map<String, dynamic>> comments) async {
    if (comments.isEmpty) return;
    final sw = Stopwatch()..start();
    // Strip sync_status — Supabase table does not have that column
    final rows = comments.map((c) {
      final m = Map<String, dynamic>.from(c);
      m.remove('sync_status');
      return m;
    }).toList();
    await _client.from('expense_comments').upsert(rows);
    debugPrint('[API] syncComments (${rows.length} rows): ${sw.elapsedMilliseconds}ms');
  }

  /// Fetch comments for a given expense from Supabase.
  Future<List<Map<String, dynamic>>> fetchComments(String expenseId) async {
    final sw = Stopwatch()..start();
    final result = await _client
        .from('expense_comments')
        .select()
        .eq('expense_id', expenseId)
        .order('created_at', ascending: true);
    debugPrint('[API] fetchComments expense=$expenseId: ${sw.elapsedMilliseconds}ms, ${result.length} rows');
    return result.cast<Map<String, dynamic>>();
  }
}
