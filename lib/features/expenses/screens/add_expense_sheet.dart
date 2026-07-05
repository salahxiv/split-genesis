import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../groups/models/group.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../widgets/amount_numpad.dart';

/// Stitch "Add Expense" — single-screen modal bottom sheet.
///
/// Visual reference: stitch.googleapis.com project "Split iOS Expense Tracker",
/// screen "Add Expense (Light)".
Future<void> showStitchAddExpenseSheet(
  BuildContext context, {
  required Group group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StitchAddExpenseSheet(group: group),
  );
}

class StitchAddExpenseSheet extends ConsumerStatefulWidget {
  final Group group;
  const StitchAddExpenseSheet({super.key, required this.group});

  @override
  ConsumerState<StitchAddExpenseSheet> createState() =>
      _StitchAddExpenseSheetState();
}

class _StitchAddExpenseSheetState extends ConsumerState<StitchAddExpenseSheet> {
  final _descriptionController = TextEditingController();
  double _amount = 0.0;
  String? _payerId;
  final Set<String> _splitIds = {};
  String _category = 'food';
  DateTime _date = DateTime.now();
  bool _recurring = false;
  bool _detailsExpanded = true;
  bool _saving = false;
  bool _initialized = false;

  // Compact 4-icon row (Stitch shows: Essen / Einkauf / Reise / Mehr).
  static const _stitchPrimary = ['food', 'groceries', 'travel'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _initDefaults(List<Member> members) {
    if (_initialized || members.isEmpty) return;
    _initialized = true;
    final userId = AuthService.instance.userId;
    Member? me;
    if (userId != null) {
      for (final m in members) {
        if (m.userId == userId) {
          me = m;
          break;
        }
      }
    }
    setState(() {
      _payerId = (me ?? members.first).id;
      _splitIds.addAll(members.map((m) => m.id));
    });
  }

  Future<void> _openNumpad() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (_) {
        double localAmount = _amount;
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountNumpad(
                    initialAmount: localAmount,
                    onAmountChanged: (a) {
                      localAmount = a;
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(28),
                      onPressed: () {
                        setState(() => _amount = localAmount);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Übernehmen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPayer(List<Member> members) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Bezahlt von',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            for (final m in members)
              ListTile(
                title: Text(m.name),
                trailing: m.id == _payerId
                    ? const Icon(CupertinoIcons.check_mark,
                        color: AppTheme.primaryColor)
                    : null,
                onTap: () => Navigator.pop(ctx, m.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _payerId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) {
        DateTime tmp = _date;
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Abbrechen'),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx, tmp),
                      child: const Text('Übernehmen'),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _date,
                    maximumDate: DateTime.now().add(const Duration(days: 1)),
                    onDateTimeChanged: (d) => tmp = d,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(List<Member> members) async {
    if (_saving) return;
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib eine Beschreibung ein')),
      );
      return;
    }
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Betrag ein')),
      );
      return;
    }
    if (_payerId == null) return;
    if (_splitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle mindestens eine Person')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(expensesProvider(widget.group.id).notifier)
          .addExpense(
            description: desc,
            amount: _amount,
            paidByIds: [_payerId!],
            splitAmongIds: _splitIds.toList(),
            category: _category,
            currency: widget.group.currency,
            expenseDate: _date,
            isRecurring: _recurring,
            recurrenceInterval: _recurring ? 'monthly' : null,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.darkSurface : AppTheme.surfaceColor;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final secondary =
        isDark ? AppTheme.iosSecondaryLabel : const Color(0xFF6E6E73);
    final dividerColor =
        isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final membersAsync = ref.watch(membersProvider(widget.group.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: membersAsync.when(
            data: (members) {
              _initDefaults(members);
              return _buildBody(
                members: members,
                cardBg: cardBg,
                secondary: secondary,
                dividerColor: dividerColor,
                scrollController: scrollController,
              );
            },
            loading: () =>
                const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle,
                        size: 36, color: AppTheme.negativeColor),
                    const SizedBox(height: 12),
                    Text(
                      'Fehler beim Laden: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondary),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(20),
                      onPressed: () => ref.invalidate(membersProvider(widget.group.id)),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required List<Member> members,
    required Color cardBg,
    required Color secondary,
    required Color dividerColor,
    required ScrollController scrollController,
  }) {
    final payer = members.where((m) => m.id == _payerId).firstOrNull;
    final perPerson = _splitIds.isNotEmpty ? _amount / _splitIds.length : 0.0;

    return Column(
      children: [
        // ── Drag handle + top bar
        Container(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7CC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.chevron_left,
                    color: AppTheme.primaryColor),
              ),
              const Spacer(),
              const Text(
                'Split',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const SizedBox(width: 36),
            ],
          ),
        ),

        // ── Body
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Big amount + Wofür
              GestureDetector(
                onTap: _openNumpad,
                child: Center(
                  child: Text(
                    formatCurrency(_amount, widget.group.currency),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: _amount > 0
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withAlpha(110),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _descriptionController,
                placeholder: 'Wofür?',
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.sentences,
                decoration: const BoxDecoration(),
                style: TextStyle(fontSize: 16, color: secondary),
                placeholderStyle: TextStyle(fontSize: 16, color: secondary),
              ),
              const SizedBox(height: 18),

              // ── Card: Bezahlt von + Split pills
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickPayer(members),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            const Text(
                              'Bezahlt von',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              payer?.name ?? '—',
                              style: TextStyle(fontSize: 15, color: secondary),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              CupertinoIcons.chevron_forward,
                              size: 14,
                              color: secondary.withAlpha(180),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: dividerColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Split',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: members.map((m) {
                              final selected = _splitIds.contains(m.id);
                              return _MemberPill(
                                name: m.name,
                                amount: selected ? perPerson : 0.0,
                                currency: widget.group.currency,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _splitIds.remove(m.id);
                                    } else {
                                      _splitIds.add(m.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Mehr Details Header
              GestureDetector(
                onTap: () =>
                    setState(() => _detailsExpanded = !_detailsExpanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mehr Details',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _detailsExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (_detailsExpanded) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KATEGORIE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: secondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CategoryRow(
                        keys: _stitchPrimary,
                        selected: _category,
                        onSelect: (k) => setState(() => _category = k),
                        onMore: () async {
                          final picked = await showModalBottomSheet<String>(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 4,
                                padding: const EdgeInsets.all(12),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: expenseCategories
                                    .map((c) => GestureDetector(
                                          onTap: () => Navigator.pop(ctx, c.key),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor:
                                                    c.color.withAlpha(40),
                                                child: Icon(c.icon,
                                                    color: c.color, size: 22),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(c.label,
                                                  style: const TextStyle(
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _category = picked);
                          }
                        },
                      ),
                      Divider(
                          height: 22,
                          thickness: 0.5,
                          color: dividerColor),
                      // Datum
                      GestureDetector(
                        onTap: _pickDate,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.calendar,
                                  size: 18, color: secondary),
                              const SizedBox(width: 10),
                              Text(
                                _dateLabel(_date),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const Spacer(),
                              Icon(
                                CupertinoIcons.chevron_forward,
                                size: 14,
                                color: secondary.withAlpha(180),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 0.5, thickness: 0.5, color: dividerColor),
                      // Wiederkehrend
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.refresh,
                                size: 18, color: secondary),
                            const SizedBox(width: 10),
                            const Text(
                              'Wiederkehrend',
                              style: TextStyle(fontSize: 15),
                            ),
                            const Spacer(),
                            Switch.adaptive(
                              value: _recurring,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (v) => setState(() => _recurring = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── Speichern + Split anpassen
              SizedBox(
                width: double.infinity,
                height: 52,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(28),
                  padding: EdgeInsets.zero,
                  onPressed: _saving ? null : () => _save(members),
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Split anpassen: in Kürze verfügbar'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Split anpassen →',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dn = DateTime(d.year, d.month, d.day);
    if (dn == today) return 'Heute';
    if (dn == today.subtract(const Duration(days: 1))) return 'Gestern';
    return DateFormat('d. MMM yyyy', 'de_DE').format(d);
  }
}

class _MemberPill extends StatelessWidget {
  final String name;
  final double amount;
  final String currency;
  final bool selected;
  final VoidCallback onTap;
  const _MemberPill({
    required this.name,
    required this.amount,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = AppTheme.primaryColor.withAlpha(30);
    final inactiveBg =
        isDark ? AppTheme.darkCardHigher : const Color(0xFFF2F2F7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withAlpha(120)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: const Color(0xFFE0E0E5),
              child: Text(
                getInitial(name),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              formatCurrency(amount, currency),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<String> keys;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onMore;
  const _CategoryRow({
    required this.keys,
    required this.selected,
    required this.onSelect,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg =
        isDark ? AppTheme.darkCardHigher : const Color(0xFFF2F2F7);

    Widget cat(String key) {
      final c = getCategoryData(key);
      final isSel = selected == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(key),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryColor.withAlpha(35) : inactiveBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(c.icon,
                    color: isSel ? AppTheme.primaryColor : c.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                _germanLabel(key),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AppTheme.primaryColor : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        for (final k in keys) cat(k),
        Expanded(
          child: GestureDetector(
            onTap: onMore,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: inactiveBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.ellipsis,
                      color: Color(0xFF6E6E73), size: 24),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mehr',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _germanLabel(String key) {
    switch (key) {
      case 'food':
        return 'Essen';
      case 'groceries':
        return 'Einkauf';
      case 'travel':
        return 'Reise';
      case 'transport':
        return 'Transport';
      case 'accommodation':
        return 'Unterkunft';
      case 'shopping':
        return 'Shopping';
      case 'entertainment':
        return 'Spaß';
      case 'utilities':
        return 'Nebenkosten';
      case 'drinks':
        return 'Drinks';
      case 'health':
        return 'Gesundheit';
      case 'gifts':
        return 'Geschenke';
      case 'subscriptions':
        return 'Abos';
      case 'sports':
        return 'Sport';
      default:
        return 'Allgemein';
    }
  }
}
