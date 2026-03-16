import 'dart:async';

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
    FutureProvider.autoDispose.family<GroupSummary, String>((ref, groupId) async {
  // Keep alive for 30s to survive navigation transitions
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 30), link.close);
  ref.onDispose(timer.cancel);

  final sw = Stopwatch()..start();
  final db = await DatabaseHelper().database;

  // Run all 4 queries in parallel
  final results = await Future.wait([
    db.rawQuery(
      'SELECT COUNT(*) as count FROM members WHERE group_id = ?',
      [groupId],
    ),
    db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as cnt FROM expenses WHERE group_id = ?',
      [groupId],
    ),
    db.rawQuery('''
      SELECT m.id, m.name, COALESCE(SUM(ep.amount), 0) as total_paid
      FROM members m
      LEFT JOIN expense_payers ep ON ep.member_id = m.id
        AND ep.expense_id IN (SELECT id FROM expenses WHERE group_id = ?)
      WHERE m.group_id = ?
      GROUP BY m.id, m.name
    ''', [groupId, groupId]),
    db.rawQuery('''
      SELECT m.id, COALESCE(SUM(es.amount), 0) as total_owed
      FROM members m
      LEFT JOIN expense_splits es ON es.member_id = m.id
        AND es.expense_id IN (SELECT id FROM expenses WHERE group_id = ?)
      WHERE m.group_id = ?
      GROUP BY m.id
    ''', [groupId, groupId]),
  ]);

  final memberCount = results[0].first['count'] as int;
  final totalExpenses = (results[1].first['total'] as num).toDouble();
  final expenseCount = results[1].first['cnt'] as int;
  final averageExpense = expenseCount > 0 ? totalExpenses / expenseCount : 0.0;
  final paidResult = results[2];
  final owedResult = results[3];

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
