import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/utils/currency_utils.dart';

void main() {
  group('formatCurrency', () {
    test('USD formats with dollar sign and 2 decimals', () {
      expect(formatCurrency(50.0, 'USD'), '\$50.00');
    });

    test('EUR formats with euro sign', () {
      expect(formatCurrency(50.0, 'EUR'), '\u20AC50.00');
    });

    test('GBP formats with pound sign', () {
      expect(formatCurrency(50.0, 'GBP'), '\u00A350.00');
    });

    test('JPY rounds to integer (no decimals)', () {
      expect(formatCurrency(1234.56, 'JPY'), '\u00A51235');
    });

    test('JPY rounds half-up', () {
      expect(formatCurrency(99.5, 'JPY'), '\u00A5100');
    });

    test('CAD formats correctly', () {
      expect(formatCurrency(25.50, 'CAD'), 'CA\$25.50');
    });

    test('AUD formats correctly', () {
      expect(formatCurrency(10.0, 'AUD'), 'A\$10.00');
    });

    test('CHF formats correctly', () {
      expect(formatCurrency(100.0, 'CHF'), 'CHF100.00');
    });

    test('CNY formats with yuan sign', () {
      expect(formatCurrency(88.0, 'CNY'), '\u00A588.00');
    });

    test('INR formats with rupee sign', () {
      expect(formatCurrency(500.0, 'INR'), '\u20B9500.00');
    });

    test('MXN formats correctly', () {
      expect(formatCurrency(200.0, 'MXN'), 'MX\$200.00');
    });

    test('unknown currency code uses code as symbol', () {
      expect(formatCurrency(10.0, 'XYZ'), 'XYZ10.00');
    });

    test('zero amount', () {
      expect(formatCurrency(0.0, 'USD'), '\$0.00');
    });

    test('negative amount', () {
      expect(formatCurrency(-50.0, 'USD'), '\$-50.00');
    });

    test('very large amount', () {
      expect(formatCurrency(1000000.0, 'USD'), '\$1000000.00');
    });

    test('very small amount', () {
      expect(formatCurrency(0.01, 'USD'), '\$0.01');
    });

    test('default currency is USD', () {
      expect(formatCurrency(42.0), '\$42.00');
    });
  });

  group('getCurrencySymbol', () {
    test('returns symbol for known currency', () {
      expect(getCurrencySymbol('USD'), '\$');
      expect(getCurrencySymbol('EUR'), '\u20AC');
      expect(getCurrencySymbol('GBP'), '\u00A3');
    });

    test('returns code for unknown currency', () {
      expect(getCurrencySymbol('BTC'), 'BTC');
      expect(getCurrencySymbol('UNKNOWN'), 'UNKNOWN');
    });
  });
}
