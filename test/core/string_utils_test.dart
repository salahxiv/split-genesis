import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/utils/string_utils.dart';

/// [getInitial] is the crash-safe avatar helper — the whole point is that it
/// never throws on empty / whitespace input, so those edges are the core cases.
void main() {
  group('getInitial', () {
    test('erster Buchstabe in Großschreibung', () {
      expect(getInitial('alice'), 'A');
    });

    test('führender Whitespace wird getrimmt', () {
      expect(getInitial('  bob'), 'B');
    });

    test('leerer String → "?" (crash-safe)', () {
      expect(getInitial(''), '?');
    });

    test('reiner Whitespace → "?" (crash-safe)', () {
      expect(getInitial('   '), '?');
    });

    test('mehrere Wörter → Initiale des ersten', () {
      expect(getInitial('John Doe'), 'J');
    });

    test('Umlaut/Akzent wird korrekt großgeschrieben', () {
      expect(getInitial('émile'), 'É');
    });

    test('bereits großgeschrieben bleibt unverändert', () {
      expect(getInitial('Zoe'), 'Z');
    });

    test('Zahl als erstes Zeichen bleibt Zahl', () {
      expect(getInitial('123'), '1');
    });
  });
}
