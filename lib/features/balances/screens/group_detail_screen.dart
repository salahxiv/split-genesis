import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/widgets/sync_indicator.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/screens/activity_tab.dart';
import '../../activity/services/activity_logger.dart';
import '../../groups/models/group.dart';
import '../../expenses/models/expense.dart';
import '../../expenses/models/expense_category.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/balances_provider.dart';
import '../../expenses/screens/add_expense_wizard.dart';
import '../../expenses/screens/expense_detail_screen.dart';
import '../../expenses/screens/statistics_screen.dart';
import '../../groups/providers/groups_provider.dart';
import '../../members/screens/manage_members_screen.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../settlements/providers/settlements_provider.dart';
import '../../settlements/models/settlement_record.dart';
// settlementRecordsProvider is still needed for the "Mark as Paid" action

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late String _groupName;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _groupName = widget.group.name;

    // BUG-01 fix: Start realtime subscription here (not in HomeScreen) so
    // that the lifecycle is owned by this widget. Wire the callback so
    // incoming Postgres events actually invalidate Riverpod providers.
    SyncService.instance.listenToGroup(widget.group.id);
    SyncService.instance.onGroupChanged = (groupId) {
      if (!mounted) return;
      ref.invalidate(membersProvider(groupId));
      ref.invalidate(expensesProvider(groupId));
      ref.invalidate(settlementRecordsProvider(groupId));
      ref.invalidate(activityProvider(groupId));
      ref.invalidate(groupComputedDataProvider(groupId));
    };
  }

  @override
  void dispose() {
    // Clear the callback before stopping — avoids calling invalidate on a
    // disposed ProviderContainer after the screen is gone.
    SyncService.instance.onGroupChanged = null;
    SyncService.instance.stopListening(widget.group.id);
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
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
    if (_isFabExpanded) _toggleFab();
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
    if (_isFabExpanded) _toggleFab();
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
    if (_isFabExpanded) _toggleFab();
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

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed dial options — always in tree, animated via SizeTransition
        _SpeedDialItem(
          icon: Icons.person_add,
          label: 'Add Member',
          onTap: _openAddMember,
          animation: _fabAnimationController,
          index: 2,
        ),
        _SpeedDialItem(
          icon: Icons.payment,
          label: 'Record Payment',
          onTap: _openRecordPayment,
          animation: _fabAnimationController,
          index: 1,
        ),
        _SpeedDialItem(
          icon: Icons.receipt_long,
          label: 'Add Expense',
          onTap: _openAddExpense,
          animation: _fabAnimationController,
          index: 0,
        ),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabAnimationController,
          ),
        ),
      ],
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
                    slideRoute(ManageMembersScreen(groupId: widget.group.id)),
                  );
                  break;
                case 'statistics':
                  Navigator.push(
                    context,
                    slideRoute(StatisticsScreen(
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
          _BalancesTab(groupId: groupId, currency: widget.group.currency),
          _ExpensesTab(group: widget.group),
          ActivityTab(groupId: groupId),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
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

class _ExpensesTab extends ConsumerWidget {
  final Group group;

  const _ExpensesTab({required this.group});

  // Categories from expense_category.dart

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = group.id;
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
                        child: AddExpenseWizard(group: group),
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

            // Group expenses by date and flatten into a list for O(1) access
            final grouped = <String, List<Expense>>{};
            for (final e in expenses) {
              final label = _dateLabel(e.expenseDate);
              grouped.putIfAbsent(label, () => []).add(e);
            }

            // Pre-build flat list: each item is either a header (String) or an Expense
            final flatItems = <Object>[];
            for (final entry in grouped.entries) {
              flatItems.add(entry.key); // header
              flatItems.addAll(entry.value); // expenses
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flatItems.length,
              itemBuilder: (context, index) {
                final item = flatItems[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
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
                final expense = item as Expense;
                final paidByNames = payersByExpense[expense.id];
                final paidByName = (paidByNames != null && paidByNames.isNotEmpty)
                    ? paidByNames.join(', ')
                    : memberMap[expense.paidById] ?? 'Unknown';
                return _buildExpenseCard(
                    context, ref, expense, paidByName, groupId);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref,
      Expense expense, String paidByName, String groupId) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Delete "${expense.description}" (\$${expense.amount.toStringAsFixed(2)})?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              slideRoute(ExpenseDetailScreen(
                expense: expense,
                group: group,
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
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final String groupId;
  final String currency;

  const _BalancesTab({required this.groupId, this.currency = 'USD'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[PERF] _BalancesTab.build() called for $groupId');
    // Single watch — all data including settlement records comes from computedData
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));

    return computedAsync.when(
      data: (computed) {
        final balances = computed.balances;
        final totalSpend = computed.totalSpend;
        final memberMap = computed.memberMap;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total group spend banner
              if (totalSpend > 0)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Total group spend: ${formatCurrency(totalSpend, currency)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                'Member Balances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (balances.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No balances to show'),
                  ),
                )
              else
                ...balances.map((mb) {
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          slideRoute(MemberDetailScreen(
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
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Text(
                'Suggested Settlements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (computed.settlements.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('All settled up!'),
                  ),
                )
              else
                ...computed.settlements.map((s) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: const Icon(Icons.arrow_forward,
                          color: AppTheme.negativeColor),
                      title: Text(
                        '${s.fromMember.name} pays ${s.toMember.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(formatCurrency(s.amount, currency),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.negativeColor,
                          )),
                      trailing: SizedBox(
                        width: 90,
                        height: 36,
                        child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Mark as Paid'),
                              content: Text(
                                  '${s.fromMember.name} paid ${formatCurrency(s.amount, currency)} to ${s.toMember.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref
                                .read(settlementRecordsProvider(groupId)
                                    .notifier)
                                .addSettlement(
                                  fromMemberId: s.fromMember.id,
                                  toMemberId: s.toMember.id,
                                  amount: s.amount,
                                  fromMemberName: s.fromMember.name,
                                  toMemberName: s.toMember.name,
                                );
                            ref.invalidate(groupComputedDataProvider(groupId));
                            await ActivityLogger.instance.logSettlementRecorded(
                              groupId: groupId,
                              fromName: s.fromMember.name,
                              toName: s.toMember.name,
                              amount: s.amount,
                            );
                            ref.invalidate(activityProvider(groupId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Payment recorded: ${s.fromMember.name} → ${s.toMember.name}'),
                                ),
                              );
                            }
                          }
                        },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Paid'),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

}

class _SpeedDialItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AnimationController animation;
  final int index;

  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;
    final interval = Interval(delay, 0.5 + delay, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: animation.drive(CurveTween(curve: interval)),
      axisAlignment: 1.0,
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: interval)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'speedDial_$label',
                onPressed: onTap,
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
