import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/currency_utils.dart';
import '../../groups/models/group_type.dart';
import '../../groups/screens/group_settings_screen.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/screens/activity_tab.dart';
import '../../activity/services/activity_logger.dart';
import '../../groups/models/group.dart';
import '../../expenses/models/expense.dart';
import '../../expenses/models/expense_category.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../providers/balances_provider.dart';
import '../../expenses/screens/add_expense_sheet.dart';
import '../../expenses/screens/expense_detail_screen.dart';
import '../../expenses/screens/statistics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/screens/manage_members_screen.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../settlements/providers/settlements_provider.dart';
import '../../settlements/screens/settle_up_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
// settlementRecordsProvider is still needed for the "Mark as Paid" action

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _selectedSegment = 0;
  late String _groupName;

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;

    // Realtime subscription lifecycle is owned by this widget. Only `expenses`
    // and `settlements` emit Realtime events; the callback invalidates exactly
    // the relevant provider on each event.
    SyncService.instance.listenToGroup(widget.group.id);
    SyncService.instance.onRealtimeChange = (groupId, table) {
      if (!mounted) return;
      switch (table) {
        case 'expenses':
          ref.invalidate(expensesProvider(groupId));
          ref.invalidate(groupComputedDataProvider(groupId));
        case 'settlements':
          ref.invalidate(settlementRecordsProvider(groupId));
          ref.invalidate(groupComputedDataProvider(groupId));
      }
    };
  }

  @override
  void dispose() {
    // Clear the callback before stopping — avoids calling invalidate on a
    // disposed ProviderContainer after the screen is gone.
    SyncService.instance.onRealtimeChange = null;
    SyncService.instance.stopListening(widget.group.id);
    super.dispose();
  }

  Future<void> _renameGroup() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _groupName);
    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.groupDetailRenameGroupTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: l10n.groupDetailGroupNamePlaceholder,
            textCapitalization: TextCapitalization.words,
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
            child: Text(l10n.groupDetailSave),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != _groupName) {
      await ref
          .read(groupsProvider.notifier)
          .renameGroup(widget.group.id, newName);
      setState(() => _groupName = newName);
    }
  }

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context);
    try {
      final expenses = await ref.read(expensesProvider(widget.group.id).future);
      final members = await ref.read(membersProvider(widget.group.id).future);
      final filePath = await CsvExportService.instance.exportGroup(
        group: widget.group,
        expenses: expenses,
        members: members,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'text/csv')],
        subject: l10n.groupDetailCsvExportSubject(_groupName),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupDetailCsvExportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context);
    try {
      final expenses = await ref.read(expensesProvider(widget.group.id).future);
      final members = await ref.read(membersProvider(widget.group.id).future);
      final computedData = await ref.read(groupComputedDataProvider(widget.group.id).future);
      final filePath = await PdfExportService.instance.exportGroup(
        group: widget.group,
        expenses: expenses,
        members: members,
        balances: computedData.multiCurrencyBalances,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/pdf')],
        subject: l10n.groupDetailPdfExportSubject(_groupName),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupDetailPdfExportFailed(e.toString()))),
      );
    }
  }

  void _showShareSheet() {
    final l10n = AppLocalizations.of(context);
    final code = widget.group.shareCode;
    final shareText = l10n.groupDetailShareText(_groupName, code);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppTheme.paddingL, AppTheme.paddingL, AppTheme.paddingL, MediaQuery.of(ctx).viewPadding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.groupDetailInviteTo(_groupName),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            // Large code display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.groupDetailInviteCode,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Copy button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.systemGrey5,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.groupDetailCodeCopied)),
                  );
                  Navigator.pop(ctx);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_doc, size: 18, color: CupertinoColors.activeBlue),
                    const SizedBox(width: 8),
                    Text(l10n.groupDetailCopyCode, style: TextStyle(color: CupertinoColors.activeBlue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Share button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.share(shareText);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.share, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.groupDetailShareInvite),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddExpense() async {
    try {
      await showStitchAddExpenseSheet(context, group: widget.group);
      ref.invalidate(expensesProvider(widget.group.id));
      ref.invalidate(activityProvider(widget.group.id));
    } catch (e, stack) {
      debugPrint('[DEBUG] FAB ERROR: $e');
      debugPrint('[DEBUG] FAB STACK: $stack');
    }
  }

  Future<void> _openRecordPayment() async {
    final l10n = AppLocalizations.of(context);
    final members = ref.read(membersProvider(widget.group.id)).valueOrNull ?? [];
    if (members.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupDetailNeedTwoMembers)),
        );
      }
      return;
    }

    String? fromId;
    String? toId;
    final amountController = TextEditingController();

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: Text(l10n.groupDetailRecordPayment),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.groupDetailFrom),
                  items: members
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  value: fromId,
                  onChanged: (v) => setDialogState(() => fromId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.groupDetailTo),
                  items: members
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                      .toList(),
                  value: toId,
                  onChanged: (v) => setDialogState(() => toId = v),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: amountController,
                  placeholder: l10n.groupDetailAmount,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: AppTheme.paddingS),
                    child: Text('\$ '),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.groupDetailRecord),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && fromId != null && toId != null && fromId != toId) {
      final amount = double.tryParse(amountController.text);
      if (amount != null && amount > 0) {
        try {
          final memberMap = {for (var m in members) m.id: m.name};
          await ref.read(settlementRecordsProvider(widget.group.id).notifier).addSettlement(
            fromMemberId: fromId!,
            toMemberId: toId!,
            amount: amount,
            fromMemberName: memberMap[fromId!] ?? l10n.groupDetailUnknownMember,
            toMemberName: memberMap[toId!] ?? l10n.groupDetailUnknownMember,
          );
          ref.invalidate(groupComputedDataProvider(widget.group.id));
          await ActivityLogger.instance.logSettlementRecorded(
            groupId: widget.group.id,
            fromName: memberMap[fromId!] ?? l10n.groupDetailUnknownMember,
            toName: memberMap[toId!] ?? l10n.groupDetailUnknownMember,
            amount: amount,
          );
          ref.invalidate(activityProvider(widget.group.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.groupDetailPaymentRecorded)),
            );
          }
        } catch (e, stack) {
          debugPrint('[ERROR] Record payment failed: $e');
          debugPrint('[ERROR] Stack: $stack');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.groupDetailPaymentError(e.toString()))),
            );
          }
        }
      }
    }
    amountController.dispose();
  }

  Future<void> _openAddMember() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.groupDetailAddMember),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: l10n.groupDetailName,
            prefix: Padding(
              padding: const EdgeInsets.only(left: AppTheme.paddingS),
              child: Icon(CupertinoIcons.person_add, size: 18, color: CupertinoColors.systemGrey),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
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
            child: Text(l10n.groupDetailAdd),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(membersProvider(widget.group.id).notifier).addMember(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupDetailMemberAdded(name))),
        );
      }
    }
    controller.dispose();
  }

  // Simple FAB — single tap for Add Expense
  Widget _buildFab() {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton(
      onPressed: _openAddExpense,
      tooltip: l10n.groupDetailAddExpense,
      child: const Icon(CupertinoIcons.add),
    );
  }

  void _showMoreMenu() {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                slideUpRoute(ManageMembersScreen(groupId: widget.group.id)),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.person_2, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailMembers),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                slideUpRoute(StatisticsScreen(
                  groupId: widget.group.id,
                  groupName: _groupName,
                )),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.chart_bar, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailStatistics),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _renameGroup();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.pencil, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailRename),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openAddMember();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.person_add, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailAddMember),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openRecordPayment();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.arrow_right_arrow_left, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailRecordPayment),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _exportCsv();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.table, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailExportCsv),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _exportPdf();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.doc_richtext, size: 20),
                const SizedBox(width: 8),
                Text(l10n.groupDetailExportPdf),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PERF] GroupDetailScreen.build() called for "${widget.group.name}"');
    final l10n = AppLocalizations.of(context);
    final groupId = widget.group.id;

    final segmentChildren = <int, Widget>{
      0: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.doc_text, size: 16),
          const SizedBox(width: 4),
          Text(l10n.groupDetailExpensesTab),
        ],
      ),
      1: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.equal_circle, size: 16),
          const SizedBox(width: 4),
          Text(l10n.groupDetailBalancesTab),
        ],
      ),
      2: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.clock, size: 16),
          const SizedBox(width: 4),
          Text(l10n.groupDetailActivityTab),
        ],
      ),
    };

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        title: const Text('Split'),
        actions: [
          const SyncIndicator(),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showShareSheet(),
            child: const Icon(CupertinoIcons.share),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              slideRoute(GroupSettingsScreen(group: widget.group)),
            ),
            child: const Icon(CupertinoIcons.settings),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showMoreMenu,
            child: const Icon(CupertinoIcons.ellipsis_circle),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stitch group header: emoji + name + avatar stack + balance card
          _StitchGroupHeader(group: widget.group, groupName: _groupName),
          // Cupertino sliding segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, 4, AppTheme.paddingM, AppTheme.paddingS),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                children: segmentChildren,
                onValueChanged: (int? value) {
                  if (value != null) {
                    setState(() => _selectedSegment = value);
                  }
                },
              ),
            ),
          ),
          // Tab content — Stitch order: Ausgaben (0) / Schulden (1) / Aktivität (2)
          Expanded(
            child: IndexedStack(
              index: _selectedSegment,
              children: [
                _ExpensesTab(group: widget.group),
                _BalancesTab(group: widget.group, groupId: groupId, currency: widget.group.currency),
                ActivityTab(groupId: groupId),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}

/// Stitch-style header above the tab switcher: large emoji + group name,
/// avatar stack of members (with +N overflow), and a balance card showing
/// the current user's total balance in this group.
class _StitchGroupHeader extends ConsumerWidget {
  final Group group;
  final String groupName;
  const _StitchGroupHeader({required this.group, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(membersProvider(group.id));
    final balanceAsync = ref.watch(groupUserBalanceProvider(group.id));
    final typeData = getGroupTypeData(group.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final secondaryLabel =
        isDark ? AppTheme.iosSecondaryLabel : const Color(0xFF6E6E73);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, AppTheme.paddingS, AppTheme.paddingM, 12),
      child: Column(
        children: [
          // Emoji + Name (large, centered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeData.color.withAlpha(36),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(typeData.icon, color: typeData.color, size: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar stack
          membersAsync.when(
            data: (members) => _AvatarStack(members: members),
            loading: () => const SizedBox(height: 32),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          // Balance card
          balanceAsync.when(
            data: (ub) {
              if (!ub.isKnown) return const SizedBox.shrink();
              final amount = ub.amount ?? 0.0;
              final absAmount = amount.abs();
              String label;
              Color color;
              if (ub.status == UserBalanceStatus.positive) {
                label = l10n.groupDetailTotalYouAreOwed;
                color = AppTheme.positiveColor;
              } else if (ub.status == UserBalanceStatus.negative) {
                label = l10n.groupDetailTotalYouOwe;
                color = AppTheme.negativeColor;
              } else {
                label = l10n.groupDetailAllSettled;
                color = secondaryLabel;
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppTheme.paddingM),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: secondaryLabel),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ub.status == UserBalanceStatus.settled
                          ? '—'
                          : formatCurrency(absAmount, ub.currency),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<Member> members;
  const _AvatarStack({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final visible = members.take(3).toList();
    final overflow = members.length - visible.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAF9FE);

    String initials(String n) {
      final t = n.trim();
      if (t.isEmpty) return '?';
      return t.substring(0, 1).toUpperCase();
    }

    final palette = [
      const Color(0xFFFFB4A9),
      const Color(0xFFB6CFE0),
      const Color(0xFFE3C8A8),
      const Color(0xFFC8E0B6),
      const Color(0xFFD8B4F8),
    ];

    return Center(
      child: SizedBox(
        height: 32,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            for (var i = 0; i < visible.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i * 22.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette[i % palette.length],
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials(visible[i].name),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            if (overflow > 0)
              Padding(
                padding: EdgeInsets.only(left: visible.length * 22.0),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9EB),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(color: ringColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$overflow',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E6E73),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Date grouping helper
String _dateLabel(DateTime date, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return l10n.groupDetailToday;
  if (d == today.subtract(const Duration(days: 1))) return l10n.groupDetailYesterday;
  return DateFormat.MMMd().format(date);
}

/// Stitch-style two cards "Du bekommst" / "Du schuldest" side-by-side.
class _StatusCardsRow extends StatelessWidget {
  final double balance;
  final String currency;
  const _StatusCardsRow({required this.balance, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final positive = balance > 0.01 ? balance : 0.0;
    final negative = balance < -0.01 ? balance.abs() : 0.0;
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            label: l10n.groupDetailYouAreOwed,
            amount: positive,
            currency: currency,
            color: AppTheme.positiveColor,
            sign: '+',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusCard(
            label: l10n.groupDetailYouOwe,
            amount: negative,
            currency: currency,
            color: AppTheme.negativeColor,
            sign: '−',
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final String sign;
  const _StatusCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final hasAmount = amount > 0.01;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: hasAmount ? color.withAlpha(45) : Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(160),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAmount ? '$sign${formatCurrency(amount, currency)}' : '—',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: hasAmount ? color : Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerStatefulWidget {
  final Group group;

  const _ExpensesTab({required this.group});

  @override
  ConsumerState<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<_ExpensesTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategory; // null = all categories
  String? _filterPayerId;  // null = all payers
  DateTimeRange? _filterDateRange;
  bool _showSwipeHint = false;
  static const _kSwipeHintShownKey = 'swipe_delete_hint_shown_v1';

  @override
  void initState() {
    super.initState();
    _checkSwipeHint();
  }

  Future<void> _checkSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_kSwipeHintShownKey) ?? false;
    if (!shown && mounted) setState(() => _showSwipeHint = true);
  }

  Future<void> _dismissSwipeHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSwipeHintShownKey, true);
    if (mounted) setState(() => _showSwipeHint = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _applyFilters(
    List<Expense> expenses,
    Map<String, String> memberMap,
  ) {
    var filtered = expenses;

    // Text search (title / description)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((e) => e.description.toLowerCase().contains(q))
          .toList();
    }

    // Category filter
    if (_filterCategory != null) {
      filtered = filtered.where((e) => e.category == _filterCategory).toList();
    }

    // Payer filter
    if (_filterPayerId != null) {
      filtered = filtered.where((e) => e.paidById == _filterPayerId).toList();
    }

    // Date range filter
    if (_filterDateRange != null) {
      final start = _filterDateRange!.start;
      final end = _filterDateRange!.end.add(const Duration(days: 1));
      filtered = filtered
          .where((e) => e.expenseDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
              e.expenseDate.isBefore(end))
          .toList();
    }

    return filtered;
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    List<Member> members,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.paddingL, AppTheme.paddingM, AppTheme.paddingL, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(l10n.groupDetailFilterExpenses,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Category filter
                Text(l10n.groupDetailCategory, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(l10n.groupDetailAll),
                      selected: _filterCategory == null,
                      onSelected: (_) {
                        setSheetState(() {});
                        setState(() => _filterCategory = null);
                      },
                    ),
                    ...expenseCategories.map((cat) => FilterChip(
                          label: Text(cat.label),
                          avatar: Icon(cat.icon, size: 16, color: cat.color),
                          selected: _filterCategory == cat.key,
                          onSelected: (_) {
                            final newVal = _filterCategory == cat.key ? null : cat.key;
                            setSheetState(() {});
                            setState(() => _filterCategory = newVal);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Payer filter
                Text(l10n.groupDetailPaidBy, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: Text(l10n.groupDetailAll),
                      selected: _filterPayerId == null,
                      onSelected: (_) {
                        setSheetState(() {});
                        setState(() => _filterPayerId = null);
                      },
                    ),
                    ...members.map((m) => FilterChip(
                          label: Text(m.name),
                          selected: _filterPayerId == m.id,
                          onSelected: (_) {
                            final newVal = _filterPayerId == m.id ? null : m.id;
                            setSheetState(() {});
                            setState(() => _filterPayerId = newVal);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Date range filter
                Text(l10n.groupDetailDateRange, style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(CupertinoIcons.calendar),
                  label: Text(
                    _filterDateRange == null
                        ? l10n.groupDetailAllTime
                        : l10n.groupDetailDateRangeValue(
                            DateFormat.MMMd().format(_filterDateRange!.start),
                            DateFormat.MMMd().format(_filterDateRange!.end),
                          ),
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _filterDateRange,
                    );
                    if (picked != null) {
                      setSheetState(() {});
                      setState(() => _filterDateRange = picked);
                    }
                  },
                ),
                if (_filterDateRange != null)
                  TextButton(
                    onPressed: () {
                      setSheetState(() {});
                      setState(() => _filterDateRange = null);
                    },
                    child: Text(l10n.groupDetailClearDateFilter),
                  ),
                const SizedBox(height: 8),

                // Reset all
                if (_filterCategory != null || _filterPayerId != null || _filterDateRange != null)
                  FilledButton.tonal(
                    onPressed: () {
                      setSheetState(() {});
                      setState(() {
                        _filterCategory = null;
                        _filterPayerId = null;
                        _filterDateRange = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(l10n.groupDetailResetAllFilters),
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupId = widget.group.id;
    final expensesAsync = ref.watch(expensesProvider(groupId));
    final membersAsync = ref.watch(membersProvider(groupId));

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_text,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100)),
                const SizedBox(height: 16),
                Text(
                  l10n.groupDetailNoExpenses,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                      ),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: () async {
                    await showStitchAddExpenseSheet(context, group: widget.group);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 18),
                      const SizedBox(width: 6),
                      Text(l10n.groupDetailFirstExpense),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Load payers for multi-payer display
        final payersFuture = ref.watch(expensePayersByGroupProvider(groupId));

        return membersAsync.when(
          data: (members) {
            final memberMap = {for (var m in members) m.id: m.name};

            // Build expense -> payer names map
            final payersByExpense = <String, List<String>>{};
            payersFuture.whenData((payers) {
              for (final p in payers) {
                payersByExpense.putIfAbsent(p.expenseId, () => []);
                final name = memberMap[p.memberId] ?? l10n.groupDetailUnknownMember;
                payersByExpense[p.expenseId]!.add(name);
              }
            });

            // Apply search + filters (local, no API call needed)
            final filteredExpenses = _applyFilters(expenses, memberMap);

            final activeFilterCount = [
              _filterCategory,
              _filterPayerId,
              _filterDateRange,
            ].where((f) => f != null).length;

            // Group filtered expenses by date and flatten into a list
            final grouped = <String, List<Expense>>{};
            for (final e in filteredExpenses) {
              final label = _dateLabel(e.expenseDate, l10n);
              grouped.putIfAbsent(label, () => []).add(e);
            }

            // Pre-build flat list: each item is either a header (String) or an Expense
            final flatItems = <Object>[];
            for (final entry in grouped.entries) {
              flatItems.add(entry.key); // header
              flatItems.addAll(entry.value); // expenses
            }

            return Column(
              children: [
                // Search bar + filter button
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, 12, AppTheme.paddingM, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          controller: _searchController,
                          hintText: l10n.groupDetailSearchExpenses,
                          leading: const Icon(CupertinoIcons.search),
                          trailing: _searchQuery.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.clear_circled),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                                ]
                              : null,
                          onChanged: (q) => setState(() => _searchQuery = q),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible: activeFilterCount > 0,
                        label: Text('$activeFilterCount'),
                        child: IconButton.outlined(
                          icon: const Icon(CupertinoIcons.line_horizontal_3_decrease),
                          tooltip: l10n.groupDetailFilter,
                          onPressed: () => _showFilterSheet(context, members),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active filter chips summary
                if (activeFilterCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 4),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.info_circle,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.groupDetailFilteredCount(
                              filteredExpenses.length, expenses.length),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () => setState(() {
                            _filterCategory = null;
                            _filterPayerId = null;
                            _filterDateRange = null;
                          }),
                          child: Text(l10n.groupDetailClear),
                        ),
                      ],
                    ),
                  ),

                // Swipe-to-delete one-time discoverability hint (Issue #73)
                if (_showSwipeHint && filteredExpenses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, 0, AppTheme.paddingM, 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showSwipeHint
                          ? MaterialBanner(
                              key: const ValueKey('swipe_hint'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: AppTheme.paddingS),
                              content: Row(
                                children: [
                                  const Icon(CupertinoIcons.hand_draw,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.groupDetailSwipeHint,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: _dismissSwipeHint,
                                  child: Text(l10n.groupDetailGotIt),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                // Expenses list
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.search,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(100)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.groupDetailNoMatchingExpenses,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(150)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, AppTheme.paddingM),
                          itemCount: flatItems.length,
                          itemBuilder: (context, index) {
                            final item = flatItems[index];
                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, 12, AppTheme.paddingM, 4),
                                child: Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(120),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              );
                            }
                            final expense = item as Expense;
                            final paidByNames = payersByExpense[expense.id];
                            final paidByName =
                                (paidByNames != null && paidByNames.isNotEmpty)
                                    ? paidByNames.join(', ')
                                    : memberMap[expense.paidById] ??
                                        l10n.groupDetailUnknownMember;
                            // Show divider before rows (not before headers or first item)
                            final showDivider = index > 0 && flatItems[index - 1] is Expense;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDivider) const Divider(indent: 72, height: 1),
                                _buildExpenseCard(
                                    context, ref, expense, paidByName, groupId),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => AppErrorHandler.errorWidget(
            e,
            context,
            () => ref.invalidate(membersProvider(groupId)),
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => AppErrorHandler.errorWidget(
        error,
        context,
        () => ref.invalidate(expensesProvider(groupId)),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, // ignore: avoid_unused_parameters
      Expense expense, String paidByName, String groupId, {Group? group}) {
    final l10n = AppLocalizations.of(context);
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(CupertinoIcons.trash_fill, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        bool? confirmed;
        await showCupertinoModalPopup<void>(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: Text(l10n.groupDetailDeleteExpenseTitle),
            message: Text(
                l10n.groupDetailDeleteExpenseMessage(
                    expense.description, expense.amount.toStringAsFixed(2))),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  confirmed = true;
                  Navigator.pop(ctx);
                },
                child: Text(l10n.groupDetailDeleteExpenseTitle),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                confirmed = false;
                Navigator.pop(ctx);
              },
              child: Text(l10n.cancel),
            ),
          ),
        );
        if (confirmed == true) {
          try {
            await ref
                .read(expensesProvider(groupId).notifier)
                .deleteExpense(expense.id);
            await ActivityLogger.instance.logExpenseDeleted(
              groupId: groupId,
              description: expense.description,
              amount: expense.amount,
            );
            ref.invalidate(activityProvider(groupId));
            return true;
          } catch (e) {
            return false;
          }
        }
        return false;
      },
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            sharedAxisRoute(ExpenseDetailScreen(
              expense: expense,
              group: group ?? widget.group,
            )),
          );
        },
        leading: CircleAvatar(
          backgroundColor: getCategoryData(expense.category).color.withAlpha(30),
          child: Icon(
              getCategoryData(expense.category).icon,
              color: getCategoryData(expense.category).color),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.groupDetailPaidByName(paidByName)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(expense.amount, expense.currency),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat.MMMd().format(expense.expenseDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final Group group;
  final String groupId;
  final String currency;

  const _BalancesTab({required this.group, required this.groupId, this.currency = 'USD'});

  /// Find the current user's balance. Matches by userId first, then displayName fallback.
  double? _getUserBalance(
      String displayName, List<dynamic> balances, bool hasMultipleCurrencies,
      List<dynamic> multiCurrencyBalances, String currency) {
    final currentUserId = AuthService.instance.userId;

    // Primary: match by userId
    if (currentUserId != null) {
      if (!hasMultipleCurrencies) {
        for (final mb in balances) {
          if (mb.member.userId == currentUserId) return mb.netBalance;
        }
      } else {
        for (final mcb in multiCurrencyBalances) {
          if (mcb.member.userId == currentUserId) return mcb.amountFor(currency);
        }
      }
    }

    // Fallback: match by displayName
    if (displayName.trim().isEmpty) return null;
    final lowerName = displayName.trim().toLowerCase();
    if (!hasMultipleCurrencies) {
      for (final mb in balances) {
        if (mb.member.name.toLowerCase() == lowerName) return mb.netBalance;
      }
    } else {
      for (final mcb in multiCurrencyBalances) {
        if (mcb.member.name.toLowerCase() == lowerName) return mcb.amountFor(currency);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[PERF] _BalancesTab.build() called for $groupId');
    final l10n = AppLocalizations.of(context);
    // Single watch — all data including settlement records comes from computedData
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));
    final displayName = ref.watch(displayNameProvider);

    return computedAsync.when(
      data: (computed) {
        final balances = computed.balances;
        final multiCurrencyBalances = computed.multiCurrencyBalances;

        // Determine if any expense uses a different currency than the group's default
        // If yes, show multi-currency breakdown; otherwise show the single-currency view.
        final hasMultipleCurrencies = multiCurrencyBalances.any(
          (mcb) => mcb.currencyBalances.length > 1 ||
              (mcb.currencyBalances.isNotEmpty &&
               mcb.currencyBalances.keys.first != currency),
        );

        // Hero: current user's balance (null if name not set or no match)
        final userBalance = _getUserBalance(
            displayName, balances, hasMultipleCurrencies,
            multiCurrencyBalances, currency);

        final hasSettlements = computed.settlements.isNotEmpty;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  0, 0, 0, hasSettlements ? 88 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stitch 2-card status (Du bekommst / Du schuldest)
                  if (userBalance != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, AppTheme.paddingS, AppTheme.paddingM, 12),
                      child: _StatusCardsRow(
                        balance: userBalance,
                        currency: currency,
                      ),
                    ),
                  // ── "WER SCHULDET WEM" section header (Stitch uppercase)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, AppTheme.paddingS, AppTheme.paddingM, AppTheme.paddingS),
                    child: Text(
                      l10n.groupDetailWhoOwesWhom,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(140),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (balances.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
                      child: Text(l10n.groupDetailNoBalances),
                    )
                  else if (hasMultipleCurrencies)
                    // Multi-currency view: plain ListTile + Divider (no Card)
                    ...() {
                      final items = <Widget>[];
                      final list = multiCurrencyBalances;
                      for (var i = 0; i < list.length; i++) {
                        final mcb = list[i];
                        final isSettledUp = mcb.isSettledUp;
                        final hasDebt = mcb.owedCurrencies.isNotEmpty;
                        final color = isSettledUp
                            ? Colors.grey
                            : hasDebt
                                ? AppTheme.negativeColor
                                : AppTheme.positiveColor;

                        final relevantCurrencies = hasDebt
                            ? mcb.owedCurrencies
                            : mcb.owingCurrencies;

                        items.add(ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              sharedAxisRoute(MemberDetailScreen(
                                memberId: mcb.member.id,
                                groupId: groupId,
                                memberName: mcb.member.name,
                              )),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha(40),
                            child: Text(
                              (mcb.member.name.isNotEmpty ? mcb.member.name[0] : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(mcb.member.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSettledUp)
                                Icon(CupertinoIcons.checkmark_circle, size: 16, color: Colors.grey)
                              else ...[
                                Icon(
                                  hasDebt ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                                  size: 16,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: relevantCurrencies.entries.map((e) => Text(
                                    formatCurrency(e.value.abs() / 100, e.key),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  )).toList(),
                                ),
                              ],
                              const SizedBox(width: 4),
                              Icon(CupertinoIcons.chevron_right,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(80)),
                            ],
                          ),
                        ));
                        if (i < list.length - 1) {
                          items.add(const Divider(indent: 56, height: 1));
                        }
                      }
                      return items;
                    }()
                  else
                    // Single-currency view: plain ListTile + Divider (no Card)
                    ...() {
                      final items = <Widget>[];
                      for (var i = 0; i < balances.length; i++) {
                        final mb = balances[i];
                        final isPositive = mb.netBalance >= 0;
                        final color = mb.netBalance.abs() < 0.01
                            ? Colors.grey
                            : isPositive
                                ? AppTheme.positiveColor
                                : AppTheme.negativeColor;
                        final isSettled = mb.netBalance.abs() < 0.01;
                        items.add(ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              sharedAxisRoute(MemberDetailScreen(
                                memberId: mb.member.id,
                                groupId: groupId,
                                memberName: mb.member.name,
                              )),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: color.withAlpha(40),
                            child: Text(
                              (mb.member.name.isNotEmpty ? mb.member.name[0] : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(mb.member.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSettled)
                                Icon(CupertinoIcons.checkmark_circle, size: 16, color: Colors.grey)
                              else
                                Icon(
                                  isPositive ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                                  size: 16,
                                  color: color,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                formatCurrency(mb.netBalance.abs(), currency),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(CupertinoIcons.chevron_right,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(80)),
                            ],
                          ),
                        ));
                        if (i < balances.length - 1) {
                          items.add(const Divider(indent: 56, height: 1));
                        }
                      }
                      return items;
                    }(),
                  // ── Stitch "Schulden vereinfacht" banner ──────────────
                  if (hasSettlements)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.paddingM, AppTheme.paddingL, AppTheme.paddingM, AppTheme.paddingS),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: AppTheme.primaryColor.withAlpha(60),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.sparkles,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.groupDetailDebtsSimplified,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(210),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Settle Up Button — sticky at bottom ──────────────────────
            if (hasSettlements)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.push(
                    context,
                    slideUpRoute(SettleUpScreen(group: group)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: BorderRadius.circular(28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_right_arrow_left, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.groupDetailSettleUp),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorHandler.errorWidget(
        e,
        context,
        () => ref.invalidate(groupComputedDataProvider(groupId)),
      ),
    );
  }

}
