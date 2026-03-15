import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/balances/models/balance.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/groups/models/group.dart';
import '../../features/members/models/member.dart';

/// Exports group expenses and balances as a PDF.
///
/// Layout:
/// - Header: Group name + export date
/// - Section 1: Balances per member (multi-currency)
/// - Section 2: Expense list (date, description, paid by, amount, currency)
class PdfExportService {
  const PdfExportService._();
  static const PdfExportService instance = PdfExportService._();

  Future<String> exportGroup({
    required Group group,
    required List<Expense> expenses,
    required List<Member> members,
    required List<MultiCurrencyBalance> balances,
  }) async {
    final memberMap = {for (final m in members) m.id: m.name};
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(group, now),
            pw.SizedBox(height: 20),
            _buildBalancesSection(balances, memberMap),
            pw.SizedBox(height: 24),
            _buildExpensesSection(expenses, memberMap, dateFormatter),
          ];
        },
      ),
    );

    final filename = '${_sanitizeFilename(group.name)}_export_${DateFormat('yyyyMMdd').format(now)}.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    debugPrint('[PdfExport] Exported ${expenses.length} expenses to ${file.path}');
    return file.path;
  }

  // MARK: - PDF Sections

  pw.Widget _buildHeader(Group group, DateTime exportDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          group.name,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Exported: ${DateFormat('MMMM d, yyyy').format(exportDate)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
        pw.Divider(color: PdfColors.grey400, thickness: 1),
      ],
    );
  }

  pw.Widget _buildBalancesSection(
    List<MultiCurrencyBalance> balances,
    Map<String, String> memberMap,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Balances',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Member', isHeader: true),
                _tableCell('Balance', isHeader: true),
              ],
            ),
            // Data rows
            ...balances.map((mb) {
              final name = mb.member.name;
              final balanceText = mb.currencyBalances.entries.map((e) {
                final amount = e.value / 100;
                final sign = amount >= 0 ? '+' : '';
                return '$sign${amount.toStringAsFixed(2)} ${e.key}';
              }).join('  |  ');
              return pw.TableRow(
                children: [
                  _tableCell(name),
                  _tableCell(balanceText.isEmpty ? '0.00' : balanceText),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildExpensesSection(
    List<Expense> expenses,
    Map<String, String> memberMap,
    DateFormat dateFormatter,
  ) {
    final sortedExpenses = [...expenses]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expenses (${expenses.length})',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(72),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FixedColumnWidth(80),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Date', isHeader: true),
                _tableCell('Description', isHeader: true),
                _tableCell('Paid By', isHeader: true),
                _tableCell('Amount', isHeader: true),
              ],
            ),
            ...sortedExpenses.map((expense) {
              final paidBy = memberMap[expense.paidById] ?? expense.paidById;
              final amount = '${(expense.amountCents / 100).toStringAsFixed(2)} ${expense.currency}';
              return pw.TableRow(
                children: [
                  _tableCell(dateFormatter.format(expense.expenseDate)),
                  _tableCell(expense.description),
                  _tableCell(paidBy),
                  _tableCell(amount),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: isHeader
          ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)
          : const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }
}
