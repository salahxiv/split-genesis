import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/recurring_expense_service.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../../core/widgets/spring_card.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../models/group.dart';
import '../models/group_type.dart';
import '../providers/groups_provider.dart';
import '../providers/group_summary_provider.dart';
import 'add_group_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'join_group_screen.dart';
import '../../balances/screens/group_detail_screen.dart';
import '../../balances/providers/balances_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription? _deepLinkSub;
  StreamSubscription? _syncCountSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initSyncSnackbar();
    // Check for due recurring expenses on app start (Issue #48)
    RecurringExpenseService.instance.checkAndCreateDue();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _syncCountSub?.cancel();
    super.dispose();
  }

  /// Listen to OfflineQueueService synced-count stream and show
  /// "X Änderungen synchronisiert" snackbar after each successful flush.
  void _initSyncSnackbar() {
    _syncCountSub =
        SyncService.instance.syncedCountStream.listen((count) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).syncChanges(count)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    });
  }

  void _initDeepLinks() {
    // Handle initial deep link
    final initialCode = DeepLinkService.instance.initialCode;
    if (initialCode != null) {
      DeepLinkService.instance.clearInitialCode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateToJoin(initialCode);
      });
    }

    // Listen for future deep links
    _deepLinkSub = DeepLinkService.instance.onJoinCode.listen((code) {
      if (mounted) _navigateToJoin(code);
    });
  }

  void _navigateToJoin(String code) {
    Navigator.push(
      context,
      slideUpRoute(JoinGroupScreen(shareCode: code)),
    );
  }

  Future<void> _showJoinGroupDialog() async {
    final controller = TextEditingController();
    final code = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Join Group'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            placeholder: 'e.g., A1B2C3D4',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.lock, size: 16),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty && mounted) {
      // First try cloud lookup
      debugPrint('[PERF] _showJoinGroupDialog: looking up code "$code"');
      final sw = Stopwatch()..start();
      final cloudGroup =
          await SyncService.instance.findGroupByShareCode(code);
      debugPrint('[PERF] _showJoinGroupDialog: cloud lookup done in ${sw.elapsedMilliseconds}ms');
      if (cloudGroup != null && mounted) {
        // Pass prefetched data to avoid double network call
        Navigator.push(
          context,
          slideUpRoute(JoinGroupScreen(shareCode: code, prefetchedGroupData: cloudGroup)),
        );
        return;
      }

      // Fall back to local lookup
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.getGroupByShareCode(code);
      if (group != null && mounted) {
        Navigator.push(
          context,
          sharedAxisRoute(GroupDetailScreen(group: group)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No group found with that code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      body: groupsAsync.when(
        data: (groups) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(
                title: const Text('Groups'),
                actions: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SyncIndicator(),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.person_add),
                    tooltip: 'Join group',
                    onPressed: _showJoinGroupDialog,
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.add),
                    tooltip: 'New group',
                    onPressed: () => Navigator.push(
                      context,
                      slideUpRoute(const AddGroupScreen()),
                    ),
                  ),
                ],
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(scale: value, child: child);
                            },
                            child: Icon(
                              CupertinoIcons.group,
                              size: 72,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(60),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No groups yet',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(150),
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a group to start splitting expenses',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(100),
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              slideUpRoute(const AddGroupScreen()),
                            ),
                            icon: const Icon(CupertinoIcons.add),
                            label: const Text('Create your first group'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return ScaleFadeIn(
                        index: index,
                        child: _GroupListItem(group: group),
                      );
                    },
                  ),
                ),
              // Extra bottom padding for tab bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Groups')),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Groups')),
            SliverFillRemaining(
              child: AppErrorHandler.errorWidget(error),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted list item widget — scopes provider watches to a single item,
/// preventing the parent ListView from rebuilding when one item's data changes.
class _GroupListItem extends ConsumerWidget {
  final Group group;

  const _GroupListItem({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(groupSummaryProvider(group.id));
    final balanceAsync = ref.watch(groupUserBalanceProvider(group.id));
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withAlpha(120);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SpringCard(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            sharedAxisRoute(GroupDetailScreen(group: group)),
          );
        },
        onLongPress: () {
          showCupertinoModalPopup<void>(
            context: context,
            builder: (ctx) => CupertinoActionSheet(
              title: const Text('Delete Group'),
              message: Text(
                  'Delete "${group.name}" and all its expenses? This cannot be undone.'),
              actions: [
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(groupsProvider.notifier).deleteGroup(group.id);
                  },
                  child: const Text('Delete Group'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
          );
        },
        child: Container(
          color: theme.cardTheme.color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: getGroupTypeData(group.type).color.withAlpha(30),
                  child: Icon(
                    getGroupTypeData(group.type).icon,
                    color: getGroupTypeData(group.type).color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      summaryAsync.when(
                        data: (summary) => Text(
                          '${summary.memberCount} members  ·  ${formatCurrency(summary.totalExpenses, group.currency)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                        ),
                        loading: () => Text(
                          DateFormat.yMMMd().format(group.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                      balanceAsync.when(
                        data: (ub) {
                          if (!ub.isKnown) return const SizedBox();
                          final amount = ub.amount!;
                          final absAmount = amount.abs();
                          Color color;
                          String label;
                          if (ub.status == UserBalanceStatus.positive) {
                            color = AppTheme.positiveColor;
                            label = 'owed ${formatCurrency(absAmount, ub.currency)}';
                          } else if (ub.status == UserBalanceStatus.negative) {
                            color = AppTheme.negativeColor;
                            label = 'owe ${formatCurrency(absAmount, ub.currency)}';
                          } else {
                            color = Colors.grey;
                            label = 'settled';
                          }
                          return Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
