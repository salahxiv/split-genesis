import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../models/activity_entry.dart';
import '../providers/activity_provider.dart';
import '../../groups/providers/groups_provider.dart';

class GlobalActivityScreen extends ConsumerWidget {
  const GlobalActivityScreen({super.key});

  static const _typeIcons = <ActivityType, IconData>{
    ActivityType.expenseCreated: Icons.add_circle,
    ActivityType.expenseUpdated: Icons.edit,
    ActivityType.expenseDeleted: Icons.delete,
    ActivityType.settlementRecorded: Icons.arrow_forward,
    ActivityType.settlementDeleted: Icons.remove_circle,
    ActivityType.memberAdded: Icons.person_add,
    ActivityType.memberRemoved: Icons.person_remove,
    ActivityType.groupCreated: Icons.group,
    ActivityType.groupRenamed: Icons.edit_note,
    ActivityType.memberJoined: Icons.person_add_alt,
  };

  static const _typeColors = <ActivityType, Color>{
    ActivityType.expenseCreated: Colors.blue,
    ActivityType.expenseUpdated: Colors.orange,
    ActivityType.expenseDeleted: Colors.red,
    ActivityType.settlementRecorded: AppTheme.positiveColor,
    ActivityType.settlementDeleted: Colors.red,
    ActivityType.memberAdded: Colors.green,
    ActivityType.memberRemoved: Colors.red,
    ActivityType.groupCreated: Colors.purple,
    ActivityType.groupRenamed: Colors.orange,
    ActivityType.memberJoined: Colors.green,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a group to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                        ),
                  ),
                ],
              ),
            );
          }

          // Combine activity from all groups
          final allActivities = groups
              .map((g) => ref.watch(activityProvider(g.id)))
              .toList();

          final isLoading = allActivities.any((a) => a.isLoading);
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final combined = <ActivityEntry>[];
          for (final a in allActivities) {
            a.whenData((list) => combined.addAll(list));
          }

          // Sort by timestamp descending
          combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (combined.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: combined.length,
            itemBuilder: (context, index) {
              final entry = combined[index];
              final icon = _typeIcons[entry.type] ?? Icons.info_outline;
              final color = _typeColors[entry.type] ?? Colors.grey;
              // Find group name
              final groupName = groups
                  .where((g) => g.id == entry.groupId)
                  .map((g) => g.name)
                  .firstOrNull;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(entry.description),
                subtitle: Text(
                  [
                    if (groupName != null) groupName,
                    DateFormat.MMMd().add_jm().format(entry.timestamp),
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                      ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorHandler.errorWidget(e),
      ),
    );
  }
}
