import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/database/database_helper.dart';
import 'core/services/auth_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/sync/sync_service.dart';

bool _supabaseInitialized = false;

bool get isSupabaseInitialized => _supabaseInitialized;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
    debugPrint('=== END FLUTTER ERROR ===');
  };

  // Catch all uncaught async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR ===');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    debugPrint('=== END PLATFORM ERROR ===');
    return true;
  };

  // Pre-warm database so first provider query doesn't pay init cost
  final dbSw = Stopwatch()..start();
  await DatabaseHelper().database;
  debugPrint('[PERF] DB pre-warm: ${dbSw.elapsedMilliseconds}ms');

  // Initialize connectivity service early
  await ConnectivityService.instance.init();

  // Start non-blocking services
  await NotificationService.instance.initialize();
  await DeepLinkService.instance.init();

  // Show UI immediately
  runApp(
    const ProviderScope(
      child: SplitGenesisApp(),
    ),
  );

  // Initialize Supabase + sync in background after UI is up
  _initSupabaseInBackground();
}

Future<void> _initSupabaseInBackground() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Supabase init timeout — continuing in local-only mode');
        throw TimeoutException('Supabase init timed out');
      },
    );
    _supabaseInitialized = true;
    debugPrint('Supabase initialized successfully');

    await AuthService.instance.signInAnonymously().timeout(
      const Duration(seconds: 10),
      onTimeout: () => debugPrint('Auth timeout — continuing without auth'),
    );
    debugPrint('Auth done, userId: ${AuthService.instance.userId}');

    await SyncService.instance.init();
    SyncService.instance.pushPendingChanges();
  } catch (e) {
    debugPrint('Supabase error: $e');
    debugPrint('App running in local-only mode.');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
