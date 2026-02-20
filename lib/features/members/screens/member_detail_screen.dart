import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../expenses/models/expense_category.dart';
import '../../balances/providers/balances_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../settlements/providers/settlements_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  final String groupId;
  final String memberName;

  const MemberDetailScreen({
    super.key,
    required this.memberId,
    required this.groupId,
    required this.memberName,
  });

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5856D6),
      Color(0xFFFF9500),
      Color(0xFFFF2D55),
      Color(0xFF34C759),
      Color(0xFF007AFF),
      Color(0xFFAF52DE),
      Color(0xFFFF6B35),
      Color(0xFF30B0C7),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final expensesAsync = ref.watch(expensesProvider(groupId));
    final payersAsync = ref.watch(expensePayersByGroupProvider(groupId));
    final settlementsAsync = ref.watch(settlementRecordsProvider(groupId));
    final splitsAsync = ref.watch(watchedSplitsByGroupProvider(groupId));

    final isLoading = expensesAsync.isLoading ||
        payersAsync.isLoading ||
        settlementsAsync.isLoading ||
        splitsAsync.isLoading;

    final hasError = expensesAsync.hasError ||
        payersAsync.hasError ||
        settlementsAsync.hasError ||
        splitsAsync.hasError;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(memberName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(memberName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load member details',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final allExpenses = expensesAsync.value ?? [];
    final allPayers = payersAsync.value ?? [];
    final allSettlements = settlementsAsync.value ?? [];
    final allSplits = splitsAsync.value ?? [];

    // Expenses this member paid (at least partially)
    final memberPayerEntries =
        allPayers.where((p) => p.memberId == memberId).toList();
    final paidExpenseIds =
        memberPayerEntries.map((p) => p.expenseId).toSet();
    final expensesPaid =
        allExpenses.where((e) => paidExpenseIds.contains(e.id)).toList();

    // Splits this member is involved in
    final memberSplits =
        allSplits.where((s) => s.memberId == memberId).toList();
    final splitExpenseIds =
        memberSplits.map((s) => s.expenseId).toSet();

    // All expenses this member is involved in (paid or split)
    final involvedExpenseIds =
        {...paidExpenseIds, ...splitExpenseIds};
    final expensesInvolved =
        allExpenses.where((e) => involvedExpenseIds.contains(e.id)).toList();

    // Settlements involving this member
    final memberSettlements = allSettlements
        .where((s) =>
            s.fromMemberId == memberId || s.toMemberId == memberId)
        .toList();

    // Balance calculation
    double totalPaid = 0.0;
    for (final payer in memberPayerEntries) {
      totalPaid += payer.amount;
    }

    double totalOwes = 0.0;
    for (final split in memberSplits) {
      totalOwes += split.amount;
    }

    // Also factor in settlements
    double settlementAdjustment = 0.0;
    for (final s in memberSettlements) {
      if (s.fromMemberId == memberId) {
        settlementAdjustment -= s.amount;
      } else if (s.toMemberId == memberId) {
        settlementAdjustment += s.amount;
      }
    }

    final netBalance = totalPaid - totalOwes + settlementAdjustment;

    final avatarColor = _avatarColor(memberName);
    final initial =
        memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: isDark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFF2F2F7),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(
                initial: initial,
                memberName: memberName,
                avatarColor: avatarColor,
                netBalance: netBalance,
                isDark: isDark,
                theme: theme,
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _StatsRow(
                expensesPaidCount: expensesPaid.length,
                expensesInvolvedCount: expensesInvolved.length,
                settlementsCount: memberSettlements.length,
                isDark: isDark,
                theme: theme,
              ),
            ),
          ),

          // Transaction history header
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Transaction History',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Combined transaction list
          if (expensesInvolved.isEmpty && memberSettlements.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _TransactionList(
              expenses: expensesInvolved,
              settlements: memberSettlements,
              memberId: memberId,
              memberPayers: memberPayerEntries,
              memberSplits: memberSplits,
              allPayers: allPayers,
              isDark: isDark,
              theme: theme,
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initial;
  final String memberName;
  final Color avatarColor;
  final double netBalance;
  final bool isDark;
  final ThemeData theme;

  const _ProfileHeader({
    required this.initial,
    required this.memberName,
    required this.avatarColor,
    required this.netBalance,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = netBalance > 0
        ? AppTheme.positiveColor
        : netBalance < 0
            ? AppTheme.negativeColor
            : theme.colorScheme.onSurfaceVariant;

    final balanceLabel = netBalance > 0
        ? 'gets back'
        : netBalance < 0
            ? 'owes'
            : 'settled up';

    final balanceAmount = netBalance.abs();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Member name
          Text(
            memberName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Balance
          if (netBalance == 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Settled up',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  memberName.split(' ').first,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  balanceLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${balanceAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: balanceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int expensesPaidCount;
  final int expensesInvolvedCount;
  final int settlementsCount;
  final bool isDark;
  final ThemeData theme;

  const _StatsRow({
    required this.expensesPaidCount,
    required this.expensesInvolvedCount,
    required this.settlementsCount,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatCell(
            value: expensesPaidCount.toString(),
            label: 'Paid for',
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF007AFF),
            theme: theme,
            isFirst: true,
          ),
          _VerticalDivider(isDark: isDark),
          _StatCell(
            value: expensesInvolvedCount.toString(),
            label: 'Involved in',
            icon: Icons.receipt_outlined,
            iconColor: const Color(0xFFFF9500),
            theme: theme,
          ),
          _VerticalDivider(isDark: isDark),
          _StatCell(
            value: settlementsCount.toString(),
            label: 'Settlements',
            icon: Icons.handshake_outlined,
            iconColor: AppTheme.positiveColor,
            theme: theme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final bool isDark;

  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final ThemeData theme;
  final bool isFirst;
  final bool isLast;

  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.theme,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List expenses;
  final List settlements;
  final String memberId;
  final List memberPayers;
  final List memberSplits;
  final List allPayers;
  final bool isDark;
  final ThemeData theme;

  const _TransactionList({
    required this.expenses,
    required this.settlements,
    required this.memberId,
    required this.memberPayers,
    required this.memberSplits,
    required this.allPayers,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Build combined list of items sorted by date desc
    final items = <_TransactionItem>[];

    for (final expense in expenses) {
      final paidAmount = memberPayers
          .where((p) => p.expenseId == expense.id)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      final splitAmount = memberSplits
          .where((s) => s.expenseId == expense.id)
          .fold<double>(0.0, (sum, s) => sum + s.amount);

      final isPayer = paidAmount > 0;

      items.add(_TransactionItem(
        id: expense.id,
        date: expense.expenseDate ?? expense.createdAt,
        isExpense: true,
        title: expense.description,
        subtitle: isPayer
            ? 'You paid \$${paidAmount.toStringAsFixed(2)}'
            : 'Your share \$${splitAmount.toStringAsFixed(2)}',
        amount: isPayer ? paidAmount : -splitAmount,
        category: expense.category,
        currency: expense.currency ?? 'USD',
        isPayer: isPayer,
      ));
    }

    for (final settlement in settlements) {
      final isReceiver = settlement.toMemberId == memberId;
      final otherName = isReceiver
          ? settlement.fromMemberName
          : settlement.toMemberName;

      items.add(_TransactionItem(
        id: settlement.id,
        date: settlement.createdAt,
        isExpense: false,
        title: isReceiver
            ? 'Payment from $otherName'
            : 'Payment to $otherName',
        subtitle: isReceiver ? 'Received' : 'Sent',
        amount: isReceiver ? settlement.amount : -settlement.amount,
        category: null,
        currency: 'USD',
        isPayer: isReceiver,
      ));
    }

    // Sort by date descending
    items.sort((a, b) {
      final dateA = a.date is DateTime ? a.date as DateTime : DateTime.tryParse(a.date.toString()) ?? DateTime(0);
      final dateB = b.date is DateTime ? b.date as DateTime : DateTime.tryParse(b.date.toString()) ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, index == 0 ? 0 : 0, 16, isLast ? 0 : 0),
            child: _TransactionTile(
              item: item,
              isFirst: index == 0,
              isLast: isLast,
              isDark: isDark,
              theme: theme,
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }
}

class _TransactionItem {
  final String id;
  final dynamic date;
  final bool isExpense;
  final String title;
  final String subtitle;
  final double amount;
  final String? category;
  final String currency;
  final bool isPayer;

  const _TransactionItem({
    required this.id,
    required this.date,
    required this.isExpense,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.category,
    required this.currency,
    required this.isPayer,
  });
}

class _TransactionTile extends StatelessWidget {
  final _TransactionItem item;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final ThemeData theme;

  const _TransactionTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    DateTime? parsedDate;
    if (item.date is DateTime) {
      parsedDate = item.date as DateTime;
    } else if (item.date is String) {
      parsedDate = DateTime.tryParse(item.date as String);
    }

    final dateStr = parsedDate != null
        ? DateFormat('MMM d, yyyy').format(parsedDate)
        : '';

    final amountColor = item.amount > 0
        ? AppTheme.positiveColor
        : item.amount < 0
            ? AppTheme.negativeColor
            : colorScheme.onSurfaceVariant;

    final amountStr = item.amount >= 0
        ? '+\$${item.amount.toStringAsFixed(2)}'
        : '-\$${item.amount.abs().toStringAsFixed(2)}';

    Widget leadingIcon;
    if (item.isExpense && item.category != null) {
      final catData = getCategoryData(item.category!);
      leadingIcon = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: catData.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          catData.icon,
          color: catData.color,
          size: 20,
        ),
      );
    } else {
      leadingIcon = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.positiveColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.swap_horiz_rounded,
          color: AppTheme.positiveColor,
          size: 22,
        ),
      );
    }

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: radius,
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (!isFirst)
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                leadingIcon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr.isNotEmpty
                            ? '${item.subtitle} · $dateStr'
                            : item.subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amountStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
