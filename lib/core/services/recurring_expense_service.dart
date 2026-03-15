import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/expenses/repositories/expense_repository.dart';
import '../database/database_helper.dart';

/// Checks daily whether recurring expenses are due and auto-creates them.
/// Call [checkAndCreateDue] on app start (e.g. from HomeScreen.initState or
/// SyncService.init).
class RecurringExpenseService {
  RecurringExpenseService._();
  static final instance = RecurringExpenseService._();

  final _uuid = const Uuid();

  /// Returns the next due date for a given interval, based on [from].
  DateTime _nextDue(String interval, DateTime from) {
    switch (interval) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
      default:
        // Same day next month, clamped to last day of month.
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final nextYear = from.month == 12 ? from.year + 1 : from.year;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        return DateTime(nextYear, nextMonth, from.day.clamp(1, lastDay));
    }
  }

  /// Fetches all recurring expenses whose [nextDueDate] is today or in the
  /// past, creates a copy, and advances [nextDueDate] on the template.
  Future<void> checkAndCreateDue() async {
    debugPrint('[RecurringExpenseService] Running check...');
    try {
      final db = await DatabaseHelper().database;
      final now = DateTime.now();
      final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();

      // Find recurring templates that are due
      final maps = await db.query(
        'expenses',
        where: 'is_recurring = 1 AND next_due_date IS NOT NULL AND next_due_date <= ?',
        whereArgs: [todayStr],
      );

      debugPrint('[RecurringExpenseService] ${maps.length} due recurring expense(s)');

      for (final map in maps) {
        final template = Expense.fromMap(map);
        if (template.recurrenceInterval == null) continue;

        // Load splits and payers for the template
        final splits = await db.query(
          'expense_splits',
          where: 'expense_id = ?',
          whereArgs: [template.id],
        );
        final payers = await db.query(
          'expense_payers',
          where: 'expense_id = ?',
          whereArgs: [template.id],
        );

        // Create new expense for today
        final newId = _uuid.v4();
        final newExpense = Expense(
          id: newId,
          description: template.description,
          amountCents: template.amountCents,
          paidById: template.paidById,
          groupId: template.groupId,
          createdAt: now,
          expenseDate: now,
          category: template.category,
          splitType: template.splitType,
          currency: template.currency,
          syncStatus: 'pending',
          isRecurring: false, // copies are not templates
          recurringParentId: template.id,
        );

        final newSplits = splits.map((s) {
          final splitMap = Map<String, dynamic>.from(s);
          splitMap['id'] = _uuid.v4();
          splitMap['expense_id'] = newId;
          return ExpenseSplit.fromMap(splitMap);
        }).toList();

        final newPayers = payers.map((p) {
          final payerMap = Map<String, dynamic>.from(p);
          payerMap['id'] = _uuid.v4();
          payerMap['expense_id'] = newId;
          return ExpensePayer.fromMap(payerMap);
        }).toList();

        // Insert new expense
        final repo = ExpenseRepository();
        await repo.insertExpense(newExpense, newSplits, payers: newPayers);

        // Advance nextDueDate on template
        final nextDue = _nextDue(template.recurrenceInterval!, template.nextDueDate!);
        await db.update(
          'expenses',
          {'next_due_date': nextDue.toIso8601String()},
          where: 'id = ?',
          whereArgs: [template.id],
        );

        debugPrint('[RecurringExpenseService] Created recurring copy $newId for template ${template.id}, next due: $nextDue');
      }
    } catch (e, stack) {
      debugPrint('[RecurringExpenseService] ERROR: $e\n$stack');
    }
  }
}
