import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  bool _cachedOnline = true;
  final _controller = StreamController<bool>.broadcast();

  bool get isOnline => _cachedOnline;
  Stream<bool> get onlineStream => _controller.stream;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    _cachedOnline = !initial.contains(ConnectivityResult.none);
    debugPrint('[CONN] initial online: $_cachedOnline');

    _connectivity.onConnectivityChanged.listen((result) {
      final online = !result.contains(ConnectivityResult.none);
      if (online != _cachedOnline) {
        _cachedOnline = online;
        _controller.add(online);
        debugPrint('[CONN] connectivity changed: $_cachedOnline');
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}
