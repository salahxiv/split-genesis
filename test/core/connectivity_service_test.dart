import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    test('is a singleton', () {
      final a = ConnectivityService.instance;
      final b = ConnectivityService.instance;
      expect(identical(a, b), isTrue);
    });

    test('default online state is true (optimistic)', () {
      // Before init() is called, the default should be true
      expect(ConnectivityService.instance.isOnline, isTrue);
    });
  });
}
