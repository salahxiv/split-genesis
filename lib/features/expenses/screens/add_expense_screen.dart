import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_logger.dart';
import '../../groups/models/group.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../widgets/amount_numpad.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Group group;
  final Expense? expense;

  const AddExpenseScreen({super.key, required this.group, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  double _numpadAmount = 0;
  String? _selectedPayerId;
  final Set<String> _selectedSplitMemberIds = {};
  bool _membersInitialized = false;
  String _selectedCategory = 'general';
  String _splitType = 'equal';
  final Map<String, TextEditingController> _splitControllers = {};
  bool _moreOptionsExpanded = false;

  bool get _isEditing => widget.expense != null;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.expense!;
      _descriptionController.text = e.description;
      _numpadAmount = e.amount;
      _selectedPayerId = e.paidById;
      _selectedCategory = e.category;
      _splitType = e.splitType;
      // If editing with non-default settings, expand more options
      if (e.splitType != 'equal' || e.category != 'general') {
        _moreOptionsExpanded = true;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String memberId) {
    return _splitControllers.putIfAbsent(
        memberId, () => TextEditingController());
  }

  Future<void> _initSplitsForEdit() async {
    if (_isEditing && !_membersInitialized) {
      final splits = await ref
          .read(expenseRepositoryProvider)
          .getSplitsByExpense(widget.expense!.id);
      if (mounted) {
        setState(() {
          _selectedSplitMemberIds.addAll(splits.map((s) => s.memberId));
          if (_splitType != 'equal') {
            for (final s in splits) {
              _getController(s.memberId).text =
                  _splitType == 'percent'
                      ? ((s.amount / widget.expense!.amount) * 100)
                          .toStringAsFixed(1)
                      : s.amount.toStringAsFixed(2);
            }
          }
          _membersInitialized = true;
        });
      }
    }
  }

  Map<String, double>? _calculateCustomSplits(double amount) {
    if (_splitType == 'equal') return null;

    final splits = <String, double>{};

    if (_splitType == 'exact') {
      double total = 0;
      for (final id in _selectedSplitMemberIds) {
        final val = double.tryParse(_getController(id).text) ?? 0;
        splits[id] = val;
        total += val;
      }
      if ((total - amount).abs() > 0.01) return null;
    } else if (_splitType == 'percent') {
      double totalPercent = 0;
      for (final id in _selectedSplitMemberIds) {
        final pct = double.tryParse(_getController(id).text) ?? 0;
        splits[id] = amount * pct / 100;
        totalPercent += pct;
      }
      if ((totalPercent - 100).abs() > 0.1) return null;
    } else if (_splitType == 'shares') {
      double totalShares = 0;
      final shareValues = <String, double>{};
      for (final id in _selectedSplitMemberIds) {
        final share = double.tryParse(_getController(id).text) ?? 0;
        shareValues[id] = share;
        totalShares += share;
      }
      if (totalShares <= 0) return null;
      for (final id in _selectedSplitMemberIds) {
        splits[id] = amount * (shareValues[id]! / totalShares);
      }
    }

    return splits;
  }

  Future<void> _saveExpense() async {
    if (_saving) return;
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final amount = _numpadAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedPayerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid')),
      );
      return;
    }

    if (_selectedSplitMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who to split with')),
      );
      return;
    }

    Map<String, double>? customSplits;
    if (_splitType != 'equal') {
      customSplits = _calculateCustomSplits(amount);
      if (customSplits == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_splitType == 'exact'
                ? 'Individual amounts must add up to \$${amount.toStringAsFixed(2)}'
                : _splitType == 'percent'
                    ? 'Percentages must add up to 100%'
                    : 'Please enter valid share values'),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(expensesProvider(widget.group.id).notifier);
      if (_isEditing) {
        await notifier.updateExpense(
          expenseId: widget.expense!.id,
          description: description,
          amount: amount,
          paidByIds: [_selectedPayerId!],
          splitAmongIds: _selectedSplitMemberIds.toList(),
          category: _selectedCategory,
          splitType: _splitType,
          customSplits: customSplits,
          originalCreatedAt: widget.expense!.createdAt,
          expenseDate: widget.expense!.expenseDate,
        );
        NotificationService.instance.showExpenseUpdated(
          groupName: widget.group.name,
          description: description,
        );
        await ActivityLogger.instance.logExpenseUpdated(
          groupId: widget.group.id,
          description: description,
          amount: amount,
        );
      } else {
        await notifier.addExpense(
          description: description,
          amount: amount,
          paidByIds: [_selectedPayerId!],
          splitAmongIds: _selectedSplitMemberIds.toList(),
          category: _selectedCategory,
          splitType: _splitType,
          customSplits: customSplits,
        );
      }
      ref.invalidate(activityProvider(widget.group.id));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSplitInputs(List<Member> members) {
    if (_splitType == 'equal') {
      final amount = _numpadAmount;
      final perPerson = _selectedSplitMemberIds.isNotEmpty
          ? amount / _selectedSplitMemberIds.length
          : 0.0;
      if (_selectedSplitMemberIds.isNotEmpty && _numpadAmount > 0) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '\$${perPerson.toStringAsFixed(2)} per person '
              '(${_selectedSplitMemberIds.length} people)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final selectedMembers =
        members.where((m) => _selectedSplitMemberIds.contains(m.id)).toList();
    if (selectedMembers.isEmpty) return const SizedBox.shrink();

    final amount = _numpadAmount;
    String suffix;
    String hint;
    switch (_splitType) {
      case 'percent':
        suffix = '%';
        hint = '0';
        break;
      case 'exact':
        suffix = '';
        hint = '0.00';
        break;
      case 'shares':
        suffix = 'x';
        hint = '1';
        break;
      default:
        suffix = '';
        hint = '0';
    }

    double total = 0;
    for (final m in selectedMembers) {
      total += double.tryParse(_getController(m.id).text) ?? 0;
    }

    String? validationText;
    Color? validationColor;
    if (_splitType == 'exact') {
      final diff = amount - total;
      if (diff.abs() > 0.01) {
        validationText = '\$${diff.abs().toStringAsFixed(2)} ${diff > 0 ? 'remaining' : 'over'}';
        validationColor = AppTheme.negativeColor;
      } else {
        validationText = 'Amounts match';
        validationColor = AppTheme.positiveColor;
      }
    } else if (_splitType == 'percent') {
      final diff = 100 - total;
      if (diff.abs() > 0.1) {
        validationText = '${diff.abs().toStringAsFixed(1)}% ${diff > 0 ? 'remaining' : 'over'}';
        validationColor = AppTheme.negativeColor;
      } else {
        validationText = 'Percentages match (100%)';
        validationColor = AppTheme.positiveColor;
      }
    } else if (_splitType == 'shares' && total > 0) {
      validationText = 'Total shares: ${total.toStringAsFixed(0)}';
      validationColor = Theme.of(context).colorScheme.onSurface;
    }

    return Column(
      children: [
        ...selectedMembers.map((member) {
          final controller = _getController(member.id);
          String? memberAmount;
          if (_splitType == 'percent') {
            final pct = double.tryParse(controller.text) ?? 0;
            memberAmount = '\$${(amount * pct / 100).toStringAsFixed(2)}';
          } else if (_splitType == 'shares' && total > 0) {
            final share = double.tryParse(controller.text) ?? 0;
            memberAmount = '\$${(amount * share / total).toStringAsFixed(2)}';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(member.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: hint,
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(suffix,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150))),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (memberAmount != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(memberAmount,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right),
                  ),
                ],
              ],
            ),
          );
        }),
        if (validationText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(validationText,
                style: TextStyle(
                    color: validationColor, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildMoreOptions(List<Member> members) {
    final cat = expenseCategories.firstWhere(
      (c) => c.key == _selectedCategory,
      orElse: () => expenseCategories.first,
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _moreOptionsExpanded,
        onExpansionChanged: (v) => setState(() => _moreOptionsExpanded = v),
        title: Row(
          children: [
            Icon(cat.icon, size: 16, color: cat.color),
            const SizedBox(width: 6),
            Text(
              'More options',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          // Category
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Category',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: expenseCategories.length,
            itemBuilder: (context, index) {
              final category = expenseCategories[index];
              final isSelected = _selectedCategory == category.key;
              return Semantics(
                label: category.label,
                hint: isSelected ? 'Selected category' : 'Tap to select category',
                selected: isSelected,
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color.withAlpha(30)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? category.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon, size: 22, color: category.color),
                        const SizedBox(height: 4),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? category.color
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Split type
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Split type',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _splitType,
              onValueChanged: (String? value) {
                if (value != null) setState(() => _splitType = value);
              },
              children: const {
                'equal': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Equal'),
                ),
                'exact': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Exact'),
                ),
                'percent': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('%'),
                ),
                'shares': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Shares'),
                ),
              },
            ),
          ),
          const SizedBox(height: 16),
          // Split among
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Split among',
                  style: Theme.of(context).textTheme.titleSmall),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSplitMemberIds.length == members.length) {
                      _selectedSplitMemberIds.clear();
                    } else {
                      _selectedSplitMemberIds.clear();
                      _selectedSplitMemberIds
                          .addAll(members.map((m) => m.id));
                    }
                  });
                },
                child: Text(
                  _selectedSplitMemberIds.length == members.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((member) {
              final isSelected = _selectedSplitMemberIds.contains(member.id);
              return FilterChip(
                label: Text(member.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSplitMemberIds.add(member.id);
                    } else {
                      _selectedSplitMemberIds.remove(member.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildSplitInputs(members),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider(widget.group.id));

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: membersAsync.when(
        data: (members) {
          if (!_membersInitialized) {
            if (_isEditing) {
              _initSplitsForEdit();
            } else {
              _membersInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedSplitMemberIds.addAll(members.map((m) => m.id));
                    // Auto-set first member as default payer
                    if (_selectedPayerId == null && members.isNotEmpty) {
                      _selectedPayerId = members.first.id;
                    }
                  });
                }
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingM, AppTheme.paddingM,
                AppTheme.paddingM, AppTheme.paddingXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount numpad — primary interaction
                AmountNumpad(
                  initialAmount: _numpadAmount,
                  onAmountChanged: (amount) {
                    setState(() => _numpadAmount = amount);
                  },
                ),
                const SizedBox(height: AppTheme.paddingM),
                // Description — the only other required field
                CupertinoTextField(
                  controller: _descriptionController,
                  placeholder: 'What was it for?',
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                const SizedBox(height: AppTheme.paddingM),
                // Paid by — always visible (Change 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Paid by',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members.map((member) {
                    final isSelected = _selectedPayerId == member.id;
                    return ChoiceChip(
                      label: Text(member.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPayerId = selected ? member.id : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.paddingM),
                // More options (collapsed by default)
                _buildMoreOptions(members),
                const SizedBox(height: AppTheme.paddingM),
                // Primary action button
                CupertinoButton.filled(
                  onPressed: _saving ? null : _saveExpense,
                  child: _saving
                      ? const CupertinoActivityIndicator(
                          color: Colors.white,
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Add Expense'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => AppErrorHandler.errorWidget(e),
      ),
    );
  }
}
