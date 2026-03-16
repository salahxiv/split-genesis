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
/// Edge case (Issue #118): two expenses with the same amount, category and
/// group created within 2 seconds of each other are treated as a near-duplicate.
/// In this case the older entry (lower timestamp) is deduplicated and the newer
/// one is kept, preventing duplicate rows from appearing after reconnect.
class ConflictResolutionService {
  static final ConflictResolutionService instance =
      ConflictResolutionService._();
  ConflictResolutionService._();

  /// Maximum time difference (in seconds) for near-duplicate detection.
  static const int _nearDuplicateThresholdSeconds = 2;

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
  ///
  /// Near-duplicate detection (Issue #118): if two expenses (one local-only,
  /// one server-only) share the same [amount], [category] and [groupId] and
  /// were created within [_nearDuplicateThresholdSeconds] of each other, they
  /// are treated as duplicates. The newer entry wins and the older one is
  /// excluded from the result, preventing double-entries after offline sync.
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

    // Local-only rows: check for near-duplicates against server-only rows,
    // then keep if no duplicate found.
    final serverOnlyExpenses = serverRows
        .where((s) => !localMap.containsKey(s.id))
        .toList();

    for (final local in localRows) {
      if (serverMap.containsKey(local.id)) continue; // already handled above

      final nearDuplicate = _findNearDuplicate(local, serverOnlyExpenses);
      if (nearDuplicate != null) {
        // Near-duplicate found: keep the newer one, drop the older one.
        final localCreated = local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final serverCreated = nearDuplicate.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final keepLocal = localCreated.isAfter(serverCreated);
        debugPrint(
          '[LWW] Near-duplicate detected: local ${local.id} ↔ server ${nearDuplicate.id} '
          '— keeping ${keepLocal ? "local" : "server"}',
        );
        if (keepLocal) {
          // Replace the server entry already in result with the local one
          result.remove(nearDuplicate.id);
          result[local.id] = local;
        }
        // If server wins, the server entry was already added; skip local.
      } else {
        // No duplicate → local wins (pending sync)
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

  // ─── Near-duplicate detection (Issue #118) ──────────────────────────────────

  /// Returns the first server expense that is a near-duplicate of [local],
  /// or null if none is found.
  ///
  /// Two expenses are near-duplicates when they share the same [amount],
  /// [category] and [groupId] and their timestamps differ by at most
  /// [_nearDuplicateThresholdSeconds] seconds.
  Expense? _findNearDuplicate(Expense local, List<Expense> candidates) {
    final localTs = local.updatedAt;
    if (localTs == null) return null;

    for (final candidate in candidates) {
      if (candidate.amount != local.amount) continue;
      if (candidate.category != local.category) continue;
      if (candidate.groupId != local.groupId) continue;

      final candidateTs = candidate.updatedAt;
      if (candidateTs == null) continue;

      final diff = localTs.difference(candidateTs).inSeconds.abs();
      if (diff <= _nearDuplicateThresholdSeconds) {
        return candidate;
      }
    }
    return null;
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
