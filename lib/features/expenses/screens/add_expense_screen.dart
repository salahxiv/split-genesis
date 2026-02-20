import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
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

  bool get _isEditing => widget.expense != null;

  // Categories from expense_category.dart

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
    }
  }

  Widget _buildSplitInputs(List<Member> members) {
    if (_splitType == 'equal') {
      final amount = _numpadAmount;
      final perPerson = _selectedSplitMemberIds.isNotEmpty
          ? amount / _selectedSplitMemberIds.length
          : 0.0;
      if (_selectedSplitMemberIds.isNotEmpty &&
          _numpadAmount > 0) {
        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

    // Calculate validation info
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
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      suffixText: suffix,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider(widget.group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton.icon(
            onPressed: _saveExpense,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
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
                    _selectedSplitMemberIds
                        .addAll(members.map((m) => m.id));
                  });
                }
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Dinner, Groceries',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                AmountNumpad(
                  initialAmount: _numpadAmount,
                  onAmountChanged: (amount) {
                    setState(() => _numpadAmount = amount);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleMedium,
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
                    final cat = expenseCategories[index];
                    final isSelected = _selectedCategory == cat.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withAlpha(30)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, size: 22, color: cat.color),
                            const SizedBox(height: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? cat.color
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Paid by',
                  style: Theme.of(context).textTheme.titleMedium,
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
                const SizedBox(height: 24),
                Text(
                  'Split type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'equal', label: Text('Equal')),
                    ButtonSegment(value: 'exact', label: Text('Exact')),
                    ButtonSegment(value: 'percent', label: Text('Percent')),
                    ButtonSegment(value: 'shares', label: Text('Shares')),
                  ],
                  selected: {_splitType},
                  onSelectionChanged: (selected) {
                    setState(() => _splitType = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Split among',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedSplitMemberIds.length ==
                              members.length) {
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
                    final isSelected =
                        _selectedSplitMemberIds.contains(member.id);
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
                const SizedBox(height: 16),
                _buildSplitInputs(members),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

