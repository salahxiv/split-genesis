import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/services/deep_link_service.dart';

/// [DeepLinkService.parseJoinCode] is the invite-link parser. A bug here means
/// broken group invites, so the edge cases — trailing slashes, query strings,
/// wrong scheme/host, empty codes — are the point.
void main() {
  String? parse(String uri) => DeepLinkService.parseJoinCode(Uri.parse(uri));

  group('parseJoinCode — Custom-Scheme (splitgenesis://join/CODE)', () {
    test('gültiger Code', () {
      expect(parse('splitgenesis://join/ABC123'), 'ABC123');
    });

    test('Query-String wird ignoriert', () {
      expect(parse('splitgenesis://join/ABC123?ref=xyz'), 'ABC123');
    });

    test('Code behält Groß-/Kleinschreibung (nur Scheme/Host normalisiert)', () {
      expect(parse('splitgenesis://join/AbC123'), 'AbC123');
    });

    test('fehlender Code → null', () {
      expect(parse('splitgenesis://join'), isNull);
    });

    test('falscher Host → null', () {
      expect(parse('splitgenesis://invite/ABC123'), isNull);
    });
  });

  group('parseJoinCode — HTTPS (https://host/join/CODE)', () {
    test('gültiger Code', () {
      expect(parse('https://splitgenesis.app/join/ABC123'), 'ABC123');
    });

    test('Query-String wird ignoriert', () {
      expect(parse('https://splitgenesis.app/join/ABC123?utm=share'), 'ABC123');
    });

    test('zusätzliche Pfadsegmente → nimmt das zweite (den Code)', () {
      expect(parse('https://splitgenesis.app/join/ABC123/extra'), 'ABC123');
    });

    test('Trailing-Slash ohne Code → null', () {
      expect(parse('https://splitgenesis.app/join/'), isNull);
    });

    test('erstes Segment ist nicht "join" → null', () {
      expect(parse('https://splitgenesis.app/invite/ABC123'), isNull);
    });

    test('nur /join ohne Code → null', () {
      expect(parse('https://splitgenesis.app/join'), isNull);
    });
  });

  group('parseJoinCode — Nicht-Join-Links', () {
    test('fremdes Custom-Scheme → null', () {
      expect(parse('otherapp://join/ABC123'), isNull);
    });

    test('nackte Domain ohne Pfad → null', () {
      expect(parse('https://splitgenesis.app/'), isNull);
    });

    test('relativer /join/CODE-Pfad parst ebenfalls (Scheme-agnostisch)', () {
      // Dokumentiert bewusst das Ist-Verhalten: der HTTPS-Zweig prüft nur die
      // Pfadsegmente, nicht das Scheme. Real kommen Deep-Links immer mit
      // Scheme, daher praktisch unkritisch — hier festgehalten, nicht "gefixt".
      expect(parse('/join/ABC123'), 'ABC123');
    });

    test('relativer Nicht-Join-Pfad → null', () {
      expect(parse('/settings/ABC123'), isNull);
    });
  });
}
