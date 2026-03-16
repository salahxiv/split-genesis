import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_extensions.dart';
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
/// mark individual debts as settled (full or partial) with a confirmation step.
class SettleUpScreen extends ConsumerStatefulWidget {
  final Group group;

  const SettleUpScreen({super.key, required this.group});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  final Set<String> _processingKeys = {};

  String _settlementKey(Settlement s) =>
      '${s.fromMember.id}_${s.toMember.id}_${s.amountCents}';

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group.id;
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        backgroundColor: context.iosGroupedBackground,
        title: const Text('Settle Up'),
        centerTitle: false,
      ),
      body: computedAsync.when(
        data: (computed) {
          final settlements = computed.settlements;

          if (settlements.isEmpty) {
            return _buildAllSettledView(context);
          }

          final hasSettleAll = settlements.length > 1;
          const headerCount = 1;
          final settleAllCount = hasSettleAll ? 1 : 0;
          const sectionTitleCount = 1;
          final leadingCount = headerCount + settleAllCount + sectionTitleCount;

          return ListView.builder(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(16),
            itemCount: leadingCount + settlements.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHeaderCard(context, settlements),
                );
              }
              if (hasSettleAll && index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () =>
                          _settleAll(context, ref, settlements),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(CupertinoIcons.checkmark_alt, size: 18),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (index == leadingCount - 1) {
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
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48,
                  color: CupertinoColors.systemRed.resolveFrom(context)),
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
          Icon(CupertinoIcons.checkmark_circle,
              size: 80,
              color: CupertinoColors.systemGreen.resolveFrom(context)),
          const SizedBox(height: 16),
          Text(
            'All settled up!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No outstanding debts in "${widget.group.name}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.iosSecondaryLabel,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, List<Settlement> settlements) {
    final totalCents =
        settlements.fold<int>(0, (sum, s) => sum + s.amountCents);
    final total =
        formatCurrency(totalCents / 100, widget.group.currency);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.creditcard,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${settlements.length} debt${settlements.length == 1 ? '' : 's'} pending',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  Text(
                    'Total: $total',
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
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
            child:
                Text('Confirm \u2014 Settle ${settlements.length} debts'),
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
      final notifier =
          ref.read(settlementRecordsProvider(groupId).notifier);
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
        settlements.map(
            (s) => ActivityLogger.instance.logSettlementRecorded(
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
              children: const [
                Icon(CupertinoIcons.checkmark_circle,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
              ],
            ),
            backgroundColor: CupertinoColors.systemGreen.color,
            duration: const Duration(seconds: 2),
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

  /// Shows a partial-payment bottom sheet and settles the chosen amount.
  Future<void> _markAsSettled(
    BuildContext context,
    WidgetRef ref,
    Settlement s,
    String key,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show partial payment sheet
    double? confirmedAmount;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _PartialPaymentSheet(
        settlement: s,
        currency: widget.group.currency,
        onConfirm: (amount) {
          confirmedAmount = amount;
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    if (confirmedAmount == null || !mounted) return;

    setState(() => _processingKeys.add(key));

    try {
      final groupId = widget.group.id;
      final settledAmount = confirmedAmount!;

      await ref
          .read(settlementRecordsProvider(groupId).notifier)
          .addSettlement(
            fromMemberId: s.fromMember.id,
            toMemberId: s.toMember.id,
            amount: settledAmount,
            fromMemberName: s.fromMember.name,
            toMemberName: s.toMember.name,
          );

      ref.invalidate(groupComputedDataProvider(groupId));

      await ActivityLogger.instance.logSettlementRecorded(
        groupId: groupId,
        fromName: s.fromMember.name,
        toName: s.toMember.name,
        amount: settledAmount,
      );
      ref.invalidate(activityProvider(groupId));

      final amountStr =
          formatCurrency(settledAmount, widget.group.currency);
      await NotificationService.instance.showDebtSettled(
        groupName: widget.group.name,
        settledByName: s.fromMember.name,
        amount: settledAmount,
        owedToName: s.toMember.name,
        groupUuid: groupId,
      );

      unawaited(ReviewService.instance.onSettleUpCompleted());

      if (mounted) {
        final isPartial = (settledAmount - s.amount).abs() > 0.01;
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_circle,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPartial
                        ? '${s.fromMember.name} paid $amountStr (partial) to ${s.toMember.name}'
                        : '${s.fromMember.name} settled $amountStr with ${s.toMember.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: CupertinoColors.systemGreen.color,
            duration: const Duration(seconds: 2),
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

// -----------------------------------------------------------------------
// Settlement Card Widget
// -----------------------------------------------------------------------

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
    final isDark = theme.brightness == Brightness.dark;
    final amountStr = formatCurrency(s.amount, currency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From -> To row
            Row(
              children: [
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
                              color: theme.colorScheme.onSurface
                                  .withAlpha(150),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.arrow_right,
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Text(
                        s.toMember.name.isNotEmpty
                            ? s.toMember.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color:
                              theme.colorScheme.onPrimaryContainer,
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
            Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
            ),
            const SizedBox(height: 12),

            // Amount + Action row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(150),
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
                isProcessing
                    ? const CupertinoActivityIndicator()
                    : CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        onPressed: onMarkSettled,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.checkmark,
                                size: 16),
                            SizedBox(width: 6),
                            Text('Settle'),
                          ],
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Partial Payment Bottom Sheet
// -----------------------------------------------------------------------

class _PartialPaymentSheet extends StatefulWidget {
  final Settlement settlement;
  final String currency;
  final void Function(double amount) onConfirm;
  final VoidCallback onCancel;

  const _PartialPaymentSheet({
    required this.settlement,
    required this.currency,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_PartialPaymentSheet> createState() => _PartialPaymentSheetState();
}

class _PartialPaymentSheetState extends State<_PartialPaymentSheet> {
  late final TextEditingController _amountController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.settlement.amount.toStringAsFixed(2),
    );
    _amountController.addListener(_validate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _amountController.text.trim();
    final value = double.tryParse(text);
    setState(() {
      if (text.isEmpty || value == null) {
        _errorText = null; // just disable button
      } else if (value <= 0) {
        _errorText = 'Amount must be greater than 0';
      } else if (value > widget.settlement.amount + 0.01) {
        _errorText =
            'Cannot exceed ${formatCurrency(widget.settlement.amount, widget.currency)}';
      } else {
        _errorText = null;
      }
    });
  }

  double? get _parsedAmount {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) return null;
    if (value > widget.settlement.amount + 0.01) return null;
    return value;
  }

  bool get _isPartial {
    final v = _parsedAmount;
    if (v == null) return false;
    return (v - widget.settlement.amount).abs() > 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settlement;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullAmountStr = formatCurrency(s.amount, widget.currency);
    final canConfirm = _parsedAmount != null && _errorText == null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Settle Payment',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // From -> To
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.errorContainer,
                child: Text(
                  s.fromMember.name.isNotEmpty
                      ? s.fromMember.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.fromMember.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  CupertinoIcons.arrow_right,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
              Text(
                s.toMember.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  s.toMember.name.isNotEmpty
                      ? s.toMember.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount input
          CupertinoTextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            placeholder: '0.00',
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '\$',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(13),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),

          // "of $X total" label or error
          if (_errorText != null)
            Text(
              _errorText!,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            )
          else
            Text(
              'of $fullAmountStr total debt',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: canConfirm
                  ? () => widget.onConfirm(_parsedAmount!)
                  : null,
              child: Text(
                _isPartial
                    ? 'Settle ${formatCurrency(_parsedAmount ?? 0, widget.currency)} (partial)'
                    : 'Settle Full Amount',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: widget.onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
