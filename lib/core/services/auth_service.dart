import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles anonymous authentication with persistence across app restarts.
///
/// Strategy:
/// 1. On first login, save the Supabase user-id and refresh-token to
///    FlutterSecureStorage.
/// 2. On subsequent launches, restore the session from the stored tokens
///    (Supabase handles this automatically via [recoverSession]).
/// 3. If no stored session is found, sign in anonymously and persist the
///    new session.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyUserId = 'anon_user_id';
  static const _keyAccessToken = 'anon_access_token';
  static const _keyRefreshToken = 'anon_refresh_token';

  bool _initialized = false;

  String? get userId {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentUser?.id;
  }

  bool get isSignedIn {
    if (!_initialized) return false;
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Call once at app startup. Restores a persisted session when possible,
  /// otherwise signs in anonymously and persists the new session.
  Future<void> signInAnonymously() async {
    try {
      final auth = Supabase.instance.client.auth;

      // 1. Already have an active in-memory session (e.g. hot restart).
      if (auth.currentUser != null) {
        _initialized = true;
        return;
      }

      // 2. Try to restore from SecureStorage.
      final storedRefreshToken = await _storage.read(key: _keyRefreshToken);
      final storedAccessToken = await _storage.read(key: _keyAccessToken);

      if (storedRefreshToken != null && storedAccessToken != null) {
        try {
          final response = await auth.setSession(storedAccessToken);
          if (response.user != null) {
            debugPrint('[Auth] Session restored for user: ${response.user!.id}');
            _initialized = true;
            // Persist the refreshed tokens.
            await _persistSession(response.session!);
            return;
          }
        } catch (e) {
          // Stored session is invalid or expired — fall through to re-auth.
          debugPrint('[Auth] Stored session invalid, re-authenticating: $e');
          await _clearStoredSession();
        }
      }

      // 3. No valid session — sign in anonymously and persist.
      final response = await auth.signInAnonymously();
      if (response.user != null && response.session != null) {
        debugPrint('[Auth] Signed in anonymously as: ${response.user!.id}');
        await _persistSession(response.session!);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[Auth] Error during signInAnonymously: $e');
    }
  }

  Future<void> _persistSession(Session session) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: session.user.id),
      _storage.write(key: _keyAccessToken, value: session.accessToken),
      _storage.write(key: _keyRefreshToken, value: session.refreshToken ?? ''),
    ]);
    debugPrint('[Auth] Session persisted for user: ${session.user.id}');
  }

  Future<void> _clearStoredSession() async {
    await Future.wait([
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  /// Sign out and clear the persisted session.
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    await _clearStoredSession();
    _initialized = false;
  }
}
