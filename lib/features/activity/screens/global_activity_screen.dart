import 'package:flutter/cupertino.dart';
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
    ActivityType.expenseCreated: CupertinoIcons.add_circled,
    ActivityType.expenseUpdated: CupertinoIcons.pencil,
    ActivityType.expenseDeleted: CupertinoIcons.trash,
    ActivityType.settlementRecorded: CupertinoIcons.arrow_right,
    ActivityType.settlementDeleted: CupertinoIcons.minus_circle,
    ActivityType.memberAdded: CupertinoIcons.person_add,
    ActivityType.memberRemoved: CupertinoIcons.person_badge_minus,
    ActivityType.groupCreated: CupertinoIcons.person_2_fill,
    ActivityType.groupRenamed: CupertinoIcons.pencil_outline,
    ActivityType.memberJoined: CupertinoIcons.arrow_right_circle,
  };

  static const _typeColors = <ActivityType, Color>{
    ActivityType.expenseCreated: AppTheme.primaryColor,
    ActivityType.expenseUpdated: AppTheme.warningColor,
    ActivityType.expenseDeleted: AppTheme.negativeColor,
    ActivityType.settlementRecorded: AppTheme.positiveColor,
    ActivityType.settlementDeleted: AppTheme.negativeColor,
    ActivityType.memberAdded: AppTheme.positiveColor,
    ActivityType.memberRemoved: AppTheme.negativeColor,
    ActivityType.groupCreated: AppTheme.primaryColor,
    ActivityType.groupRenamed: AppTheme.warningColor,
    ActivityType.memberJoined: AppTheme.positiveColor,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar.large(title: const Text('Activity')),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
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
                  ),
                ),
              ],
            );
          }

          // Combine activity from all groups
          final allActivities = groups
              .map((g) => ref.watch(activityProvider(g.id)))
              .toList();

          final isLoading = allActivities.any((a) => a.isLoading);

          final combined = <ActivityEntry>[];
          for (final a in allActivities) {
            a.whenData((list) => combined.addAll(list));
          }
          combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(title: const Text('Activity')),
              if (isLoading && combined.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (combined.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
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
                  ),
                )
              else
                SliverList.builder(
                  itemCount: combined.length,
                  itemBuilder: (context, index) {
                    final entry = combined[index];
                    final icon = _typeIcons[entry.type] ?? CupertinoIcons.info;
                    final color = _typeColors[entry.type] ?? Colors.grey;
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
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Activity')),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (e, _) => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Activity')),
            SliverFillRemaining(child: AppErrorHandler.errorWidget(e)),
          ],
        ),
      ),
    );
  }
}
