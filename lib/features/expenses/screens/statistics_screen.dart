import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../../members/providers/members_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const StatisticsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  // 0 = "Dieser Monat", 1 = "Alles"
  int _filterIndex = 1;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider(widget.groupId));
    final payersAsync = ref.watch(expensePayersByGroupProvider(widget.groupId));
    final membersAsync = ref.watch(membersProvider(widget.groupId));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        backgroundColor: context.iosGroupedBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              widget.groupName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Zeit-Filter: CupertinoSlidingSegmentedControl
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _filterIndex,
              onValueChanged: (int? value) {
                if (value != null) setState(() => _filterIndex = value);
              },
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Dieser Monat'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Alles'),
                ),
              },
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error loading statistics',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                ),
              ),
              data: (allExpenses) {
                // Apply time filter
                final now = DateTime.now();
                final expenses = _filterIndex == 0
                    ? allExpenses.where((e) =>
                        e.expenseDate.year == now.year &&
                        e.expenseDate.month == now.month).toList()
                    : allExpenses;

                return payersAsync.when(
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading payer data',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                    ),
                  ),
                  data: (payers) {
                    return membersAsync.when(
                      loading: () => const Center(child: CupertinoActivityIndicator()),
                      error: (err, _) => Center(
                        child: Text(
                          'Error loading member data',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                        ),
                      ),
                      data: (members) {
                        // Empty state
                        if (expenses.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.chart_bar,
                                  size: 80,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(60),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Noch keine Ausgaben',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(120),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final totalSpend = expenses.fold<double>(
                          0.0,
                          (sum, e) => sum + e.amount,
                        );

                        // Category breakdown
                        final Map<String, double> categoryTotals = {};
                        for (final expense in expenses) {
                          final key = expense.category;
                          categoryTotals[key] = (categoryTotals[key] ?? 0.0) + expense.amount;
                        }
                        final sortedCategories = categoryTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                        // Monthly breakdown (last 6 months)
                        final Map<String, double> monthlyTotals = {};
                        for (var i = 5; i >= 0; i--) {
                          final month = DateTime(now.year, now.month - i, 1);
                          final key = DateFormat('MMM yyyy').format(month);
                          monthlyTotals[key] = 0.0;
                        }
                        for (final expense in expenses) {
                          final date = expense.expenseDate;
                          final key = DateFormat('MMM yyyy').format(date);
                          if (monthlyTotals.containsKey(key)) {
                            monthlyTotals[key] = (monthlyTotals[key] ?? 0.0) + expense.amount;
                          }
                        }

                        // Per-member breakdown using payers
                        final expenseIds = expenses.map((e) => e.id).toSet();
                        final filteredPayers = _filterIndex == 0
                            ? payers.where((p) => expenseIds.contains(p.expenseId)).toList()
                            : payers;

                        final Map<String, double> memberTotals = {};
                        for (final payer in filteredPayers) {
                          memberTotals[payer.memberId] =
                              (memberTotals[payer.memberId] ?? 0.0) + payer.amount;
                        }

                        final currencySymbol = expenses.isNotEmpty
                            ? _getCurrencySymbol(expenses.first.currency)
                            : '\$';

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: [
                            // Total Spend Card
                            _TotalSpendCard(
                              totalSpend: totalSpend,
                              expenseCount: expenses.length,
                              currencySymbol: currencySymbol,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),

                            // Category Breakdown
                            if (sortedCategories.isNotEmpty) ...[
                              _CategoryBreakdownCard(
                                categoryTotals: sortedCategories,
                                totalSpend: totalSpend,
                                currencySymbol: currencySymbol,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Monthly Spending
                            _MonthlySpendingCard(
                              monthlyTotals: monthlyTotals,
                              currencySymbol: currencySymbol,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),

                            // Per-Member Breakdown
                            if (memberTotals.isNotEmpty) ...[
                              _MemberBreakdownCard(
                                memberTotals: memberTotals,
                                members: members,
                                currencySymbol: currencySymbol,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      default:
        return '\$';
    }
  }
}

// ---------------------------------------------------------------------------
// Total Spend Card
// ---------------------------------------------------------------------------

class _TotalSpendCard extends StatelessWidget {
  final double totalSpend;
  final int expenseCount;
  final String currencySymbol;
  final bool isDark;

  const _TotalSpendCard({
    required this.totalSpend,
    required this.expenseCount,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    ).format(totalSpend);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(191),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Total Group Spend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatted,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'} recorded',
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Breakdown Card
// ---------------------------------------------------------------------------

class _CategoryBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> categoryTotals;
  final double totalSpend;
  final String currencySymbol;
  final bool isDark;

  const _CategoryBreakdownCard({
    required this.categoryTotals,
    required this.totalSpend,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = categoryTotals.isNotEmpty ? categoryTotals.first.value : 1.0;

    return _StatCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: CupertinoIcons.chart_pie,
            title: 'By Category',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          ...categoryTotals.take(8).map((entry) {
            final categoryData = getCategoryData(entry.key);
            final percent = totalSpend > 0 ? (entry.value / totalSpend * 100) : 0.0;
            final barFraction = maxValue > 0 ? entry.value / maxValue : 0.0;
            final formatted = NumberFormat.currency(
              symbol: currencySymbol,
              decimalDigits: 2,
            ).format(entry.value);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _HorizontalBar(
                icon: categoryData.icon,
                label: categoryData.label,
                value: formatted,
                percent: percent,
                barFraction: barFraction,
                color: categoryData.color,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly Spending Card
// ---------------------------------------------------------------------------

class _MonthlySpendingCard extends StatefulWidget {
  final Map<String, double> monthlyTotals;
  final String currencySymbol;
  final bool isDark;

  const _MonthlySpendingCard({
    required this.monthlyTotals,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  State<_MonthlySpendingCard> createState() => _MonthlySpendingCardState();
}

class _MonthlySpendingCardState extends State<_MonthlySpendingCard>
    with SingleTickerProviderStateMixin {
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animated = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.monthlyTotals.entries.toList();
    final maxValue = entries.fold<double>(
      0.0,
      (max, e) => e.value > max ? e.value : max,
    );

    return _StatCard(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: CupertinoIcons.chart_bar,
            title: 'Monthly Spending',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final fraction = maxValue > 0 ? entry.value / maxValue : 0.0;
                final shortLabel = entry.key.split(' ').first;
                final isCurrentMonth = entry.key ==
                    DateFormat('MMM yyyy').format(DateTime.now());

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _formatCompact(entry.value, widget.currencySymbol),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isCurrentMonth
                                    ? AppTheme.primaryColor
                                    : (widget.isDark
                                        ? Colors.white54
                                        : Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: _animated ? (fraction * 110).clamp(2.0, 110.0) : 2.0,
                          decoration: BoxDecoration(
                            color: isCurrentMonth
                                ? AppTheme.primaryColor
                                : (widget.isDark
                                    ? Colors.white24
                                    : AppTheme.primaryColor.withAlpha(64)),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.w400,
                            color: isCurrentMonth
                                ? AppTheme.primaryColor
                                : (widget.isDark
                                    ? Colors.white54
                                    : Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value, String symbol) {
    if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }
}

// ---------------------------------------------------------------------------
// Member Breakdown Card
// ---------------------------------------------------------------------------

class _MemberBreakdownCard extends StatelessWidget {
  final Map<String, double> memberTotals;
  final List<dynamic> members;
  final String currencySymbol;
  final bool isDark;

  const _MemberBreakdownCard({
    required this.memberTotals,
    required this.members,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalPaid = memberTotals.values.fold<double>(0.0, (sum, v) => sum + v);
    final maxValue = memberTotals.values.fold<double>(
      0.0,
      (max, v) => v > max ? v : max,
    );

    final sortedMembers = memberTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final memberMap = {for (final m in members) m.id as String: m.name as String};

    final avatarColors = [
      const Color(0xFF5E81F4),
      const Color(0xFF56C2A6),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB347),
      const Color(0xFFAA86F5),
      const Color(0xFF4FC3F7),
    ];

    return _StatCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: CupertinoIcons.person_2,
            title: 'Per Member Paid',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          ...sortedMembers.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final name = memberMap[entry.key] ?? 'Unknown';
            final percent = totalPaid > 0 ? (entry.value / totalPaid * 100) : 0.0;
            final barFraction = maxValue > 0 ? entry.value / maxValue : 0.0;
            final color = avatarColors[index % avatarColors.length];
            final formatted = NumberFormat.currency(
              symbol: currencySymbol,
              decimalDigits: 2,
            ).format(entry.value);
            final initials = _initials(name);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(46),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '$formatted  (${percent.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _AnimatedBar(
                          fraction: barFraction,
                          color: color,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _StatCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(31),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double percent;
  final double barFraction;
  final Color color;
  final bool isDark;

  const _HorizontalBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.percent,
    required this.barFraction,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '$value  (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _AnimatedBar(
          fraction: barFraction,
          color: color,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final double fraction;
  final Color color;
  final bool isDark;

  const _AnimatedBar({
    required this.fraction,
    required this.color,
    required this.isDark,
  });

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = (_started ? widget.fraction * maxWidth : 0.0).clamp(0.0, maxWidth);

        return Stack(
          children: [
            Container(
              height: 7,
              width: maxWidth,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white12 : Colors.black.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              height: 7,
              width: targetWidth,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}
