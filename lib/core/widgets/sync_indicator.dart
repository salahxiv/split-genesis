import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_service.dart';
import '../sync/sync_status_provider.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);

    return syncState.when(
      data: (state) {
        switch (state) {
          case SyncState.syncing:
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          case SyncState.offline:
            return Icon(
              Icons.cloud_off,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            );
          case SyncState.error:
            return Icon(
              Icons.cloud_off,
              size: 20,
              color: Colors.orange.withAlpha(180),
            );
          case SyncState.idle:
            return Icon(
              Icons.cloud_done,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
            );
        }
      },
      loading: () => const SizedBox(width: 20, height: 20),
      error: (_, __) => const SizedBox(width: 20, height: 20),
    );
  }
}
