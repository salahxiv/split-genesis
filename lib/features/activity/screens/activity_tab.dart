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
                Icon(Icons.history,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(80)),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Actions will appear here',
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
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            }
            return _buildActivityItem(context, item as ActivityEntry);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorHandler.errorWidget(e),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityEntry activity) {
    final color = _typeColors[activity.type] ?? AppTheme.primaryColor;
    final icon = _typeIcons[activity.type] ?? Icons.info;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, size: 18, color: color),
          ),
          title: Text(
            activity.description,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Text(
            _relativeTime(activity.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(120),
                ),
          ),
        ),
      ),
    );
  }
}
