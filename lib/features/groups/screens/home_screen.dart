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
import '../models/group_type.dart';
import '../providers/groups_provider.dart';
import '../providers/group_summary_provider.dart';
import 'add_group_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'join_group_screen.dart';
import '../../balances/screens/group_detail_screen.dart';
import '../../balances/providers/balances_provider.dart';
import '../../activity/providers/activity_provider.dart';

/// Returns a human-readable relative time string for a DateTime.
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return DateFormat.yMMMd().format(dt);
}

/// Maps group type key to an emoji for the avatar.
String _groupEmoji(String type) {
  switch (type) {
    case 'trip':
      return '✈️';
    case 'household':
      return '🏠';
    case 'couple':
      return '❤️';
    case 'event':
      return '🎉';
    default:
      return '👥';
  }
}

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
    final initialCode = DeepLinkService.instance.initialCode;
    if (initialCode != null) {
      DeepLinkService.instance.clearInitialCode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateToJoin(initialCode);
      });
    }

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
      debugPrint('[PERF] _showJoinGroupDialog: looking up code "$code"');
      final sw = Stopwatch()..start();
      final cloudGroup =
          await SyncService.instance.findGroupByShareCode(code);
      debugPrint('[PERF] _showJoinGroupDialog: cloud lookup done in ${sw.elapsedMilliseconds}ms');
      if (cloudGroup != null && mounted) {
        Navigator.push(
          context,
          slideUpRoute(JoinGroupScreen(shareCode: code, prefetchedGroupData: cloudGroup)),
        );
        return;
      }

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final typeData = getGroupTypeData(group.type);
              return ScaleFadeIn(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SpringCard(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      debugPrint('[PERF] HomeScreen: tapped group "${group.name}" (${group.id})');
                      final sw = Stopwatch()..start();
                      Navigator.push(
                        context,
                        sharedAxisRoute(GroupDetailScreen(group: group)),
                      );
                      debugPrint('[PERF] HomeScreen: Navigator.push called at ${sw.elapsedMilliseconds}ms');
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
                                ref
                                    .read(groupsProvider.notifier)
                                    .deleteGroup(group.id);
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
                    child: _GroupCard(group: group, typeData: typeData),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorHandler.errorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            slideUpRoute(const AddGroupScreen()),
          );
        },
        tooltip: 'New Group',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Card — rich visual with emoji avatar, last activity subtitle
// ─────────────────────────────────────────────────────────────────────────────

class _GroupCard extends ConsumerWidget {
  final dynamic group;
  final GroupTypeData typeData;

  const _GroupCard({required this.group, required this.typeData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = typeData.color;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 3.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Emoji avatar with gradient background
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accentColor.withAlpha(40),
                    accentColor.withAlpha(15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _groupEmoji(group.type),
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name
                  Text(
                    group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Member count + total from summary
                  Consumer(
                    builder: (context, ref, _) {
                      final summaryAsync =
                          ref.watch(groupSummaryProvider(group.id));
                      return summaryAsync.when(
                        data: (summary) => Text(
                          '${summary.memberCount} members · ${formatCurrency(summary.totalExpenses, group.currency)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                        loading: () => const SizedBox(height: 14),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                  const SizedBox(height: 3),
                  // Last activity subtitle
                  Consumer(
                    builder: (context, ref, _) {
                      final activityAsync =
                          ref.watch(activityProvider(group.id));
                      return activityAsync.when(
                        data: (entries) {
                          if (entries.isEmpty) {
                            return Text(
                              'Created ${_relativeTime(group.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(80),
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          final latest = entries.first;
                          return Text(
                            'Last activity: ${_relativeTime(latest.timestamp)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(80),
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 14),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  // User balance badge
                  Consumer(
                    builder: (context, ref, _) {
                      final balanceAsync =
                          ref.watch(groupUserBalanceProvider(group.id));
                      return balanceAsync.when(
                        data: (ub) {
                          if (!ub.isKnown) return const SizedBox();
                          final amount = ub.amount!;
                          final absAmount = amount.abs();
                          Color color;
                          String label;
                          if (ub.status == UserBalanceStatus.positive) {
                            color = AppTheme.positiveColor;
                            label =
                                'owed ${formatCurrency(absAmount, ub.currency)}';
                          } else if (ub.status == UserBalanceStatus.negative) {
                            color = AppTheme.negativeColor;
                            label =
                                'owe ${formatCurrency(absAmount, ub.currency)}';
                          } else {
                            color = Colors.grey;
                            label = 'settled';
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withAlpha(60), width: 0.8),
                            ),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withAlpha(60),
            ),
          ],
        ),
      ),
    );
  }
}
