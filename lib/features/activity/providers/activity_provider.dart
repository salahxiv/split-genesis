import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_entry.dart';
import '../repositories/activity_repository.dart';

final activityRepositoryProvider = Provider((ref) => ActivityRepository());

final activityProvider = AsyncNotifierProvider.autoDispose.family<ActivityNotifier,
    List<ActivityEntry>, String>(ActivityNotifier.new);

class ActivityNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<ActivityEntry>, String> {
  @override
  Future<List<ActivityEntry>> build(String arg) async {
    final link = ref.keepAlive();
    Timer(const Duration(seconds: 30), link.close);
    return ref.read(activityRepositoryProvider).getActivitiesByGroup(arg);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
