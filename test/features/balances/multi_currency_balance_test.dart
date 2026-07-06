import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/features/balances/models/balance.dart';
import 'package:split_genesis/features/members/models/member.dart';

/// Pins the boundary behaviour of [MultiCurrencyBalance]'s pure getters —
/// the sign split (owed vs owing) and the ±1-cent settled tolerance are the
/// kind of off-by-one edges that silently regress without a test.
void main() {
  Member member() =>
      Member(id: 'm1', name: 'Alice', groupId: 'g1');

  MultiCurrencyBalance balance(Map<String, int> cents) =>
      MultiCurrencyBalance(member: member(), currencyBalances: cents);

  group('MultiCurrencyBalance.owedCurrencies (member owes → negative cents)', () {
    test('nur negative Beträge werden zurückgegeben', () {
      final b = balance({'EUR': -1250, 'USD': 800, 'GBP': 0});
      expect(b.owedCurrencies, {'EUR': -1250});
    });

    test('Betrag 0 zählt NICHT als geschuldet', () {
      expect(balance({'EUR': 0}).owedCurrencies, isEmpty);
    });

    test('-1 Cent zählt als geschuldet (strikt < 0)', () {
      expect(balance({'EUR': -1}).owedCurrencies, {'EUR': -1});
    });

    test('leere Balance → keine geschuldeten Währungen', () {
      expect(balance({}).owedCurrencies, isEmpty);
    });
  });

  group('MultiCurrencyBalance.owingCurrencies (member bekommt → positive cents)', () {
    test('nur positive Beträge werden zurückgegeben', () {
      final b = balance({'EUR': -1250, 'USD': 800, 'GBP': 0});
      expect(b.owingCurrencies, {'USD': 800});
    });

    test('Betrag 0 zählt NICHT als Guthaben', () {
      expect(balance({'USD': 0}).owingCurrencies, isEmpty);
    });

    test('+1 Cent zählt als Guthaben (strikt > 0)', () {
      expect(balance({'USD': 1}).owingCurrencies, {'USD': 1});
    });
  });

  group('MultiCurrencyBalance.isSettledUp (±1-Cent-Toleranz)', () {
    test('alle Beträge innerhalb ±1 Cent → settled', () {
      expect(balance({'EUR': 1, 'USD': -1, 'GBP': 0}).isSettledUp, isTrue);
    });

    test('ein Betrag mit |v| = 2 → nicht settled', () {
      expect(balance({'EUR': 2}).isSettledUp, isFalse);
    });

    test('leere Balance gilt als settled', () {
      expect(balance({}).isSettledUp, isTrue);
    });

    test('gemischt: eine Währung über Toleranz kippt das Gesamtergebnis', () {
      expect(balance({'EUR': 1, 'USD': -50}).isSettledUp, isFalse);
    });
  });

  group('MultiCurrencyBalance.centsFor / amountFor', () {
    test('vorhandene Währung → gespeicherte Cents', () {
      expect(balance({'EUR': -1250}).centsFor('EUR'), -1250);
    });

    test('fehlende Währung → 0', () {
      expect(balance({'EUR': -1250}).centsFor('USD'), 0);
    });

    test('amountFor teilt Cents durch 100', () {
      expect(balance({'EUR': -1250}).amountFor('EUR'), -12.5);
    });

    test('amountFor fehlender Währung → 0.0', () {
      expect(balance({'EUR': -1250}).amountFor('JPY'), 0.0);
    });
  });
}
