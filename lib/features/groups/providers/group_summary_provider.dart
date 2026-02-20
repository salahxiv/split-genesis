import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';

class MemberSummary {
  final String memberId;
  final String name;
  final double totalPaid;
  final double totalOwed;

  MemberSummary({
    required this.memberId,
    required this.name,
    required this.totalPaid,
    required this.totalOwed,
  });
}

class GroupSummary {
  final int memberCount;
  final double totalExpenses;
  final int expenseCount;
  final double averageExpense;
  final List<MemberSummary> memberSummaries;

  GroupSummary({
    required this.memberCount,
    required this.totalExpenses,
    required this.expenseCount,
    required this.averageExpense,
    required this.memberSummaries,
  });

  MemberSummary? get topPayer {
    if (memberSummaries.isEmpty) return null;
    return memberSummaries.reduce(
        (a, b) => a.totalPaid >= b.totalPaid ? a : b);
  }
}

final groupSummaryProvider =
    FutureProvider.family<GroupSummary, String>((ref, groupId) async {
  final sw = Stopwatch()..start();
  final db = await DatabaseHelper().database;

  final memberResult = await db.rawQuery(
    'SELECT COUNT(*) as count FROM members WHERE group_id = ?',
    [groupId],
  );
  final memberCount = memberResult.first['count'] as int;

  final expenseResult = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as cnt FROM expenses WHERE group_id = ?',
    [groupId],
  );
  final totalExpenses = (expenseResult.first['total'] as num).toDouble();
  final expenseCount = expenseResult.first['cnt'] as int;
  final averageExpense = expenseCount > 0 ? totalExpenses / expenseCount : 0.0;

  // Per-member paid amounts (from expense_payers)
  final paidResult = await db.rawQuery('''
    SELECT m.id, m.name, COALESCE(SUM(ep.amount), 0) as total_paid
    FROM members m
    LEFT JOIN expense_payers ep ON ep.member_id = m.id
      AND ep.expense_id IN (SELECT id FROM expenses WHERE group_id = ?)
    WHERE m.group_id = ?
    GROUP BY m.id, m.name
  ''', [groupId, groupId]);

  // Per-member owed amounts (from expense_splits)
  final owedResult = await db.rawQuery('''
    SELECT m.id, COALESCE(SUM(es.amount), 0) as total_owed
    FROM members m
    LEFT JOIN expense_splits es ON es.member_id = m.id
      AND es.expense_id IN (SELECT id FROM expenses WHERE group_id = ?)
    WHERE m.group_id = ?
    GROUP BY m.id
  ''', [groupId, groupId]);

  final owedMap = <String, double>{};
  for (final row in owedResult) {
    owedMap[row['id'] as String] = (row['total_owed'] as num).toDouble();
  }

  final memberSummaries = paidResult.map((row) {
    final id = row['id'] as String;
    return MemberSummary(
      memberId: id,
      name: row['name'] as String,
      totalPaid: (row['total_paid'] as num).toDouble(),
      totalOwed: owedMap[id] ?? 0,
    );
  }).toList();

  debugPrint('[PERF] groupSummaryProvider($groupId): ${sw.elapsedMilliseconds}ms');
  return GroupSummary(
    memberCount: memberCount,
    totalExpenses: totalExpenses,
    expenseCount: expenseCount,
    averageExpense: averageExpense,
    memberSummaries: memberSummaries,
  );
});
