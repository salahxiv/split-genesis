import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/services/recurring_expense_service.dart';

void main() {
  final service = RecurringExpenseService.instance;

  group('nextDue — weekly / biweekly', () {
    test('weekly adds 7 days', () {
      expect(
        service.nextDue('weekly', DateTime(2024, 6, 1)),
        DateTime(2024, 6, 8),
      );
    });

    test('biweekly adds 14 days', () {
      expect(
        service.nextDue('biweekly', DateTime(2024, 6, 1)),
        DateTime(2024, 6, 15),
      );
    });

    test('weekly rolls across a month boundary', () {
      expect(
        service.nextDue('weekly', DateTime(2024, 1, 28)),
        DateTime(2024, 2, 4),
      );
    });
  });

  group('nextDue — monthly', () {
    test('same day next month for a normal date', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 6, 15)),
        DateTime(2024, 7, 15),
      );
    });

    test('Jan 31 → Feb clamps to last day (leap year = Feb 29)', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 1, 31)),
        DateTime(2024, 2, 29),
      );
    });

    test('Jan 31 → Feb clamps to Feb 28 in a non-leap year', () {
      expect(
        service.nextDue('monthly', DateTime(2023, 1, 31)),
        DateTime(2023, 2, 28),
      );
    });

    test('Mar 31 → Apr clamps to Apr 30', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 3, 31)),
        DateTime(2024, 4, 30),
      );
    });

    test('Dec → Jan rolls the year over', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 12, 15)),
        DateTime(2025, 1, 15),
      );
    });

    test('Dec 31 → Jan 31 (no clamp, both months have 31 days)', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 12, 31)),
        DateTime(2025, 1, 31),
      );
    });

    test('Nov 30 → Dec 30 (month==11 branch, Dec has 31 days)', () {
      expect(
        service.nextDue('monthly', DateTime(2024, 11, 30)),
        DateTime(2024, 12, 30),
      );
    });
  });

  group('nextDue — unknown interval falls through to monthly', () {
    test('unrecognised interval behaves like monthly', () {
      expect(
        service.nextDue('quarterly', DateTime(2024, 6, 15)),
        DateTime(2024, 7, 15),
      );
    });
  });
}
