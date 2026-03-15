import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/groups/models/group.dart';
import '../../features/members/models/member.dart';

/// Exports group expenses as a UTF-8 BOM CSV for Excel compatibility.
///
/// Multi-currency: each currency gets its own Amount column.
/// Format: Date, Description, Category, Paid By, Currency, Amount, Split Type
class CsvExportService {
  CsvExportService._();
  static const CsvExportService instance = CsvExportService._();

  /// Generates CSV content and saves to a temp file. Returns the file path.
  Future<String> exportGroup({
    required Group group,
    required List<Expense> expenses,
    required List<Member> members,
  }) async {
    final memberMap = {for (final m in members) m.id: m.name};
    final dateFormatter = DateFormat('yyyy-MM-dd');

    // Collect all currencies used
    final currencies = expenses.map((e) => e.currency).toSet().toList()..sort();

    // Build header row
    final headers = [
      'Date',
      'Description',
      'Category',
      'Paid By',
      ...currencies.map((c) => 'Amount ($c)'),
      'Split Type',
    ];

    final rows = <List<String>>[headers];

    for (final expense in expenses
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate))) {
      final row = <String>[
        dateFormatter.format(expense.expenseDate),
        _escapeCsv(expense.description),
        expense.category,
        _escapeCsv(memberMap[expense.paidById] ?? expense.paidById),
        // Amount columns — fill the matching currency column, empty for others
        ...currencies.map((c) {
          if (c == expense.currency) {
            return _formatAmount(expense.amountCents);
          }
          return '';
        }),
        expense.splitType,
      ];
      rows.add(row);
    }

    // Build CSV string with UTF-8 BOM (for Excel)
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // BOM
    for (final row in rows) {
      buffer.writeln(row.join(','));
    }

    final csvContent = buffer.toString();
    final filename = '${_sanitizeFilename(group.name)}_expenses_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(utf8.encode(csvContent));

    debugPrint('[CsvExport] Exported ${expenses.length} expenses to ${file.path}');
    return file.path;
  }

  // MARK: - Helpers

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatAmount(int amountCents) {
    // e.g. 1234 → "12.34"
    return (amountCents / 100).toStringAsFixed(2);
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }
}
