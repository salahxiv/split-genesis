import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final groupId = widget.group.id;
    final computedAsync = ref.watch(groupComputedDataProvider(groupId));

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        backgroundColor: context.iosGroupedBackground,
        title: Text(l10n.settleUpTitle),
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
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: leadingCount + settlements.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  child: _buildHeaderCard(context, settlements),
                );
              }
              if (hasSettleAll && index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
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
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
                  child: Text(
                    l10n.settleUpOutstandingDebts,
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
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.exclamationmark_circle,
                    size: 48,
                    color: CupertinoColors.systemRed.resolveFrom(context)),
                const SizedBox(height: 12),
                Text(l10n.settleUpLoadError(e.toString()),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () => ref.invalidate(groupComputedDataProvider(groupId)),
                  child: Text(l10n.settleUpTryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllSettledView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.checkmark_circle,
              size: 80,
              color: CupertinoColors.systemGreen.resolveFrom(context)),
          const SizedBox(height: 16),
          Text(
            l10n.settleUpAllSettledTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settleUpNoDebtsIn(widget.group.name),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.iosSecondaryLabel,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settleUpBackToGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, List<Settlement> settlements) {
    final l10n = AppLocalizations.of(context);
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
        padding: const EdgeInsets.all(AppTheme.paddingM),
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
                    l10n.settleUpOpenCount(settlements.length),
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  Text(
                    l10n.settleUpTotal(total),
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
    final l10n = AppLocalizations.of(context);
    bool? confirmed;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settleUpSettleAllTitle),
        message: Text(
          l10n.settleUpSettleAllMessage(settlements.length),
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              confirmed = true;
              Navigator.pop(ctx);
            },
            child:
                Text(l10n.settleUpSettleAllAction(settlements.length)),
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

    if (confirmed != true || !context.mounted) return;

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

      if (context.mounted) {
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
    final l10n = AppLocalizations.of(context);
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
                        ? l10n.settleUpPartialPaidSnack(
                            s.fromMember.name, amountStr, s.toMember.name)
                        : l10n.settleUpSettledSnack(
                            s.fromMember.name, amountStr, s.toMember.name),
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
    final l10n = AppLocalizations.of(context);
    final s = settlement;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amountStr = formatCurrency(s.amount, currency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingM),
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
                    getInitial(s.fromMember.name),
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
                        l10n.settleUpOwes,
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
                        getInitial(s.toMember.name),
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
                  ? AppTheme.darkSeparator
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
                      l10n.settleUpAmount,
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
                            horizontal: AppTheme.paddingM, vertical: AppTheme.paddingS),
                        onPressed: onMarkSettled,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.checkmark,
                                size: 16),
                            const SizedBox(width: 6),
                            Text(l10n.settleUpTitle),
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

/// Validation error variants for the partial-payment amount field.
enum _AmountError { notPositive, exceedsMax }

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
  _AmountError? _amountError;

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
        _amountError = null; // just disable button
      } else if (value <= 0) {
        _amountError = _AmountError.notPositive;
      } else if (value > widget.settlement.amount + 0.01) {
        _amountError = _AmountError.exceedsMax;
      } else {
        _amountError = null;
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
    final l10n = AppLocalizations.of(context);
    final s = widget.settlement;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fullAmountStr = formatCurrency(s.amount, widget.currency);
    final canConfirm = _parsedAmount != null && _amountError == null;
    final errorText = switch (_amountError) {
      _AmountError.notPositive => l10n.settleUpAmountMustBePositive,
      _AmountError.exceedsMax => l10n.settleUpCannotExceed(fullAmountStr),
      null => null,
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppTheme.paddingL, AppTheme.paddingM, AppTheme.paddingL, MediaQuery.of(context).viewPadding.bottom + 24),
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

          // Title (Stitch: bold, large)
          Text(
            l10n.settleUpTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settleUpOwesTo(s.fromMember.name, s.toMember.name),
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 18),

          // ── Big Avatar → Avatar (Stitch-style)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BigAvatar(name: s.fromMember.name, color: const Color(0xFFFFB4A9)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  CupertinoIcons.arrow_right,
                  size: 22,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              _BigAvatar(name: s.toMember.name, color: const Color(0xFFB6CFE0)),
            ],
          ),
          const SizedBox(height: 22),

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
              padding: const EdgeInsets.only(left: AppTheme.paddingM),
              child: Text(
                '\$',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingM, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkCardHigher
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(13),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),

          // "of $X total" label or error
          if (errorText != null)
            Text(
              errorText,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            )
          else
            Text(
              l10n.settleUpOfTotal(fullAmountStr),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          const SizedBox(height: 16),

          // ── Stitch slider for amount selection
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withAlpha(40),
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: ((_parsedAmount ?? widget.settlement.amount)
                      .clamp(0.0, widget.settlement.amount))
                  .toDouble(),
              min: 0,
              max: widget.settlement.amount,
              onChanged: (v) {
                final rounded = (v * 100).round() / 100;
                _amountController.text = rounded.toStringAsFixed(2);
                _amountController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _amountController.text.length),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatCurrency(0, widget.currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () {
                  _amountController.text =
                      widget.settlement.amount.toStringAsFixed(2);
                },
                child: Text(
                  l10n.settleUpSettleFull,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                fullAmountStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Bankverbindung-Row (Placeholder)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardHigher : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(13),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.creditcard,
                  size: 18,
                  color: theme.colorScheme.onSurface.withAlpha(170),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settleUpPaymentMethod,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        l10n.settleUpBankTransfer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.settleUpBankTransferComingSoon),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    l10n.settleUpChange,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(28),
              onPressed: canConfirm
                  ? () => widget.onConfirm(_parsedAmount!)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.checkmark_alt_circle, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isPartial
                        ? l10n.settleUpConfirmPaymentAmount(
                            formatCurrency(
                                _parsedAmount ?? 0, widget.currency))
                        : l10n.settleUpConfirmPayment,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.settleUpMarkedImmediately,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Cancel
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: widget.onCancel,
              child: Text(
                l10n.cancel,
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

/// Stitch-style large circular avatar with a single initial on a pastel bg.
class _BigAvatar extends StatelessWidget {
  final String name;
  final Color color;
  const _BigAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = getInitial(name);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}
