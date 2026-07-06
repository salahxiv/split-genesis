import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/utils/error_handler.dart';

/// [AppErrorHandler.getMessage] maps raw exceptions to user-facing copy. Without
/// a [BuildContext] `_isGerman` falls back to `false`, so every assertion here
/// pins the English branch — deterministic, no widget tree needed.
void main() {
  group('AppErrorHandler.getMessage — Netzwerk', () {
    test('SocketException → Verbindungshinweis', () {
      expect(
        AppErrorHandler.getMessage(const SocketException('boom')),
        'No connection. Please check your internet.',
      );
    });

    test('NetworkException → Verbindungshinweis', () {
      expect(
        AppErrorHandler.getMessage(const NetworkException('down')),
        'No connection. Please check your internet.',
      );
    });

    test('"failed host lookup" im Text → Verbindungshinweis', () {
      expect(
        AppErrorHandler.getMessage('Failed host lookup: api.example.com'),
        'No connection. Please check your internet.',
      );
    });
  });

  group('AppErrorHandler.getMessage — Timeout', () {
    test('TimeoutException → Timeout-Hinweis', () {
      expect(
        AppErrorHandler.getMessage(TimeoutException('slow')),
        'The request took too long. Please try again.',
      );
    });

    test('"timed out" im Text → Timeout-Hinweis', () {
      expect(
        AppErrorHandler.getMessage('Operation timed out'),
        'The request took too long. Please try again.',
      );
    });
  });

  group('AppErrorHandler.getMessage — Auth', () {
    test('"invalid credentials" → Sign-in-Fehler', () {
      expect(
        AppErrorHandler.getMessage('Invalid credentials'),
        'Sign in failed.',
      );
    });

    test('AuthException-artiger Text → Sign-in-Fehler', () {
      expect(
        AppErrorHandler.getMessage('AuthException: bad token'),
        'Sign in failed.',
      );
    });
  });

  group('AppErrorHandler.getMessage — Berechtigung / Not-Found', () {
    test('"permission denied" → Berechtigungsfehler', () {
      expect(
        AppErrorHandler.getMessage('permission denied'),
        "You don't have permission for this action.",
      );
    });

    test('"403" → Berechtigungsfehler', () {
      expect(
        AppErrorHandler.getMessage('Request failed with status 403'),
        "You don't have permission for this action.",
      );
    });

    test('"not found" → Ressource-nicht-gefunden', () {
      expect(
        AppErrorHandler.getMessage('resource not found'),
        'The resource was not found.',
      );
    });

    test('"404" → Ressource-nicht-gefunden', () {
      expect(
        AppErrorHandler.getMessage('HTTP 404'),
        'The resource was not found.',
      );
    });
  });

  group('AppErrorHandler.getMessage — Fallback', () {
    test('unbekannter Fehler → generische Meldung', () {
      expect(
        AppErrorHandler.getMessage(StateError('weird')),
        'Something went wrong. Please restart the app.',
      );
    });

    test('null → generische Meldung (kein Crash)', () {
      expect(
        AppErrorHandler.getMessage(null),
        'Something went wrong. Please restart the app.',
      );
    });
  });
}
