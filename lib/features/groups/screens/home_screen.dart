import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final l10n = AppLocalizations.of(context);
    final code = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.joinGroupTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            placeholder: l10n.homeJoinCodePlaceholder,
            prefix: const Padding(
              padding: EdgeInsets.only(left: AppTheme.paddingS),
              child: Icon(CupertinoIcons.lock, size: 16),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.homeJoinAction),
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
          SnackBar(content: Text(l10n.homeGroupNotFoundByCode)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: groupsAsync.when(
        data: (groups) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverAppBar.large(
                title: const Text('Split'),
                actions: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SyncIndicator(),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.person_add),
                    tooltip: l10n.homeJoinTooltip,
                    onPressed: _showJoinGroupDialog,
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.add),
                    tooltip: l10n.homeNewGroupTooltip,
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
                      padding: const EdgeInsets.all(AppTheme.paddingXL),
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
                            l10n.homeEmptyTitle,
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
                            l10n.homeEmptySubtitle,
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
                            label: Text(l10n.homeCreateFirstGroup),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.paddingL,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
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
                // ── Stitch "Create New Group" — prominent below the list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, AppTheme.paddingS, AppTheme.paddingM, AppTheme.paddingM),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(28),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.push(
                          context,
                          slideUpRoute(const AddGroupScreen()),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.person_add, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.homeCreateNewGroup,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Extra bottom padding for tab bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
            ],
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Split')),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, stack) => CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Split')),
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
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(groupSummaryProvider(group.id));
    final balanceAsync = ref.watch(groupUserBalanceProvider(group.id));
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurface.withAlpha(120);

    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final iconBoxBg = isDark
        ? AppTheme.darkCardHigher
        : const Color(0xFFEFEEF3);
    final typeData = getGroupTypeData(group.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
      child: SpringCard(
        borderRadius: BorderRadius.circular(14),
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
              title: Text(l10n.homeDeleteGroupTitle),
              message: Text(l10n.homeDeleteGroupMessage(group.name)),
              actions: [
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    ref.read(groupsProvider.notifier).deleteGroup(group.id);
                  },
                  child: Text(l10n.delete),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Squircle icon box (Stitch-style)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  typeData.icon,
                  color: typeData.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // valueOrNull: render last known summary instantly.
                    // Avoids per-item loading flash on tab/screen returns.
                    () {
                      final s = summaryAsync.value;
                      if (s == null) {
                        return Text('…',
                            style: TextStyle(fontSize: 13, color: subtitleColor));
                      }
                      return Text(
                        l10n.homePersonCount(s.memberCount),
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      );
                    }(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // valueOrNull: render last known balance pill instantly.
              if (balanceAsync.value != null) _BalancePill(ub: balanceAsync.value!),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stitch-style balance pill: green / red / grey.
class _BalancePill extends StatelessWidget {
  final dynamic ub; // UserBalance — typed loosely to avoid extra import here

  const _BalancePill({required this.ub});

  @override
  Widget build(BuildContext context) {
    if (!(ub.isKnown as bool)) return const SizedBox();
    final amount = (ub.amount as double?) ?? 0.0;
    final absAmount = amount.abs();
    final status = ub.status;

    Color bg;
    Color fg;
    String label;
    if (status == UserBalanceStatus.positive) {
      bg = AppTheme.positiveColor.withAlpha(38);
      fg = const Color(0xFF1F7A36);
      label = '+${formatCurrency(absAmount, ub.currency as String)}';
    } else if (status == UserBalanceStatus.negative) {
      bg = AppTheme.negativeColor.withAlpha(38);
      fg = const Color(0xFFB52A20);
      label = '−${formatCurrency(absAmount, ub.currency as String)}';
    } else {
      bg = const Color(0xFFE9E9EB);
      fg = const Color(0xFF6E6E73);
      label = AppLocalizations.of(context).balanceSettled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
