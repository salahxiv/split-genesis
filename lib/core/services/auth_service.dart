import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  bool _initialized = false;

  String? get userId {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentUser?.id;
  }

  bool get isSignedIn {
    if (!_initialized) return false;
    return Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> signInAnonymously() async {
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentUser != null) {
        _initialized = true;
        return;
      }
      await auth.signInAnonymously();
      _initialized = true;
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }
}
