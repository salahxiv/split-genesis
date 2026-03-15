import 'package:flutter/foundation.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/groups/models/group.dart';

/// Implements Last-Write-Wins (LWW) conflict resolution strategy.
///
/// When a local change and a server change conflict (same record modified
/// in both places while offline), we compare `updated_at` timestamps:
/// - local.updatedAt > server.updatedAt → local wins (keep local version)
/// - server.updatedAt >= local.updatedAt → server wins (use server version)
///
/// This is intentionally simple and appropriate for a split-expense app:
/// the most recent edit wins. If two users edit simultaneously, the last
/// save wins — no merge, no manual resolution required.
class ConflictResolutionService {
  static final ConflictResolutionService instance =
      ConflictResolutionService._();
  ConflictResolutionService._();

  // ─── Expense ───────────────────────────────────────────────────────────────

  /// Resolves a conflict between a local and server [Expense].
  ///
  /// Returns the winning [Expense] (local or server) based on `updated_at`.
  /// If either timestamp is null, server wins (safe default).
  Expense resolveExpense({
    required Expense local,
    required Expense server,
  }) {
    final result = _resolveConflict(
      localUpdatedAt: local.updatedAt,
      serverUpdatedAt: server.updatedAt,
      entityType: 'expense',
      entityId: local.id,
    );
    return result == ConflictWinner.local ? local : server;
  }

  /// Resolves a list of expenses by comparing local cache with server rows.
  ///
  /// Returns a map of expense ID → winning Expense.
  /// Expenses only in [serverRows] are returned as-is.
  /// Expenses only in [localRows] are returned as pending (local wins by default).
  Map<String, Expense> resolveExpenses({
    required List<Expense> localRows,
    required List<Expense> serverRows,
  }) {
    final localMap = {for (final e in localRows) e.id: e};
    final serverMap = {for (final e in serverRows) e.id: e};

    final result = <String, Expense>{};

    // All server rows: check for local conflicts
    for (final server in serverRows) {
      final local = localMap[server.id];
      if (local == null) {
        // No local version → server wins
        result[server.id] = server;
      } else {
        result[server.id] = resolveExpense(local: local, server: server);
      }
    }

    // Local-only rows: not yet on server → local wins (pending sync)
    for (final local in localRows) {
      if (!serverMap.containsKey(local.id)) {
        result[local.id] = local;
      }
    }

    return result;
  }

  // ─── Group ─────────────────────────────────────────────────────────────────

  /// Resolves a conflict between a local and server [Group].
  ///
  /// Returns the winning [Group] based on `updated_at`.
  Group resolveGroup({
    required Group local,
    required Group server,
  }) {
    final result = _resolveConflict(
      localUpdatedAt: local.updatedAt,
      serverUpdatedAt: server.updatedAt,
      entityType: 'group',
      entityId: local.id,
    );
    return result == ConflictWinner.local ? local : server;
  }

  /// Resolves a list of groups by comparing local cache with server rows.
  Map<String, Group> resolveGroups({
    required List<Group> localRows,
    required List<Group> serverRows,
  }) {
    final localMap = {for (final g in localRows) g.id: g};
    final serverMap = {for (final g in serverRows) g.id: g};

    final result = <String, Group>{};

    for (final server in serverRows) {
      final local = localMap[server.id];
      if (local == null) {
        result[server.id] = server;
      } else {
        result[server.id] = resolveGroup(local: local, server: server);
      }
    }

    for (final local in localRows) {
      if (!serverMap.containsKey(local.id)) {
        result[local.id] = local;
      }
    }

    return result;
  }

  // ─── Generic Map-based resolution (for raw SQLite rows) ────────────────────

  /// Resolves a conflict between a local and server raw map row.
  ///
  /// Both maps must have an `updated_at` ISO-8601 string (nullable).
  /// Returns the winning map (either [local] or [server] by reference).
  Map<String, dynamic> resolveRow({
    required Map<String, dynamic> local,
    required Map<String, dynamic> server,
    required String entityType,
  }) {
    final w = resolveRowWinner(local: local, server: server, entityType: entityType);
    return w == ConflictWinner.local ? local : server;
  }

  /// Like [resolveRow] but returns the winner enum instead of the map.
  /// Use this when you need to distinguish local vs server without relying
  /// on [identical] reference equality across Map types.
  ConflictWinner resolveRowWinner({
    required Map<String, dynamic> local,
    required Map<String, dynamic> server,
    required String entityType,
  }) {
    final localUpdatedAt = _parseTimestamp(local['updated_at']);
    final serverUpdatedAt = _parseTimestamp(server['updated_at']);
    return _resolveConflict(
      localUpdatedAt: localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt,
      entityType: entityType,
      entityId: (local['id'] ?? 'unknown').toString(),
    );
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  ConflictWinner _resolveConflict({
    required DateTime? localUpdatedAt,
    required DateTime? serverUpdatedAt,
    required String entityType,
    required String entityId,
  }) {
    if (localUpdatedAt == null || serverUpdatedAt == null) {
      // Missing timestamp → server wins (safe default)
      debugPrint(
        '[LWW] $entityType $entityId: missing timestamp — server wins',
      );
      return ConflictWinner.server;
    }

    if (localUpdatedAt.isAfter(serverUpdatedAt)) {
      debugPrint(
        '[LWW] $entityType $entityId: local ($localUpdatedAt) > server ($serverUpdatedAt) — local wins',
      );
      return ConflictWinner.local;
    } else {
      debugPrint(
        '[LWW] $entityType $entityId: server ($serverUpdatedAt) >= local ($localUpdatedAt) — server wins',
      );
      return ConflictWinner.server;
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

/// Which version wins a conflict.
enum ConflictWinner { local, server }
