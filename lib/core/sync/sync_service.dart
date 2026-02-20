import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../database/supabase_data_source.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';

enum SyncState { idle, syncing, error, offline }

/// Callback type for realtime change notifications.
/// Called with the groupId that changed.
typedef OnGroupChanged = void Function(String groupId);

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  final _db = DatabaseHelper();
  final _api = SupabaseDataSource.instance;
  final _connectivity = ConnectivityService.instance;
  bool _supabaseAvailable = false;

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState _currentState = SyncState.idle;
  SyncState get currentState => _currentState;

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Timer?> _debounceTimers = {};

  /// External callback for realtime changes — set by the app to invalidate Riverpod providers.
  OnGroupChanged? onGroupChanged;

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
  Future<void> pushPendingChanges() async {
    if (!_supabaseAvailable) return;
    if (!_connectivity.isOnline) return;

    _setState(SyncState.syncing);
    try {
      final db = await _db.database;

      // Push pending groups
      final pendingGroups = await db.query('groups', where: "sync_status = 'pending'");
      for (final g in pendingGroups) {
        final groupId = g['id'] as String;
        await _pushPendingGroup(db, groupId);
      }

      // Push pending members (in groups that are already synced)
      final pendingMembers = await db.query('members', where: "sync_status = 'pending'");
      if (pendingMembers.isNotEmpty) {
        final rows = pendingMembers.map((m) {
          final map = Map<String, dynamic>.from(m);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('members', rows);
        for (final m in pendingMembers) {
          await db.update('members', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [m['id']]);
        }
      }

      // Push pending expenses
      final pendingExpenses = await db.query('expenses', where: "sync_status = 'pending'");
      for (final e in pendingExpenses) {
        final expenseId = e['id'] as String;
        final expenseMap = Map<String, dynamic>.from(e);
        expenseMap.remove('sync_status');

        final splits = await db.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
        final payers = await db.query('expense_payers', where: 'expense_id = ?', whereArgs: [expenseId]);

        await _api.rpc('upsert_expense', params: {
          'p_expense': expenseMap,
          'p_splits': splits,
          'p_payers': payers,
        });
        await db.update('expenses', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [expenseId]);
      }

      // Push pending settlements
      final pendingSettlements = await db.query('settlements', where: "sync_status = 'pending'");
      if (pendingSettlements.isNotEmpty) {
        final rows = pendingSettlements.map((s) {
          final map = Map<String, dynamic>.from(s);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('settlements', rows);
        for (final s in pendingSettlements) {
          await db.update('settlements', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [s['id']]);
        }
      }

      // Push pending activity
      final pendingActivity = await db.query('activity_log', where: "sync_status = 'pending'");
      if (pendingActivity.isNotEmpty) {
        final rows = pendingActivity.map((a) {
          final map = Map<String, dynamic>.from(a);
          map.remove('sync_status');
          return map;
        }).toList();
        await _api.upsertMany('activity_log', rows);
        for (final a in pendingActivity) {
          await db.update('activity_log', {'sync_status': 'synced'}, where: 'id = ?', whereArgs: [a['id']]);
        }
      }

      _setState(SyncState.idle);
      debugPrint('[SYNC] pushPendingChanges done');
    } catch (e) {
      debugPrint('[SYNC] pushPendingChanges error: $e');
      _setState(SyncState.error);
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

  void _debouncedNotify(String groupId) {
    _debounceTimers[groupId]?.cancel();
    _debounceTimers[groupId] = Timer(const Duration(milliseconds: 500), () {
      debugPrint('[SYNC] realtime change for group $groupId — notifying');
      onGroupChanged?.call(groupId);
    });
  }

  void listenToGroup(String groupId) {
    if (!_supabaseAvailable) return;
    _channels[groupId]?.unsubscribe();

    final channel = _supabase.channel('group-$groupId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'groups',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'expenses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId),
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
        callback: (_) => _debouncedNotify(groupId),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'activity_log',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (_) => _debouncedNotify(groupId),
      )
      ..subscribe();

    _channels[groupId] = channel;
  }

  void stopListening(String groupId) {
    _debounceTimers[groupId]?.cancel();
    _debounceTimers.remove(groupId);
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
