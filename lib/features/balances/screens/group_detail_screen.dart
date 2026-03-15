import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
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
import '../../expenses/screens/add_expense_wizard.dart';
import '../../expenses/screens/expense_detail_screen.dart';
import '../../expenses/screens/statistics_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/screens/manage_members_screen.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../settlements/providers/settlements_provider.dart';
import '../../settlements/screens/settle_up_screen.dart';
import '../../settings/providers/settings_provider.dart';
// settlementRecordsProvider is still needed for the "Mark as Paid" action

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _groupName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _groupName = widget.group.name;

    // BUG-01 fix: Start realtime subscription here (not in HomeScreen) so
    // that the lifecycle is owned by this widget. Wire the granular callback so
    // incoming Postgres events invalidate only the relevant Riverpod provider.
    // Only 'expenses' and 'settlements' emit Realtime events.
    // members/groups/activity_log are loaded once on screen-open (no Realtime).
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _renameGroup() async {
    final controller = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
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
        subject: '$_groupName – Expenses Export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
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
        subject: '$_groupName – Export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  void _showShareSheet() {
    final code = widget.group.shareCode;
    final shareText = 'Join my group "$_groupName" on Split Genesis!\n'
        'Tap: splitgenesis://join/$code\n'
        'Or enter code: $code';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewPadding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invite to "$_groupName"',
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Invite Code',
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
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
              ),
            ),
            const SizedBox(height: 8),
            // Share button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Share.share(shareText);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddExpense() async {
    try {
      final container = ProviderScope.containerOf(context);
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ProviderScope(
          parent: container,
          child: AddExpenseWizard(group: widget.group),
        ),
      );
      if (result == 'added' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense added'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final expenses = ref.read(expensesProvider(widget.group.id));
                expenses.whenData((list) {
                  if (list.isNotEmpty) {
                    ref
                        .read(expensesProvider(widget.group.id).notifier)
                        .deleteExpense(list.first.id);
                  }
                });
              },
            ),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[DEBUG] FAB ERROR: $e');
      debugPrint('[DEBUG] FAB STACK: $stack');
    }
  }

  Future<void> _openRecordPayment() async {
    final members = ref.read(membersProvider(widget.group.id)).valueOrNull ?? [];
    if (members.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 2 members to record a payment')),
        );
      }
      return;
    }

    String? fromId;
    String? toId;
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'From'),
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                value: fromId,
                onChanged: (v) => setDialogState(() => fromId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'To'),
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                    .toList(),
                value: toId,
                onChanged: (v) => setDialogState(() => toId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Record'),
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
            fromMemberName: memberMap[fromId!] ?? 'Unknown',
            toMemberName: memberMap[toId!] ?? 'Unknown',
          );
          ref.invalidate(groupComputedDataProvider(widget.group.id));
          await ActivityLogger.instance.logSettlementRecorded(
            groupId: widget.group.id,
            fromName: memberMap[fromId!] ?? 'Unknown',
            toName: memberMap[toId!] ?? 'Unknown',
            amount: amount,
          );
          ref.invalidate(activityProvider(widget.group.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment recorded')),
            );
          }
        } catch (e, stack) {
          debugPrint('[ERROR] Record payment failed: $e');
          debugPrint('[ERROR] Stack: $stack');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error recording payment: $e')),
            );
          }
        }
      }
    }
    amountController.dispose();
  }

  Future<void> _openAddMember() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g., Alice',
            prefixIcon: Icon(Icons.person_add),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(membersProvider(widget.group.id).notifier).addMember(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added to group')),
        );
      }
    }
    controller.dispose();
  }

  // Simple FAB — single tap for Add Expense
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _openAddExpense,
      tooltip: 'Add Expense',
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[PERF] GroupDetailScreen.build() called for "${widget.group.name}"');
    final groupId = widget.group.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName),
        actions: [
          const SyncIndicator(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share group',
            onPressed: () => _showShareSheet(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'members':
                  Navigator.push(
                    context,
                    slideUpRoute(ManageMembersScreen(groupId: widget.group.id)),
                  );
                  break;
                case 'statistics':
                  Navigator.push(
                    context,
                    slideUpRoute(StatisticsScreen(
                      groupId: widget.group.id,
                      groupName: _groupName,
                    )),
                  );
                  break;
                case 'rename':
                  _renameGroup();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Statistics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Rename'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.balance), text: 'Balances'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
            Tab(icon: Icon(Icons.history), text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BalancesTab(group: widget.group, groupId: groupId, currency: widget.group.currency),
          _ExpensesTab(group: widget.group),
          ActivityTab(groupId: groupId),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}

// Date grouping helper
String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return 'Today';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat.MMMd().format(date);
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
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Filter Expenses',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Category filter
                Text('Category', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('All'),
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
                Text('Paid by', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('All'),
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
                Text('Date range', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _filterDateRange == null
                        ? 'All time'
                        : '${DateFormat.MMMd().format(_filterDateRange!.start)} — ${DateFormat.MMMd().format(_filterDateRange!.end)}',
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
                    child: const Text('Clear date filter'),
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
                    child: const Text('Reset all filters'),
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
                Icon(Icons.receipt_long,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(100)),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor:
                          Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => ProviderScope(
                        parent: ProviderScope.containerOf(context),
                        child: AddExpenseWizard(group: widget.group),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add first expense'),
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
                final name = memberMap[p.memberId] ?? 'Unknown';
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
              final label = _dateLabel(e.expenseDate);
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          controller: _searchController,
                          hintText: 'Search expenses…',
                          leading: const Icon(Icons.search),
                          trailing: _searchQuery.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.clear),
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
                          icon: const Icon(Icons.filter_list),
                          tooltip: 'Filter',
                          onPressed: () => _showFilterSheet(context, members),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active filter chips summary
                if (activeFilterCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredExpenses.length} of ${expenses.length} expenses',
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
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),

                // Swipe-to-delete one-time discoverability hint (Issue #73)
                if (_showSwipeHint && filteredExpenses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showSwipeHint
                          ? MaterialBanner(
                              key: const ValueKey('swipe_hint'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              content: const Row(
                                children: [
                                  Icon(Icons.swipe_left_outlined,
                                      size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Swipe left on an expense to delete it',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: _dismissSwipeHint,
                                  child: const Text('Got it'),
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
                              Icon(Icons.search_off,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(100)),
                              const SizedBox(height: 12),
                              Text(
                                'No matching expenses',
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
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                          itemCount: flatItems.length,
                          itemBuilder: (context, index) {
                            final item = flatItems[index];
                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                                    : memberMap[expense.paidById] ?? 'Unknown';
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorHandler.errorWidget(e),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppErrorHandler.errorWidget(error),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, // ignore: avoid_unused_parameters
      Expense expense, String paidByName, String groupId, {Group? group}) {
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
            title: const Text('Delete Expense'),
            message: Text(
                '"${expense.description}" (${expense.amount.toStringAsFixed(2)}) will be permanently deleted.'),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Delete Expense'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                confirmed = false;
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
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
        subtitle: Text('Paid by $paidByName'),
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

  /// Find the current user's balance based on display name match.
  /// Returns null if no match found.
  double? _getUserBalance(
      String displayName, List<dynamic> balances, bool hasMultipleCurrencies,
      List<dynamic> multiCurrencyBalances, String currency) {
    if (displayName.trim().isEmpty) return null;

    final lowerName = displayName.trim().toLowerCase();

    if (!hasMultipleCurrencies) {
      // Single-currency path
      for (final mb in balances) {
        if (mb.member.name.toLowerCase() == lowerName) {
          return mb.netBalance;
        }
      }
    } else {
      // Multi-currency path: use primary currency balance
      for (final mcb in multiCurrencyBalances) {
        if (mcb.member.name.toLowerCase() == lowerName) {
          return mcb.amountFor(currency);
        }
      }
    }
    return null;
  }

  String _getUserBalanceText(double? userBalance, String currency) {
    if (userBalance == null) return '';
    final abs = userBalance.abs();
    final formatted = formatCurrency(abs, currency);
    if (userBalance > 0.01) return 'You are owed $formatted';
    if (userBalance < -0.01) return 'You owe $formatted';
    return 'All settled up ✓';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[PERF] _BalancesTab.build() called for $groupId');
    // Single watch — all data including settlement records comes from computedData
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));
    final displayName = ref.watch(displayNameProvider);

    return computedAsync.when(
      data: (computed) {
        final balances = computed.balances;
        final multiCurrencyBalances = computed.multiCurrencyBalances;
        final totalSpend = computed.totalSpend;

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
        final showHeader = (userBalance != null) || (totalSpend > 0);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  0, 0, 0, hasSettlements ? 88 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Merged Header: Your Balance + Total Spend ─────────
                  if (showHeader)
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      padding: const EdgeInsets.all(16),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            if (userBalance != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Balance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getUserBalanceText(userBalance, currency),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: userBalance > 0.01
                                                ? AppTheme.positiveColor
                                                : userBalance < -0.01
                                                    ? AppTheme.negativeColor
                                                    : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (userBalance != null && totalSpend > 0)
                              const VerticalDivider(width: 32),
                            if (totalSpend > 0)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: userBalance != null
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spend',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatCurrency(totalSpend, currency),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // ──────────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Member Balances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (balances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('No balances to show'),
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

                        String buildMultiCurrencyLabel(Map<String, int> cMap, String verb) {
                          if (cMap.isEmpty) return '';
                          final parts = cMap.entries
                              .map((e) => formatCurrency(e.value.abs() / 100, e.key))
                              .toList();
                          return '$verb ${parts.join(' + ')}';
                        }

                        final trailingLabel = isSettledUp
                            ? 'settled up'
                            : hasDebt
                                ? buildMultiCurrencyLabel(mcb.owedCurrencies, 'owes')
                                : buildMultiCurrencyLabel(mcb.owingCurrencies, 'gets back');

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
                              Flexible(
                                child: Text(
                                  trailingLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
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
                        final label = mb.netBalance.abs() < 0.01
                            ? 'settled up'
                            : isPositive
                                ? 'gets back'
                                : 'owes';
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
                              Text(
                                '$label ${formatCurrency(mb.netBalance.abs(), currency)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right,
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
                ],
              ),
            ),
            // ── Settle Up Button — sticky at bottom ──────────────────────
            if (hasSettlements)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    slideUpRoute(SettleUpScreen(group: group)),
                  ),
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Settle Up'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorHandler.errorWidget(e),
    );
  }

}


