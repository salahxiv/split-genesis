import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/services/csv_export_service.dart';
import 'package:split_genesis/features/expenses/models/expense.dart';
import 'package:split_genesis/features/members/models/member.dart';

/// Covers the pure CSV builder extracted from [CsvExportService.exportGroup]:
/// the multi-currency column layout, RFC-4180 escaping, newest-first ordering
/// and — critically — that it does NOT reorder the caller's list.
void main() {
  const csv = CsvExportService.instance;

  Member member(String id, String name) =>
      Member(id: id, name: name, groupId: 'g1');

  Expense expense({
    required String id,
    String description = 'Lunch',
    int amountCents = 1234,
    String paidById = 'm1',
    String category = 'food',
    String splitType = 'equal',
    String currency = 'EUR',
    required DateTime date,
  }) =>
      Expense(
        id: id,
        description: description,
        amountCents: amountCents,
        paidById: paidById,
        groupId: 'g1',
        createdAt: date,
        expenseDate: date,
        category: category,
        splitType: splitType,
        currency: currency,
      );

  // CSV output = BOM + '\n'-terminated rows. Strip BOM, drop trailing empty.
  List<String> lines(String out) {
    expect(out.codeUnitAt(0), 0xFEFF, reason: 'muss mit UTF-8 BOM starten');
    return out
        .substring(1)
        .split('\n')
        .where((l) => l.isNotEmpty)
        .toList();
  }

  group('buildCsv — Header', () {
    test('eine Währung → eine Amount-Spalte', () {
      final out = csv.buildCsv(
        expenses: [expense(id: 'e1', date: DateTime(2024, 3, 15))],
        members: [member('m1', 'Alice')],
      );
      expect(lines(out).first,
          'Date,Description,Category,Paid By,Amount (EUR),Split Type');
    });

    test('keine Expenses → nur Header ohne Amount-Spalte', () {
      final out = csv.buildCsv(expenses: [], members: []);
      final l = lines(out);
      expect(l, hasLength(1));
      expect(l.first, 'Date,Description,Category,Paid By,Split Type');
    });

    test('mehrere Währungen → Amount-Spalten alphabetisch sortiert', () {
      final out = csv.buildCsv(
        expenses: [
          expense(id: 'e1', currency: 'USD', date: DateTime(2024, 1, 1)),
          expense(id: 'e2', currency: 'EUR', date: DateTime(2024, 1, 2)),
        ],
        members: [member('m1', 'Alice')],
      );
      expect(lines(out).first,
          'Date,Description,Category,Paid By,Amount (EUR),Amount (USD),Split Type');
    });
  });

  group('buildCsv — Zeileninhalt', () {
    test('Felder inkl. aufgelöstem Zahler-Namen', () {
      final out = csv.buildCsv(
        expenses: [
          expense(
            id: 'e1',
            description: 'Lunch',
            category: 'food',
            splitType: 'equal',
            amountCents: 1234,
            date: DateTime(2024, 3, 15),
          )
        ],
        members: [member('m1', 'Alice')],
      );
      expect(lines(out)[1], '2024-03-15,Lunch,food,Alice,12.34,equal');
    });

    test('unbekannter Zahler → rohe paidById als Fallback', () {
      final out = csv.buildCsv(
        expenses: [expense(id: 'e1', paidById: 'ghost', date: DateTime(2024, 3, 15))],
        members: [member('m1', 'Alice')],
      );
      expect(lines(out)[1].split(',')[3], 'ghost');
    });

    test('Multi-Currency: jede Expense füllt nur ihre Spalte', () {
      final out = csv.buildCsv(
        expenses: [
          expense(id: 'e1', currency: 'EUR', amountCents: 500, date: DateTime(2024, 1, 2)),
          expense(id: 'e2', currency: 'USD', amountCents: 800, date: DateTime(2024, 1, 1)),
        ],
        members: [member('m1', 'Alice')],
      );
      final l = lines(out);
      // Spalten: Date,Desc,Cat,PaidBy,Amount(EUR),Amount(USD),Split
      expect(l[1].split(',').sublist(4, 6), ['5.00', '']); // EUR-Zeile (neuer)
      expect(l[2].split(',').sublist(4, 6), ['', '8.00']); // USD-Zeile
    });
  });

  group('buildCsv — Amount-Formatierung', () {
    test('Cents → zwei Nachkommastellen', () {
      String amountCell(int cents) {
        final out = csv.buildCsv(
          expenses: [expense(id: 'e1', amountCents: cents, date: DateTime(2024, 1, 1))],
          members: [member('m1', 'Alice')],
        );
        return lines(out)[1].split(',')[4];
      }

      expect(amountCell(1234), '12.34');
      expect(amountCell(100), '1.00');
      expect(amountCell(5), '0.05');
      expect(amountCell(0), '0.00');
    });
  });

  group('buildCsv — RFC-4180 Escaping', () {
    String descCell(String description) {
      final out = csv.buildCsv(
        expenses: [expense(id: 'e1', description: description, date: DateTime(2024, 1, 1))],
        members: [member('m1', 'Alice')],
      );
      // Description ist die zweite Spalte; bei Quoting kann sie Kommas
      // enthalten, daher gezielt zwischen erstem und (ggf.) Amount lesen.
      return lines(out)[1];
    }

    test('Komma → in Anführungszeichen', () {
      expect(descCell('Lunch, drinks'), contains('"Lunch, drinks"'));
    });

    test('Anführungszeichen → verdoppelt und umschlossen', () {
      expect(descCell('The "Best" Cafe'), contains('"The ""Best"" Cafe"'));
    });

    test('Zeilenumbruch → in Anführungszeichen', () {
      // Roh-Output prüfen: der Helper würde die Zeile am escapten \n zerteilen.
      final out = csv.buildCsv(
        expenses: [expense(id: 'e1', description: 'Line1\nLine2', date: DateTime(2024, 1, 1))],
        members: [member('m1', 'Alice')],
      );
      expect(out, contains('"Line1\nLine2"'));
    });

    test('harmloser Text → nicht gequotet', () {
      final cell = descCell('Groceries').split(',')[1];
      expect(cell, 'Groceries');
    });
  });

  group('buildCsv — Reihenfolge & Reinheit', () {
    test('Zeilen sind newest-first sortiert', () {
      final out = csv.buildCsv(
        expenses: [
          expense(id: 'old', description: 'Old', date: DateTime(2024, 1, 1)),
          expense(id: 'new', description: 'New', date: DateTime(2024, 6, 1)),
        ],
        members: [member('m1', 'Alice')],
      );
      final l = lines(out);
      expect(l[1], startsWith('2024-06-01,New'));
      expect(l[2], startsWith('2024-01-01,Old'));
    });

    test('mutiert die übergebene Expense-Liste NICHT', () {
      final input = [
        expense(id: 'old', date: DateTime(2024, 1, 1)),
        expense(id: 'new', date: DateTime(2024, 6, 1)),
      ];
      csv.buildCsv(expenses: input, members: [member('m1', 'Alice')]);
      expect(input.map((e) => e.id).toList(), ['old', 'new']);
    });
  });
}
