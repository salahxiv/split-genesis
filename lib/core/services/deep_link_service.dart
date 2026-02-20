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

  void _handleUri(Uri uri) {
    // Handle splitgenesis://join/{code}
    // or https://splitgenesis.app/join/{code}
    String? code;

    if (uri.scheme == 'splitgenesis' && uri.host == 'join') {
      // splitgenesis://join/CODE
      code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      // https://splitgenesis.app/join/CODE
      code = uri.pathSegments[1];
    }

    if (code != null && code.isNotEmpty) {
      _initialCode ??= code;
      _pendingCodeController.add(code);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pendingCodeController.close();
  }
}
