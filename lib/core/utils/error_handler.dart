import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Central error handler for Split Genesis.
/// Maps technical exceptions to user-friendly messages (DE/EN).
class AppErrorHandler {
  AppErrorHandler._();

  /// Returns a user-friendly error message for the given [error].
  /// Language is determined by the device locale via [context].
  static String getMessage(dynamic error, [BuildContext? context]) {
    final isGerman = _isGerman(context);

    final err = error?.toString().toLowerCase() ?? '';

    // Network / connectivity
    if (error is SocketException ||
        error is NetworkException ||
        err.contains('socketexception') ||
        err.contains('network') ||
        err.contains('connection refused') ||
        err.contains('no route to host') ||
        err.contains('failed host lookup')) {
      return isGerman
          ? 'Keine Verbindung. Bitte prüfe dein Internet.'
          : 'No connection. Please check your internet.';
    }

    // Timeout
    if (error is TimeoutException ||
        err.contains('timeout') ||
        err.contains('timed out')) {
      return isGerman
          ? 'Die Anfrage hat zu lange gedauert. Bitte nochmal versuchen.'
          : 'The request took too long. Please try again.';
    }

    // Supabase / auth errors
    if (err.contains('invalid login') ||
        err.contains('invalid credentials') ||
        err.contains('email not confirmed') ||
        err.contains('user not found') ||
        err.contains('wrong password') ||
        err.contains('authexception') ||
        err.contains('auth') && err.contains('error')) {
      return isGerman
          ? 'Anmeldung fehlgeschlagen.'
          : 'Sign in failed.';
    }

    // Permission / not found
    if (err.contains('permission denied') || err.contains('403')) {
      return isGerman
          ? 'Keine Berechtigung für diese Aktion.'
          : 'You don\'t have permission for this action.';
    }

    if (err.contains('not found') || err.contains('404')) {
      return isGerman
          ? 'Die Ressource wurde nicht gefunden.'
          : 'The resource was not found.';
    }

    // Fallback
    return isGerman
        ? 'Etwas ist schiefgelaufen. Bitte App neu starten.'
        : 'Something went wrong. Please restart the app.';
  }

  /// Shows a [SnackBar] with a user-friendly error message.
  static void handleError(
    dynamic error,
    BuildContext context, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = getMessage(error, context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a user-friendly error widget (for use in `.error` builders).
  static Widget errorWidget(dynamic error, [BuildContext? context]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          getMessage(error, context),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static bool _isGerman(BuildContext? context) {
    if (context == null) return false;
    try {
      final locale = Localizations.localeOf(context);
      return locale.languageCode == 'de';
    } catch (_) {
      return false;
    }
  }
}

// Placeholder so SocketException-style check compiles on all platforms.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}
