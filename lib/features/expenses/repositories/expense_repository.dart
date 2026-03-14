import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/api_first_repository.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/supabase_data_source.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/expense.dart';
import '../models/expense_comment.dart';

class ExpenseRepository with ApiFirstRepository {
  ExpenseRepository({DatabaseHelper? db, SupabaseDataSource? api, ConnectivityService? connectivity}) {
    initDeps(db: db, api: api, connectivity: connectivity);
  }
  Future<List<Expense>> getExpensesByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select(
        'expenses',
        filters: {'group_id': groupId},
        orderBy: 'created_at',
      ),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          final double rawAmount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          final int cents = (rawAmount * 100).round();
          batch.insert(
            'expenses',
            {
              'id': row['id'],
              'description': row['description'],
              'amount': rawAmount,
              'amount_cents': cents,
              'paid_by_id': row['paid_by_id'],
              'group_id': row['group_id'],
              'created_at': row['created_at'],
              'expense_date': row['expense_date'],
              'category': row['category'] ?? 'general',
              'split_type': row['split_type'] ?? 'equal',
              'currency': row['currency'] ?? 'USD',
              'updated_at': row['updated_at'],
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query(
          'expenses',
          where: 'group_id = ?',
          whereArgs: [groupId],
          orderBy: 'created_at DESC',
        );
        return maps.map((map) => Expense.fromMap(map)).toList();
      },
    );
  }

  Future<void> insertExpense(
    Expense expense,
    List<ExpenseSplit> splits, {
    List<ExpensePayer> payers = const [],
  }) async {
    await writeThrough(
      apiCall: () => api.rpc('upsert_expense', params: {
        'p_expense': jsonDecode(jsonEncode(expense.toApiMap())),
        'p_splits': splits.map((s) => s.toMap()).toList(),
        'p_payers': payers.map((p) => p.toMap()).toList(),
      }),
      sqliteCall: (database) async {
        await database.transaction((txn) async {
          await txn.insert('expenses', expense.toMap());
          for (final split in splits) {
            await txn.insert('expense_splits', split.toMap());
          }
          for (final payer in payers) {
            await txn.insert('expense_payers', payer.toMap());
          }
        });
      },
      syncTable: 'expenses',
      syncId: expense.id,
    );
  }

  Future<void> updateExpense(
    Expense expense,
    List<ExpenseSplit> splits, {
    List<ExpensePayer> payers = const [],
  }) async {
    await writeThrough(
      apiCall: () => api.rpc('upsert_expense', params: {
        'p_expense': jsonDecode(jsonEncode(expense.toApiMap())),
        'p_splits': splits.map((s) => s.toMap()).toList(),
        'p_payers': payers.map((p) => p.toMap()).toList(),
      }),
      sqliteCall: (database) async {
        await database.transaction((txn) async {
          await txn.update('expenses', expense.toMap(),
              where: 'id = ?', whereArgs: [expense.id]);
          await txn.delete('expense_splits',
              where: 'expense_id = ?', whereArgs: [expense.id]);
          await txn.delete('expense_payers',
              where: 'expense_id = ?', whereArgs: [expense.id]);
          for (final split in splits) {
            await txn.insert('expense_splits', split.toMap());
          }
          for (final payer in payers) {
            await txn.insert('expense_payers', payer.toMap());
          }
        });
      },
      syncTable: 'expenses',
      syncId: expense.id,
    );
  }

  Future<List<ExpenseSplit>> getSplitsByExpense(String expenseId) async {
    return fetchAndCache(
      apiCall: () => api.select('expense_splits', filters: {'expense_id': expenseId}),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          final double rawAmount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          batch.insert(
            'expense_splits',
            {
              'id': row['id'],
              'expense_id': row['expense_id'],
              'member_id': row['member_id'],
              'amount': rawAmount,
              'amount_cents': (rawAmount * 100).round(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query('expense_splits',
            where: 'expense_id = ?', whereArgs: [expenseId]);
        return maps.map((map) => ExpenseSplit.fromMap(map)).toList();
      },
    );
  }

  Future<List<ExpensePayer>> getPayersByExpense(String expenseId) async {
    return fetchAndCache(
      apiCall: () => api.select('expense_payers', filters: {'expense_id': expenseId}),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          final double rawAmount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          batch.insert(
            'expense_payers',
            {
              'id': row['id'],
              'expense_id': row['expense_id'],
              'member_id': row['member_id'],
              'amount': rawAmount,
              'amount_cents': (rawAmount * 100).round(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query('expense_payers',
            where: 'expense_id = ?', whereArgs: [expenseId]);
        return maps.map((map) => ExpensePayer.fromMap(map)).toList();
      },
    );
  }

  Future<List<ExpensePayer>> getPayersByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select(
        'expense_payers_by_group',
        filters: {'group_id': groupId},
      ),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          final double rawAmount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          batch.insert(
            'expense_payers',
            {
              'id': row['id'],
              'expense_id': row['expense_id'],
              'member_id': row['member_id'],
              'amount': rawAmount,
              'amount_cents': (rawAmount * 100).round(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.rawQuery('''
          SELECT ep.* FROM expense_payers ep
          INNER JOIN expenses e ON ep.expense_id = e.id
          WHERE e.group_id = ?
        ''', [groupId]);
        return maps.map((map) => ExpensePayer.fromMap(map)).toList();
      },
    );
  }

  Future<List<ExpenseSplit>> getSplitsByGroup(String groupId) async {
    return fetchAndCache(
      apiCall: () => api.select(
        'expense_splits_by_group',
        filters: {'group_id': groupId},
      ),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          final double rawAmount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          batch.insert(
            'expense_splits',
            {
              'id': row['id'],
              'expense_id': row['expense_id'],
              'member_id': row['member_id'],
              'amount': rawAmount,
              'amount_cents': (rawAmount * 100).round(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.rawQuery('''
          SELECT es.* FROM expense_splits es
          INNER JOIN expenses e ON es.expense_id = e.id
          WHERE e.group_id = ?
        ''', [groupId]);
        return maps.map((map) => ExpenseSplit.fromMap(map)).toList();
      },
    );
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  /// Load comments for an expense: API-first, cache to SQLite, fallback offline.
  Future<List<ExpenseComment>> getCommentsByExpense(String expenseId) async {
    return fetchAndCache(
      apiCall: () => api.fetchComments(expenseId),
      cacheWriter: (database, rows) async {
        final batch = database.batch();
        for (final row in rows) {
          batch.insert(
            'expense_comments',
            {
              'id': row['id'],
              'expense_id': row['expense_id'],
              'member_name': row['member_name'],
              'content': row['content'],
              'created_at': row['created_at'],
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
      sqliteCall: () async {
        final database = await db.database;
        final maps = await database.query(
          'expense_comments',
          where: 'expense_id = ?',
          whereArgs: [expenseId],
          orderBy: 'created_at ASC',
        );
        return maps.map((m) => ExpenseComment.fromMap(m)).toList();
      },
    );
  }

  /// Add a comment with offline-first write-through.
  Future<void> addComment(ExpenseComment comment) async {
    await writeThrough(
      apiCall: () => api.syncComments([comment.toMap()]),
      sqliteCall: (database) async {
        await database.insert(
          'expense_comments',
          comment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      },
      syncTable: 'expense_comments',
      syncId: comment.id,
    );
  }

  Future<void> deleteExpense(String id) async {
    await deleteThrough(
      apiCall: () => api.delete('expenses', id),
      sqliteCall: (database) async {
        await database.delete('expenses', where: 'id = ?', whereArgs: [id]);
      },
    );
  }

  Future<bool> memberHasExpenses(String memberId) async {
    if (connectivity.isOnline) {
      try {
        final result = await api.rpc<bool>(
          'member_has_expenses',
          params: {'p_member_id': memberId},
        );
        return result;
      } catch (e) {
        debugPrint('[API-FIRST] memberHasExpenses RPC error, falling back to SQLite: $e');
      }
    }

    // SQLite fallback
    final database = await db.database;
    final paidResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE paid_by_id = ?',
      [memberId],
    );
    if ((paidResult.first['count'] as int) > 0) return true;

    final payerResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM expense_payers WHERE member_id = ?',
      [memberId],
    );
    if ((payerResult.first['count'] as int) > 0) return true;

    final splitResult = await database.rawQuery(
      'SELECT COUNT(*) as count FROM expense_splits WHERE member_id = ?',
      [memberId],
    );
    return (splitResult.first['count'] as int) > 0;
  }
}
