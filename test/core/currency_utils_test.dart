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

  // These run against the static EUR fallback table (USD 1.08, GBP 0.86,
  // JPY 161.5, CHF 0.97). init()/refresh() require the network, so in tests
  // _liveRates stays null and the math is deterministic. The guard documents
  // that precondition — if live rates ever load offline-free it will flag here.
  group('CurrencyConverter', () {
    test('runs against static fallback rates (no live rates in tests)', () {
      expect(CurrencyConverter.hasLiveRates, isFalse);
    });

    group('toEurCents', () {
      test('EUR is a passthrough', () {
        expect(CurrencyConverter.toEurCents(250, 'EUR'), 250);
      });

      test('USD divides by the EUR rate and rounds', () {
        expect(CurrencyConverter.toEurCents(108, 'USD'), 100);
        expect(CurrencyConverter.toEurCents(1000, 'USD'), 926); // 925.9 -> 926
      });

      test('JPY (large rate) divides correctly', () {
        expect(CurrencyConverter.toEurCents(1615, 'JPY'), 10);
      });

      test('unknown currency fails open (returns input unchanged)', () {
        expect(CurrencyConverter.toEurCents(999, 'XYZ'), 999);
      });

      test('handles zero and negative amounts', () {
        expect(CurrencyConverter.toEurCents(0, 'USD'), 0);
        expect(CurrencyConverter.toEurCents(-108, 'USD'), -100);
      });
    });

    group('fromEurCents', () {
      test('EUR is a passthrough', () {
        expect(CurrencyConverter.fromEurCents(250, 'EUR'), 250);
      });

      test('USD multiplies by the EUR rate and rounds', () {
        expect(CurrencyConverter.fromEurCents(100, 'USD'), 108);
      });

      test('GBP multiplies by the EUR rate and rounds', () {
        expect(CurrencyConverter.fromEurCents(100, 'GBP'), 86);
      });

      test('JPY (large rate) multiplies correctly', () {
        expect(CurrencyConverter.fromEurCents(10, 'JPY'), 1615);
      });

      test('unknown currency fails open (returns input unchanged)', () {
        expect(CurrencyConverter.fromEurCents(999, 'XYZ'), 999);
      });

      test('handles zero and negative amounts', () {
        expect(CurrencyConverter.fromEurCents(0, 'GBP'), 0);
        expect(CurrencyConverter.fromEurCents(-100, 'GBP'), -86);
      });
    });

    group('convert', () {
      test('same currency is an identity (no rate applied)', () {
        expect(CurrencyConverter.convert(500, 'USD', 'USD'), 500);
      });

      test('USD to GBP pivots through EUR', () {
        // 108 USD -> 100 EUR -> 86 GBP
        expect(CurrencyConverter.convert(108, 'USD', 'GBP'), 86);
      });

      test('EUR to USD applies the forward rate', () {
        expect(CurrencyConverter.convert(100, 'EUR', 'USD'), 108);
      });

      test('USD to EUR applies the inverse rate', () {
        expect(CurrencyConverter.convert(1080, 'USD', 'EUR'), 1000);
      });

      test('round-trips a clean value without drift', () {
        final gbp = CurrencyConverter.convert(1080, 'USD', 'GBP'); // 860
        expect(gbp, 860);
        expect(CurrencyConverter.convert(gbp, 'GBP', 'USD'), 1080);
      });

      test('unknown source currency is treated as EUR (fail-open)', () {
        // toEurCents fails open -> 500 EUR -> 540 USD
        expect(CurrencyConverter.convert(500, 'XYZ', 'USD'), 540);
      });

      test('handles negative amounts through the pivot', () {
        expect(CurrencyConverter.convert(-1080, 'USD', 'GBP'), -860);
      });
    });

    group('isSupported / supportedCurrencies', () {
      test('known codes are supported', () {
        expect(CurrencyConverter.isSupported('EUR'), isTrue);
        expect(CurrencyConverter.isSupported('USD'), isTrue);
        expect(CurrencyConverter.isSupported('JPY'), isTrue);
      });

      test('unknown and empty codes are not supported', () {
        expect(CurrencyConverter.isSupported('XYZ'), isFalse);
        expect(CurrencyConverter.isSupported(''), isFalse);
      });

      test('supported list is sorted and contains the majors', () {
        final codes = CurrencyConverter.supportedCurrencies;
        expect(codes, containsAll(<String>['EUR', 'USD', 'GBP', 'JPY']));
        final sorted = [...codes]..sort();
        expect(codes, sorted);
      });

      test('static fallback table exposes 25 currencies', () {
        expect(CurrencyConverter.supportedCurrencies.length, 25);
      });
    });
  });
}
