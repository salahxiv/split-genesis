import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../database/supabase_data_source.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/offline_queue_service.dart';

enum SyncState { idle, syncing, error, offline }

/// Callback type for realtime change notifications.
/// Called with the groupId and the table that changed ('expenses' or 'settlements').
/// Only expenses and settlements are subscribed via Realtime; members, groups and
/// activity_log are loaded once on screen-open by their Riverpod providers.
typedef OnRealtimeChange = void Function(String groupId, String table);

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  final _db = DatabaseHelper();
  final _api = SupabaseDataSource.instance;
  final _connectivity = ConnectivityService.instance;
  final _queue = OfflineQueueService.instance;
  final _resolver = ConflictResolutionService.instance;
  bool _supabaseAvailable = false;

  /// Stream that emits synced-change counts (for snackbar display).
  /// Re-exposes OfflineQueueService.syncedStream for convenience.
  Stream<int> get syncedCountStream => _queue.syncedStream;

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState _currentState = SyncState.idle;
  SyncState get currentState => _currentState;

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Timer?> _debounceTimers = {};

  /// External callback for realtime changes — set by the app to invalidate
  /// Riverpod providers granularly per table.
  /// Only 'expenses' and 'settlements' are emitted; members/groups/activity_log
  /// are NOT subscribed via Realtime and must be loaded on screen-open.
  OnRealtimeChange? onRealtimeChange;

  void _setState(SyncState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> init() async {
    _supabaseAvailable = true;

    // Listen for connectivity changes
    _connectivity.onlineStream.listen((online) {
      if (!online) {
        _setState(SyncState.offline);
      } else {
        _setState(SyncState.idle);
        pushPendingChanges();
      }
    });
  }

  /// Flush all pending rows to Supabase when connectivity is restored.
  ///
  /// Uses Last-Write-Wins (LWW) conflict resolution: before pushing a local
  /// pending row, we fetch the current server version and compare `updated_at`.
  /// If server is newer, we discard the local pending change (server wins).
  /// If local is newer (or server has no version), we push local (local wins).
  ///
  /// After all sync is done, emits the synced count on [syncedCountStream]
  /// so the UI can show "X Änderungen synchronisiert" snackbar.
  Future<void> pushPendingChanges() async {
    if (!_supabaseAvailable) return;
    if (!_connectivity.isOnline) return;

    _setState(SyncState.syncing);
    int totalSynced = 0;

    try {
      final db = await _db.database;

      // ── Step 1: Flush OfflineQueue (new typed queue from OfflineQueueService) ─
      final queueSynced = await _queue.flush();
      totalSynced += queueSynced;

      // ── Step 2: Push legacy sync_status='pending' rows (with LWW check) ──────

      // Push pending groups
      final pendingGroups =
          await db.query('groups', where: "sync_status = 'pending'");
      for (final g in pendingGroups) {
        final groupId = g['id'] as String;
        await _pushPendingGroupWithLWW(db, groupId, g);
        totalSynced++;
      }

      // Push pending members
      final pendingMembers =
          await db.query('members', where: "sync_status = 'pending'");
      if (pendingMembers.isNotEmpty) {
        final rows = pendingMembers.map((m) {
          final map = Map<String, dynamic>.from(m);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('members', rows);
        for (final m in pendingMembers) {
          await db.update('members', {'sync_status': 'synced'},
              where: 'id = ?', whereArgs: [m['id']]);
        }
        totalSynced += pendingMembers.length;
      }

      // Push pending expenses with LWW conflict resolution
      final pendingExpenses =
          await db.query('expenses', where: "sync_status = 'pending'");
      for (final e in pendingExpenses) {
        final expenseId = e['id'] as String;
        final didSync = await _pushPendingExpenseWithLWW(db, expenseId, e);
        if (didSync) totalSynced++;
      }

      // Push pending settlements
      final pendingSettlements =
          await db.query('settlements', where: "sync_status = 'pending'");
      if (pendingSettlements.isNotEmpty) {
        final rows = pendingSettlements.map((s) {
          final map = Map<String, dynamic>.from(s);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('settlements', rows);
        for (final s in pendingSettlements) {
          await db.update('settlements', {'sync_status': 'synced'},
              where: 'id = ?', whereArgs: [s['id']]);
        }
        totalSynced += pendingSettlements.length;
      }

      // Push pending activity
      final pendingActivity =
          await db.query('activity_log', where: "sync_status = 'pending'");
      if (pendingActivity.isNotEmpty) {
        final rows = pendingActivity.map((a) {
          final map = Map<String, dynamic>.from(a);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('activity_log', rows);
        for (final a in pendingActivity) {
          await db.update('activity_log', {'sync_status': 'synced'},
              where: 'id = ?', whereArgs: [a['id']]);
        }
        totalSynced += pendingActivity.length;
      }

      _setState(SyncState.idle);
      debugPrint('[SYNC] pushPendingChanges done — $totalSynced synced');
    } catch (e) {
      debugPrint('[SYNC] pushPendingChanges error: $e');
      _setState(SyncState.error);
    }
  }

  /// Push a pending expense with LWW conflict resolution.
  ///
  /// Fetches the server version first and compares updated_at.
  /// Returns true if the expense was synced, false if server won (skipped).
  Future<bool> _pushPendingExpenseWithLWW(
    dynamic db,
    String expenseId,
    Map<String, dynamic> localRow,
  ) async {
    try {
      // Fetch server version for LWW comparison
      Map<String, dynamic>? serverRow;
      try {
        serverRow = await _api.selectSingle(
          'expenses',
          filters: {'id': expenseId},
        );
      } catch (_) {
        // Server row not found → local wins (new record)
        serverRow = null;
      }

      if (serverRow != null) {
        // LWW: compare updated_at. _resolver.resolveRow returns the winning map.
        final winner = _resolver.resolveRowWinner(
          local: localRow,
          server: serverRow,
          entityType: 'expense',
        );
        final serverWins = winner == ConflictWinner.server;
        if (serverWins) {
          // Server wins → discard local pending, update local cache with server
          debugPrint('[LWW] expense $expenseId: server wins — updating local cache');
          final updatedLocal = Map<String, dynamic>.from(serverRow);
          updatedLocal['sync_status'] = 'synced';
          await db.update('expenses', updatedLocal,
              where: 'id = ?', whereArgs: [expenseId]);
          return false;
        }
        // Local wins → proceed with push
        debugPrint('[LWW] expense $expenseId: local wins — pushing to server');
      }

      // Push local to server
      final expenseMap = Map<String, dynamic>.from(localRow);
      expenseMap.remove('sync_status');

      final splits = await db.query('expense_splits',
          where: 'expense_id = ?', whereArgs: [expenseId]);
      final payers = await db.query('expense_payers',
          where: 'expense_id = ?', whereArgs: [expenseId]);

      await _api.rpc('upsert_expense', params: {
        'p_expense': expenseMap,
        'p_splits': splits,
        'p_payers': payers,
      });
      await db.update('expenses', {'sync_status': 'synced'},
          where: 'id = ?', whereArgs: [expenseId]);
      return true;
    } catch (e) {
      debugPrint('[SYNC] Failed to push expense $expenseId: $e');
      return false;
    }
  }

  /// Push a pending group with LWW conflict resolution + member_user_ids merge.
  Future<void> _pushPendingGroupWithLWW(
    dynamic db,
    String groupId,
    Map<String, dynamic> localRow,
  ) async {
    try {
      // Fetch server version for LWW comparison
      Map<String, dynamic>? serverRow;
      try {
        final result = await _supabase
            .from('groups')
            .select()
            .eq('id', groupId)
            .maybeSingle();
        serverRow = result;
      } catch (_) {
        serverRow = null;
      }

      if (serverRow != null) {
        final winner = _resolver.resolveRowWinner(
          local: localRow,
          server: serverRow,
          entityType: 'group',
        );
        final serverWins = winner == ConflictWinner.server;
        if (serverWins) {
          // Server wins → update local cache
          debugPrint('[LWW] group $groupId: server wins — updating local cache');
          final updatedLocal = Map<String, dynamic>.from(serverRow);
          updatedLocal['sync_status'] = 'synced';
          await db.update('groups', updatedLocal,
              where: 'id = ?', whereArgs: [groupId]);
          return;
        }
        debugPrint('[LWW] group $groupId: local wins — pushing to server');
      }

      await _pushPendingGroup(db, groupId);
    } catch (e) {
      debugPrint('[SYNC] Failed to push group $groupId: $e');
    }
  }

  /// Push a single pending group with its member_user_ids logic.
  Future<void> _pushPendingGroup(dynamic db, String groupId) async {
    final groupMaps = await db.query('groups', where: 'id = ?', whereArgs: [groupId]);
    if (groupMaps.isEmpty) return;

    final g = groupMaps.first;
    final uid = AuthService.instance.userId;

    // Merge member_user_ids from Supabase
    List<String> memberUserIds = [];
    try {
      final existing = await _supabase
          .from('groups')
          .select('member_user_ids')
          .eq('id', groupId)
          .maybeSingle();
      if (existing != null && existing['member_user_ids'] != null) {
        memberUserIds = List<String>.from(existing['member_user_ids']);
      }
    } catch (_) {}
    if (uid != null && !memberUserIds.contains(uid)) {
      memberUserIds.add(uid);
    }

    final apiMap = Map<String, dynamic>.from(g);
    apiMap.remove('sync_status');
    apiMap['created_by_user_id'] = g['created_by_user_id'] ?? uid;
    apiMap['member_user_ids'] = memberUserIds;

    await _api.upsert('groups', apiMap);
    await db.update('groups', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [groupId]);
  }

  /// Debounced notification per (groupId, table) — prevents notification storms
  /// from rapid consecutive Postgres events on the same table.
  /// Debounce window: 1000ms (reduced from 500ms to further cut redundant refreshes).
  void _debouncedNotify(String groupId, String table) {
    final key = '$groupId:$table';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 1000), () {
      debugPrint('[SYNC] realtime change — group=$groupId table=$table — notifying');
      onRealtimeChange?.call(groupId, table);
    });
  }

  /// Subscribe to Realtime Postgres changes for a group.
  ///
  /// Only 'expenses' and 'settlements' are subscribed — these are the tables
  /// whose changes need instant UI updates (balance recalculation).
  /// 'members', 'groups' and 'activity_log' are intentionally excluded:
  /// they change rarely and are loaded once when the screen opens.
  void listenToGroup(String groupId) {
    if (!_supabaseAvailable) return;
    _channels[groupId]?.unsubscribe();

    final channel = _supabase.channel('group-$groupId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expenses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId, 'expenses'),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'settlements',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId, 'settlements'),
      )
      ..subscribe();

    _channels[groupId] = channel;
  }

  void stopListening(String groupId) {
    // Cancel all debounce timers for this group
    final keysToRemove = _debounceTimers.keys
        .where((k) => k.startsWith('$groupId:'))
        .toList();
    for (final k in keysToRemove) {
      _debounceTimers[k]?.cancel();
      _debounceTimers.remove(k);
    }
    _channels[groupId]?.unsubscribe();
    _channels.remove(groupId);
  }

  Future<Map<String, dynamic>?> findGroupByShareCode(String code) async {
    if (!_supabaseAvailable) return null;
    if (!_connectivity.isOnline) return null;

    final result = await _supabase
        .from('groups')
        .select()
        .eq('share_code', code.toUpperCase())
        .limit(1)
        .maybeSingle();
    return result;
  }

  Future<Map<String, dynamic>?> findGroupById(String groupId) async {
    if (!_supabaseAvailable) return null;
    if (!_connectivity.isOnline) return null;

    final result = await _supabase
        .from('groups')
        .select()
        .eq('id', groupId)
        .limit(1)
        .maybeSingle();
    return result;
  }

  Future<void> addUserToGroup(String groupId) async {
    if (!_supabaseAvailable) return;
    final uid = AuthService.instance.userId;
    if (uid == null) return;

    final groupData = await _supabase
        .from('groups')
        .select('member_user_ids')
        .eq('id', groupId)
        .single();

    final List<String> memberUserIds = List<String>.from(groupData['member_user_ids'] ?? []);
    if (!memberUserIds.contains(uid)) {
      memberUserIds.add(uid);
      await _supabase
          .from('groups')
          .update({'member_user_ids': memberUserIds})
          .eq('id', groupId);
    }
  }

  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
    _stateController.close();
  }
}
