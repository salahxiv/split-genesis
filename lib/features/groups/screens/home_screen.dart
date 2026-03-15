import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/recurring_expense_service.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../../core/utils/currency_utils.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/group_type.dart';
import '../providers/groups_provider.dart';
import '../providers/group_summary_provider.dart';
import 'add_group_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'join_group_screen.dart';
import '../../balances/screens/group_detail_screen.dart';

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
      slideRoute(JoinGroupScreen(shareCode: code)),
    );
  }

  Future<void> _showJoinGroupDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
            hintText: 'e.g., A1B2C3D4',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vpn_key),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
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
          slideRoute(JoinGroupScreen(shareCode: code, prefetchedGroupData: cloudGroup)),
        );
        return;
      }

      // Fall back to local lookup
      final repo = ref.read(groupRepositoryProvider);
      final group = await repo.getGroupByShareCode(code);
      if (group != null && mounted) {
        Navigator.push(
          context,
          slideRoute(GroupDetailScreen(group: group)),
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
      appBar: AppBar(
        title: const Text('Split Genesis'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SyncIndicator(),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Join group',
            onPressed: _showJoinGroupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                slideRoute(const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
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
                        Icons.group_add,
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
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Tooltip(
                    message: 'Hold to delete group',
                    triggerMode: TooltipTriggerMode.longPress,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                      debugPrint('[PERF] HomeScreen: tapped group "${group.name}" (${group.id})');
                      final sw = Stopwatch()..start();
                      // BUG-06 fix: listenToGroup is now started in GroupDetailScreen.initState()
                      // to ensure proper lifecycle ownership. Removed from here.
                      Navigator.push(
                        context,
                        slideRoute(GroupDetailScreen(group: group)),
                      );
                      debugPrint('[PERF] HomeScreen: Navigator.push called at ${sw.elapsedMilliseconds}ms');
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Group'),
                          content: Text(
                              'Delete "${group.name}" and all its expenses?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(groupsProvider.notifier)
                                    .deleteGroup(group.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final summaryAsync = ref.watch(
                                        groupSummaryProvider(group.id));
                                    return summaryAsync.when(
                                      data: (summary) => Text(
                                        '${summary.memberCount} members  ·  ${formatCurrency(summary.totalExpenses, group.currency)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(120),
                                            ),
                                      ),
                                      loading: () => Text(
                                        DateFormat.yMMMd()
                                            .format(group.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha(120),
                                            ),
                                      ),
                                      error: (_, __) => const SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(80),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ), // closes Tooltip
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorHandler.errorWidget(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            slideRoute(const AddGroupScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
