import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../models/activity_entry.dart';
import '../providers/activity_provider.dart';

class ActivityTab extends ConsumerWidget {
  final String groupId;

  const ActivityTab({super.key, required this.groupId});

  static const _typeIcons = <ActivityType, IconData>{
    ActivityType.expenseCreated: Icons.add_circle,
    ActivityType.expenseUpdated: Icons.edit,
    ActivityType.expenseDeleted: Icons.delete,
    ActivityType.settlementRecorded: Icons.arrow_forward,
    ActivityType.settlementDeleted: Icons.remove_circle,
    ActivityType.memberAdded: Icons.person_add,
    ActivityType.memberRemoved: Icons.person_remove,
    ActivityType.groupCreated: Icons.group_add,
    ActivityType.groupRenamed: Icons.drive_file_rename_outline,
    ActivityType.memberJoined: Icons.login,
  };

  static const _typeColors = <ActivityType, Color>{
    ActivityType.expenseCreated: AppTheme.positiveColor,
    ActivityType.expenseUpdated: AppTheme.warningColor,
    ActivityType.expenseDeleted: AppTheme.negativeColor,
    ActivityType.settlementRecorded: AppTheme.primaryColor,
    ActivityType.settlementDeleted: AppTheme.negativeColor,
    ActivityType.memberAdded: AppTheme.positiveColor,
    ActivityType.memberRemoved: AppTheme.negativeColor,
    ActivityType.groupCreated: AppTheme.primaryColor,
    ActivityType.groupRenamed: AppTheme.warningColor,
    ActivityType.memberJoined: AppTheme.positiveColor,
  };

  String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(timestamp);
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.MMMd().format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityProvider(groupId));

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.3,
                  child: Icon(
                    CupertinoIcons.clock_arrow_circlepath,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Noch nichts passiert',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aktionen erscheinen hier',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(100),
                      ),
                ),
              ],
            ),
          );
        }

        // Group by date and flatten into a list for O(1) access
        final grouped = <String, List<ActivityEntry>>{};
        for (final a in activities) {
          final label = _dateLabel(a.timestamp);
          grouped.putIfAbsent(label, () => []).add(a);
        }

        final flatItems = <Object>[];
        for (final entry in grouped.entries) {
          flatItems.add(entry.key); // header
          flatItems.addAll(entry.value); // activities
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flatItems.length,
          itemBuilder: (context, index) {
            final item = flatItems[index];
            if (item is String) {
              // iOS-style date header: labelSmall, uppercase, grey
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  item.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                        letterSpacing: 0.5,
                      ),
                ),
              );
            }

            final activityEntry = item as ActivityEntry;
            final nextIndex = index + 1;
            final isLast = nextIndex >= flatItems.length ||
                flatItems[nextIndex] is String;

            return _buildActivityItem(
              context,
              activityEntry,
              isFirst: index == 0 || flatItems[index - 1] is String,
              isLast: isLast,
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorHandler.errorWidget(e),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ActivityEntry activity, {
    required bool isFirst,
    required bool isLast,
  }) {
    final color = _typeColors[activity.type] ?? AppTheme.primaryColor;
    final icon = _typeIcons[activity.type] ?? Icons.info;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withAlpha(25),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  _relativeTime(activity.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 58),
        ],
      ),
    );
  }
}
