import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../activity/services/activity_logger.dart';
import '../../balances/models/balance.dart';
import '../../balances/providers/balances_provider.dart';
import '../../activity/providers/activity_provider.dart';
import '../../groups/models/group.dart';
import '../providers/settlements_provider.dart';

/// Dedicated Settle Up screen — shows all pending debts and lets members
/// mark individual debts as settled with a confirmation step.
class SettleUpScreen extends ConsumerStatefulWidget {
  final Group group;

  const SettleUpScreen({super.key, required this.group});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  /// Tracks which settlement suggestions are being processed (to show loading)
  final Set<String> _processingKeys = {};

  String _settlementKey(Settlement s) =>
      '${s.fromMember.id}_${s.toMember.id}_${s.amountCents}';

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group.id;
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        centerTitle: false,
      ),
      body: computedAsync.when(
        data: (computed) {
          final settlements = computed.settlements;

          if (settlements.isEmpty) {
            return _buildAllSettledView(context);
          }

          // Build a flat list of items for virtualized rendering.
          // Layout: [header, settleAllBtn?, sectionTitle, ...settlementCards]
          // Using ListView.builder ensures O(1) rendering even for large lists.
          final hasSettleAll = settlements.length > 1;
          // Fixed header items: header card + optional settle-all btn + section title
          const headerCount = 1; // header card (always)
          final settleAllCount = hasSettleAll ? 1 : 0;
          const sectionTitleCount = 1;
          final leadingCount = headerCount + settleAllCount + sectionTitleCount;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leadingCount + settlements.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header card
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHeaderCard(context, settlements),
                );
              }
              if (hasSettleAll && index == 1) {
                // Settle All button
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: () => _settleAll(context, ref, settlements),
                    icon: const Icon(Icons.done_all),
                    label: Text('Settle All (${settlements.length} debts)'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                );
              }
              if (index == leadingCount - 1) {
                // Section title "Pending Debts"
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pending Debts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              }
              // Settlement card
              final s = settlements[index - leadingCount];
              final key = _settlementKey(s);
              final isProcessing = _processingKeys.contains(key);
              return _SettlementCard(
                settlement: s,
                currency: widget.group.currency,
                isProcessing: isProcessing,
                onMarkSettled: () => _markAsSettled(context, ref, s, key),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading balances: $e'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllSettledView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'All settled up! 🎉',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No outstanding debts in "${widget.group.name}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, List<Settlement> settlements) {
    final totalCents = settlements.fold<int>(0, (sum, s) => sum + s.amountCents);
    final total = formatCurrency(totalCents / 100, widget.group.currency);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${settlements.length} debt${settlements.length == 1 ? '' : 's'} pending',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Total: $total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withAlpha(180),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _settleAll(
    BuildContext context,
    WidgetRef ref,
    List<Settlement> settlements,
  ) async {
    bool? confirmed;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Settle All'),
        message: Text(
          'Mark all ${settlements.length} debts as settled? This will update the group balances.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              confirmed = true;
              Navigator.pop(ctx);
            },
            child: Text('Confirm — Settle ${settlements.length} debts'),
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

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final groupId = widget.group.id;

    try {
      final notifier = ref.read(settlementRecordsProvider(groupId).notifier);
      await Future.wait(
        settlements.map((s) => notifier.addSettlement(
              fromMemberId: s.fromMember.id,
              toMemberId: s.toMember.id,
              amount: s.amount,
              fromMemberName: s.fromMember.name,
              toMemberName: s.toMember.name,
            )),
      );

      ref.invalidate(groupComputedDataProvider(groupId));

      await Future.wait(
        settlements.map((s) => ActivityLogger.instance.logSettlementRecorded(
              groupId: groupId,
              fromName: s.fromMember.name,
              toName: s.toMember.name,
              amount: s.amount,
            )),
      );
      ref.invalidate(activityProvider(groupId));

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('All ${settlements.length} debts settled ✅'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppErrorHandler.getMessage(e))),
        );
      }
    }
  }

  Future<void> _markAsSettled(
    BuildContext context,
    WidgetRef ref,
    Settlement s,
    String key,
  ) async {
    // Capture messenger before any async gap
    final messenger = ScaffoldMessenger.of(context);

    // Confirmation action sheet
    bool? confirmed;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Mark as Settled'),
        message: Text(
          '${s.fromMember.name} paid ${formatCurrency(s.amount, widget.group.currency)} to ${s.toMember.name}.\nThis will update the group balances.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              confirmed = true;
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Payment'),
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

    if (confirmed != true || !mounted) return;

    setState(() => _processingKeys.add(key));

    try {
      final groupId = widget.group.id;

      // 1. Create settlement record in DB + Supabase
      await ref.read(settlementRecordsProvider(groupId).notifier).addSettlement(
            fromMemberId: s.fromMember.id,
            toMemberId: s.toMember.id,
            amount: s.amount,
            fromMemberName: s.fromMember.name,
            toMemberName: s.toMember.name,
          );

      // 2. Invalidate balances so UI recalculates
      ref.invalidate(groupComputedDataProvider(groupId));

      // 3. Log to activity feed
      await ActivityLogger.instance.logSettlementRecorded(
        groupId: groupId,
        fromName: s.fromMember.name,
        toName: s.toMember.name,
        amount: s.amount,
      );
      ref.invalidate(activityProvider(groupId));

      // 4. Send ntfy.sh notification to group members
      final amountStr = formatCurrency(s.amount, widget.group.currency);
      await NotificationService.instance.showDebtSettled(
        groupName: widget.group.name,
        settledByName: s.fromMember.name,
        amount: s.amount,
        owedToName: s.toMember.name,
        groupUuid: groupId,
      );

      // In-App Review: trigger after successful Settle-Up (Issue #50)
      // ReviewService handles threshold (3 settle-ups) and 90-day cooldown.
      unawaited(ReviewService.instance.onSettleUpCompleted());

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.fromMember.name} settled $amountStr with ${s.toMember.name} ✅',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppErrorHandler.getMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingKeys.remove(key));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settlement Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final String currency;
  final bool isProcessing;
  final VoidCallback onMarkSettled;

  const _SettlementCard({
    required this.settlement,
    required this.currency,
    required this.isProcessing,
    required this.onMarkSettled,
  });

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    final theme = Theme.of(context);
    final amountStr = formatCurrency(s.amount, currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From → To row
            Row(
              children: [
                // From avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.errorContainer,
                  child: Text(
                    s.fromMember.name.isNotEmpty
                        ? s.fromMember.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fromMember.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'owes',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
                const SizedBox(width: 8),
                // To avatar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        s.toMember.name.isNotEmpty
                            ? s.toMember.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.toMember.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Amount + Action row
            Row(
              children: [
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                    ),
                    Text(
                      amountStr,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                    ),
                  ],
                ),

                const Spacer(),

                // Mark as Settled button
                isProcessing
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.icon(
                        onPressed: onMarkSettled,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark as Settled'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
