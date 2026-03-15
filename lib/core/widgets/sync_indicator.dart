import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/sync_service.dart';
import '../sync/sync_status_provider.dart';

/// Compact sync/offline status badge for AppBar
/// Shows: "✓ Offline ready" | "⟳ Syncing" | "✓ Synced"
/// Issue #65: Offline-First Resilience Banner
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);

    return syncState.when(
      data: (state) => _buildBadge(context, state),
      loading: () => const SizedBox(width: 20, height: 20),
      error: (_, __) => const SizedBox(width: 20, height: 20),
    );
  }

  Widget _buildBadge(BuildContext context, SyncState state) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (state) {
      case SyncState.offline:
        return _StatusBadge(
          icon: Icons.wifi_off_rounded,
          label: '✓ Offline ready',
          color: colorScheme.onSurface.withAlpha(160),
          backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(180),
        );
      case SyncState.syncing:
        return _SyncingBadge(
          label: 'Syncing',
          color: colorScheme.primary,
        );
      case SyncState.error:
        return _StatusBadge(
          icon: Icons.sync_problem_rounded,
          label: 'Sync error',
          color: Colors.orange,
          backgroundColor: Colors.orange.withAlpha(30),
        );
      case SyncState.idle:
        return _StatusBadge(
          icon: Icons.cloud_done_rounded,
          label: '✓ Synced',
          color: colorScheme.onSurface.withAlpha(80),
          backgroundColor: Colors.transparent,
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 13, color: color),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncingBadge extends StatefulWidget {
  final String label;
  final Color color;

  const _SyncingBadge({required this.label, required this.color});

  @override
  State<_SyncingBadge> createState() => _SyncingBadgeState();
}

class _SyncingBadgeState extends State<_SyncingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          RotationTransition(
            turns: _controller,
            child: Icon(Icons.sync_rounded, size: 13, color: widget.color),
          ),
          Text(
            '⟳ ${widget.label}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
