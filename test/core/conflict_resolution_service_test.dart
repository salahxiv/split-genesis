import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/services/conflict_resolution_service.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/groups/models/group.dart';

/// Builds an [Expense] fixture. [updatedAt] drives Last-Write-Wins;
/// [amountCents]/[category]/[groupId] drive near-duplicate detection.
Expense _expense({
  required String id,
  int amountCents = 5000,
  String category = 'food',
  String groupId = 'g1',
  DateTime? updatedAt,
}) {
  return Expense(
    id: id,
    description: 'desc-$id',
    amountCents: amountCents,
    paidById: 'p1',
    groupId: groupId,
    createdAt: DateTime(2024, 1, 1),
    expenseDate: DateTime(2024, 1, 1),
    category: category,
    updatedAt: updatedAt,
  );
}

Group _group({required String id, DateTime? updatedAt}) {
  return Group(
    id: id,
    name: 'group-$id',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt,
  );
}

void main() {
  final service = ConflictResolutionService.instance;

  final t0 = DateTime(2024, 6, 1, 12, 0, 0);
  final tLater = DateTime(2024, 6, 1, 12, 0, 30);

  group('resolveExpense — Last-Write-Wins by updatedAt', () {
    test('local newer → local wins', () {
      final local = _expense(id: 'e1', updatedAt: tLater);
      final server = _expense(id: 'e1', updatedAt: t0);
      expect(service.resolveExpense(local: local, server: server), same(local));
    });

    test('server newer → server wins', () {
      final local = _expense(id: 'e1', updatedAt: t0);
      final server = _expense(id: 'e1', updatedAt: tLater);
      expect(service.resolveExpense(local: local, server: server), same(server));
    });

    test('equal timestamps → server wins (>= semantics)', () {
      final local = _expense(id: 'e1', updatedAt: t0);
      final server = _expense(id: 'e1', updatedAt: t0);
      expect(service.resolveExpense(local: local, server: server), same(server));
    });

    test('local timestamp null → server wins (safe default)', () {
      final local = _expense(id: 'e1', updatedAt: null);
      final server = _expense(id: 'e1', updatedAt: t0);
      expect(service.resolveExpense(local: local, server: server), same(server));
    });

    test('server timestamp null → server wins (safe default)', () {
      final local = _expense(id: 'e1', updatedAt: tLater);
      final server = _expense(id: 'e1', updatedAt: null);
      expect(service.resolveExpense(local: local, server: server), same(server));
    });

    test('both timestamps null → server wins', () {
      final local = _expense(id: 'e1', updatedAt: null);
      final server = _expense(id: 'e1', updatedAt: null);
      expect(service.resolveExpense(local: local, server: server), same(server));
    });
  });

  group('resolveGroup — Last-Write-Wins', () {
    test('local newer → local wins', () {
      final local = _group(id: 'g1', updatedAt: tLater);
      final server = _group(id: 'g1', updatedAt: t0);
      expect(service.resolveGroup(local: local, server: server), same(local));
    });

    test('server newer → server wins', () {
      final local = _group(id: 'g1', updatedAt: t0);
      final server = _group(id: 'g1', updatedAt: tLater);
      expect(service.resolveGroup(local: local, server: server), same(server));
    });
  });

  group('resolveRowWinner — raw map rows with ISO-8601 timestamps', () {
    test('local newer ISO string → local wins', () {
      final winner = service.resolveRowWinner(
        local: {'id': 'r1', 'updated_at': tLater.toIso8601String()},
        server: {'id': 'r1', 'updated_at': t0.toIso8601String()},
        entityType: 'expense',
      );
      expect(winner, ConflictWinner.local);
    });

    test('malformed local timestamp → parsed as null → server wins', () {
      final winner = service.resolveRowWinner(
        local: {'id': 'r1', 'updated_at': 'not-a-date'},
        server: {'id': 'r1', 'updated_at': t0.toIso8601String()},
        entityType: 'expense',
      );
      expect(winner, ConflictWinner.server);
    });

    test('DateTime value passed directly (not string) is handled', () {
      final winner = service.resolveRowWinner(
        local: {'id': 'r1', 'updated_at': tLater},
        server: {'id': 'r1', 'updated_at': t0},
        entityType: 'group',
      );
      expect(winner, ConflictWinner.local);
    });

    test('missing updated_at key → null → server wins', () {
      final winner = service.resolveRowWinner(
        local: {'id': 'r1'},
        server: {'id': 'r1', 'updated_at': t0.toIso8601String()},
        entityType: 'expense',
      );
      expect(winner, ConflictWinner.server);
    });

    test('resolveRow returns the winning map by reference', () {
      final local = {'id': 'r1', 'updated_at': tLater.toIso8601String()};
      final server = {'id': 'r1', 'updated_at': t0.toIso8601String()};
      expect(
        service.resolveRow(local: local, server: server, entityType: 'expense'),
        same(local),
      );
    });
  });

  group('resolveExpenses — list merge', () {
    test('server-only expense is included as server version', () {
      final server = _expense(id: 's1', updatedAt: t0);
      final result = service.resolveExpenses(localRows: [], serverRows: [server]);
      expect(result.keys, ['s1']);
      expect(result['s1'], same(server));
    });

    test('matched id, local newer → local version kept', () {
      final local = _expense(id: 'e1', updatedAt: tLater);
      final server = _expense(id: 'e1', updatedAt: t0);
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result['e1'], same(local));
    });

    test('matched id, server newer → server version kept', () {
      final local = _expense(id: 'e1', updatedAt: t0);
      final server = _expense(id: 'e1', updatedAt: tLater);
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result['e1'], same(server));
    });

    test('local-only with no duplicate → kept (pending)', () {
      final local = _expense(id: 'local-only', updatedAt: t0);
      final result =
          service.resolveExpenses(localRows: [local], serverRows: []);
      expect(result['local-only'], same(local));
    });
  });

  group('resolveExpenses — near-duplicate detection (Issue #118)', () {
    test('near-duplicate within threshold, local newer → local kept, '
        'server dropped', () {
      final server = _expense(id: 'srv', updatedAt: t0);
      final local = _expense(
        id: 'loc',
        updatedAt: t0.add(const Duration(seconds: 1)),
      );
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isFalse);
    });

    test('near-duplicate within threshold, server newer → server kept, '
        'local dropped', () {
      final server = _expense(
        id: 'srv',
        updatedAt: t0.add(const Duration(seconds: 1)),
      );
      final local = _expense(id: 'loc', updatedAt: t0);
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('srv'), isTrue);
      expect(result.containsKey('loc'), isFalse);
    });

    test('exactly at threshold (2s) → treated as near-duplicate', () {
      final server = _expense(id: 'srv', updatedAt: t0);
      final local = _expense(
        id: 'loc',
        updatedAt: t0.add(const Duration(seconds: 2)),
      );
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      // local newer → local kept, server deduped
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isFalse);
    });

    test('beyond threshold (3s) → NOT a duplicate, both kept', () {
      final server = _expense(id: 'srv', updatedAt: t0);
      final local = _expense(
        id: 'loc',
        updatedAt: t0.add(const Duration(seconds: 3)),
      );
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isTrue);
    });

    test('same amount but different category → NOT a duplicate', () {
      final server = _expense(id: 'srv', category: 'food', updatedAt: t0);
      final local = _expense(
        id: 'loc',
        category: 'travel',
        updatedAt: t0.add(const Duration(seconds: 1)),
      );
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isTrue);
    });

    test('different amount → NOT a duplicate', () {
      final server = _expense(id: 'srv', amountCents: 5000, updatedAt: t0);
      final local = _expense(
        id: 'loc',
        amountCents: 5001,
        updatedAt: t0.add(const Duration(seconds: 1)),
      );
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isTrue);
    });

    test('local with null timestamp is never a near-duplicate', () {
      final server = _expense(id: 'srv', updatedAt: t0);
      final local = _expense(id: 'loc', updatedAt: null);
      final result =
          service.resolveExpenses(localRows: [local], serverRows: [server]);
      expect(result.containsKey('loc'), isTrue);
      expect(result.containsKey('srv'), isTrue);
    });
  });

  group('resolveGroups — list merge', () {
    test('merges server-only, local-only, and conflicting groups', () {
      final serverOnly = _group(id: 'srv', updatedAt: t0);
      final localOnly = _group(id: 'loc', updatedAt: t0);
      final conflictLocal = _group(id: 'both', updatedAt: tLater);
      final conflictServer = _group(id: 'both', updatedAt: t0);

      final result = service.resolveGroups(
        localRows: [localOnly, conflictLocal],
        serverRows: [serverOnly, conflictServer],
      );

      expect(result.keys.toSet(), {'srv', 'loc', 'both'});
      expect(result['srv'], same(serverOnly));
      expect(result['loc'], same(localOnly));
      expect(result['both'], same(conflictLocal)); // local newer wins
    });
  });
}
