import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

final syncStatusProvider = StreamProvider<SyncState>((ref) {
  return SyncService.instance.stateStream;
});
