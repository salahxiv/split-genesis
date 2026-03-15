import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _buildHeaderCard(context, settlements),
              const SizedBox(height: 16),

              Text(
                'Pending Debts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              ...settlements.map((s) {
                final key = _settlementKey(s);
                final isProcessing = _processingKeys.contains(key);
                return _SettlementCard(
                  settlement: s,
                  currency: widget.group.currency,
                  isProcessing: isProcessing,
                  onMarkSettled: () => _markAsSettled(context, ref, s, key),
                );
              }),
            ],
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

  Future<void> _markAsSettled(
    BuildContext context,
    WidgetRef ref,
    Settlement s,
    String key,
  ) async {
    // Capture messenger before any async gap
    final messenger = ScaffoldMessenger.of(context);

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
        title: const Text('Mark as Settled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(ctx).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: s.fromMember.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' paid '),
                  TextSpan(
                    text: formatCurrency(s.amount, widget.group.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text: s.toMember.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will update the group balances.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(150),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Confirm'),
          ),
        ],
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
          SnackBar(content: Text('Error: $e')),
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
