import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

final expensePayersByGroupProvider =
    FutureProvider.family<List<ExpensePayer>, String>((ref, groupId) async {
  return ref.read(expenseRepositoryProvider).getPayersByGroup(groupId);
});

final expensesProvider =
    AsyncNotifierProvider.family<ExpensesNotifier, List<Expense>, String>(
        ExpensesNotifier.new);

class ExpensesNotifier extends FamilyAsyncNotifier<List<Expense>, String> {
  @override
  Future<List<Expense>> build(String arg) async {
    final sw = Stopwatch()..start();
    final result = await ref.read(expenseRepositoryProvider).getExpensesByGroup(arg);
    debugPrint('[PERF] expensesProvider($arg).build(): ${sw.elapsedMilliseconds}ms (${result.length} expenses)');
    return result;
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required List<String> paidByIds,
    required List<String> splitAmongIds,
    String category = 'general',
    String splitType = 'equal',
    String currency = 'USD',
    DateTime? expenseDate,
    Map<String, double>? customSplits,
  }) async {
    if (splitAmongIds.isEmpty) {
      throw ArgumentError('At least one member must be selected for split');
    }
    if (paidByIds.isEmpty) {
      throw ArgumentError('At least one payer must be selected');
    }

    final expenseId = const Uuid().v4();
    // Convert to cents once; all arithmetic in int from here on.
    final totalCents = (amount * 100).round();
    final perPayerCents = totalCents ~/ paidByIds.length;
    final now = DateTime.now();

    final expense = Expense(
      id: expenseId,
      description: description,
      amountCents: totalCents,
      paidById: paidByIds.first,
      groupId: arg,
      createdAt: now,
      expenseDate: expenseDate ?? now,
      category: category,
      splitType: splitType,
      currency: currency,
    );

    final splits = splitAmongIds.map((memberId) {
      final int splitCents = customSplits != null && customSplits[memberId] != null
          ? (customSplits[memberId]! * 100).round()
          : totalCents ~/ splitAmongIds.length;
      return ExpenseSplit(
        id: const Uuid().v4(),
        expenseId: expenseId,
        memberId: memberId,
        amountCents: splitCents,
      );
    }).toList();

    final payers = paidByIds.map((memberId) {
      return ExpensePayer(
        id: const Uuid().v4(),
        expenseId: expenseId,
        memberId: memberId,
        amountCents: perPayerCents,
      );
    }).toList();

    await ref.read(expenseRepositoryProvider).insertExpense(expense, splits, payers: payers);
    ref.invalidateSelf();
    ref.invalidate(expensePayersByGroupProvider(arg));
  }

  Future<void> updateExpense({
    required String expenseId,
    required String description,
    required double amount,
    required List<String> paidByIds,
    required List<String> splitAmongIds,
    String category = 'general',
    String splitType = 'equal',
    String currency = 'USD',
    DateTime? expenseDate,
    DateTime? originalCreatedAt,
    Map<String, double>? customSplits,
  }) async {
    if (splitAmongIds.isEmpty) {
      throw ArgumentError('At least one member must be selected for split');
    }
    if (paidByIds.isEmpty) {
      throw ArgumentError('At least one payer must be selected');
    }

    // Convert to cents once; all arithmetic in int from here on.
    final totalCents = (amount * 100).round();
    final perPayerCents = totalCents ~/ paidByIds.length;

    final now = DateTime.now();
    // Preserve the original createdAt — do NOT use DateTime.now() which would
    // change sort order and break audit trail. BUG-03 fix.
    final createdAt = originalCreatedAt ?? now;
    final expense = Expense(
      id: expenseId,
      description: description,
      amountCents: totalCents,
      paidById: paidByIds.first,
      groupId: arg,
      createdAt: createdAt,
      expenseDate: expenseDate ?? createdAt,
      category: category,
      splitType: splitType,
      currency: currency,
      updatedAt: now,
    );

    final splits = splitAmongIds.map((memberId) {
      final int splitCents = customSplits != null && customSplits[memberId] != null
          ? (customSplits[memberId]! * 100).round()
          : totalCents ~/ splitAmongIds.length;
      return ExpenseSplit(
        id: const Uuid().v4(),
        expenseId: expenseId,
        memberId: memberId,
        amountCents: splitCents,
      );
    }).toList();

    final payers = paidByIds.map((memberId) {
      return ExpensePayer(
        id: const Uuid().v4(),
        expenseId: expenseId,
        memberId: memberId,
        amountCents: perPayerCents,
      );
    }).toList();

    await ref.read(expenseRepositoryProvider).updateExpense(expense, splits, payers: payers);
    ref.invalidateSelf();
    ref.invalidate(expensePayersByGroupProvider(arg));
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    ref.invalidateSelf();
    ref.invalidate(expensePayersByGroupProvider(arg));
  }
}
