import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._();
  DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription? _subscription;

  final _pendingCodeController = StreamController<String>.broadcast();
  Stream<String> get onJoinCode => _pendingCodeController.stream;

  String? _initialCode;
  String? get initialCode => _initialCode;
  void clearInitialCode() => _initialCode = null;

  Future<void> init() async {
    // Check initial link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {}

    // Listen for incoming links
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  /// Extracts a group join code from a deep link, or null when [uri] is not a
  /// valid join link. Accepts `splitgenesis://join/CODE` and
  /// `https://<host>/join/CODE`; query strings and extra path segments are
  /// ignored, an empty/missing code yields null. Pure — no side effects — so
  /// the parsing edge cases can be unit-tested directly.
  static String? parseJoinCode(Uri uri) {
    String? code;

    if (uri.scheme == 'splitgenesis' && uri.host == 'join') {
      // splitgenesis://join/CODE
      code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      // https://splitgenesis.app/join/CODE
      code = uri.pathSegments[1];
    }

    return (code != null && code.isNotEmpty) ? code : null;
  }

  void _handleUri(Uri uri) {
    final code = parseJoinCode(uri);
    if (code != null) {
      _initialCode ??= code;
      _pendingCodeController.add(code);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pendingCodeController.close();
  }
}
