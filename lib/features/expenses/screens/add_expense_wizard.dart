import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/services/recurring_expense_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_logger.dart';
import '../../groups/models/group.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../widgets/amount_numpad.dart';

class AddExpenseWizard extends ConsumerStatefulWidget {
  final Group group;

  const AddExpenseWizard({super.key, required this.group});

  @override
  ConsumerState<AddExpenseWizard> createState() => _AddExpenseWizardState();
}

class _AddExpenseWizardState extends ConsumerState<AddExpenseWizard> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1 fields
  double _numpadAmount = 0;
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'general';
  final Set<String> _selectedPayerIds = {};
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'USD'; // defaults to group currency, set in initState

  // Receipt photo
  File? _receiptFile;
  bool _uploadingReceipt = false;

  // Recurring fields (Issue #48)
  bool _isRecurring = false;
  String _recurrenceInterval = 'monthly';

  // Step 2 fields
  String _splitType = 'equal';
  final Set<String> _selectedSplitMemberIds = {};
  final Map<String, TextEditingController> _splitControllers = {};
  bool _membersInitialized = false;
  // Notifier to trigger targeted rebuilds for split validation only
  final ValueNotifier<int> _splitInputNotifier = ValueNotifier<int>(0);
  bool _saving = false; // Double-submit guard

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.group.currency;
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    // Only rebuild if validation state actually changed
    final valid = _step1Valid;
    if (valid != _lastStep1Valid) {
      _lastStep1Valid = valid;
      setState(() {});
    }
  }

  bool _lastStep1Valid = false;

  // Categories now from expense_category.dart

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _pageController.dispose();
    _descriptionController.dispose();
    _splitInputNotifier.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String memberId) {
    return _splitControllers.putIfAbsent(
        memberId, () => TextEditingController());
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  bool get _step1Valid {
    return _descriptionController.text.trim().isNotEmpty &&
        _numpadAmount > 0 &&
        _selectedPayerIds.isNotEmpty;
  }

  bool get _step2Valid => _selectedSplitMemberIds.isNotEmpty;

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

  Future<void> _pickReceipt(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 90, // pre-compress at capture
    );
    if (picked == null) return;

    setState(() {
      _receiptFile = File(picked.path);
      _uploadingReceipt = false; // upload happens on save
    });
  }

  void _showReceiptPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickReceipt(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickReceipt(ImageSource.gallery);
              },
            ),
            if (_receiptFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _receiptFile = null);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_saving) return; // Double-submit guard
    final amount = _numpadAmount;
    final description = _descriptionController.text.trim();

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

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final swTotal = Stopwatch()..start();
    debugPrint('[PERF] _saveExpense START');
    try {
      final notifier = ref.read(expensesProvider(widget.group.id).notifier);
      final members = ref.read(membersProvider(widget.group.id)).valueOrNull ?? [];
      final payerNames = members
          .where((m) => _selectedPayerIds.contains(m.id))
          .map((m) => m.name)
          .toList();
      final payerName = payerNames.isNotEmpty ? payerNames.join(', ') : 'Someone';

      // Generate expense ID early so we can use it for receipt upload path
      // The notifier will use its own UUID; pass receiptUrl separately after upload
      String? uploadedReceiptUrl;
      if (_receiptFile != null) {
        // We'll use a temp expenseId for the path; the notifier generates the real one.
        // To keep it simple: upload first, pass URL to notifier.
        // Note: expenseId used in path is a placeholder — real id is generated in notifier.
        // We upload using a temp name and update after save if needed, but for simplicity
        // we do upload before insert and the URL is stable regardless of final expenseId.
        try {
          setState(() => _uploadingReceipt = true);
          // Use group + timestamp as path key; actual expenseId is not needed for URL stability
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          uploadedReceiptUrl = await ReceiptService.shared.processAndUpload(
            _receiptFile!,
            groupId: widget.group.id,
            expenseId: tempId,
          );
        } catch (e) {
          debugPrint('[Receipt] Upload error (non-fatal): $e');
        } finally {
          if (mounted) setState(() => _uploadingReceipt = false);
        }
      }

      // Compute nextDueDate for recurring expenses
      DateTime? nextDueDate;
      if (_isRecurring) {
        switch (_recurrenceInterval) {
          case 'weekly':
            nextDueDate = _selectedDate.add(const Duration(days: 7));
            break;
          case 'biweekly':
            nextDueDate = _selectedDate.add(const Duration(days: 14));
            break;
          case 'monthly':
          default:
            final nm = _selectedDate.month == 12 ? 1 : _selectedDate.month + 1;
            final ny = _selectedDate.month == 12 ? _selectedDate.year + 1 : _selectedDate.year;
            final lastDay = DateTime(ny, nm + 1, 0).day;
            nextDueDate = DateTime(ny, nm, _selectedDate.day.clamp(1, lastDay));
        }
      }

      await notifier.addExpense(
        description: description,
        amount: amount,
        paidByIds: _selectedPayerIds.toList(),
        splitAmongIds: _selectedSplitMemberIds.toList(),
        category: _selectedCategory,
        splitType: _splitType,
        currency: _selectedCurrency,
        expenseDate: _selectedDate,
        customSplits: customSplits,
        receiptUrl: uploadedReceiptUrl,
        isRecurring: _isRecurring,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
        nextDueDate: nextDueDate,
      );
      debugPrint('[PERF] _saveExpense: addExpense done at ${swTotal.elapsedMilliseconds}ms');

      NotificationService.instance.showExpenseAdded(
        groupName: widget.group.name,
        description: description,
        amount: amount,
        paidByName: payerName,
      );

      await ActivityLogger.instance.logExpenseCreated(
        groupId: widget.group.id,
        description: description,
        amount: amount,
        paidByName: payerName,
      );
      debugPrint('[PERF] _saveExpense: activity logged at ${swTotal.elapsedMilliseconds}ms');
      ref.invalidate(activityProvider(widget.group.id));

      if (mounted) {
        Navigator.pop(context, 'added');
        debugPrint('[PERF] _saveExpense DONE in ${swTotal.elapsedMilliseconds}ms');
      }
    } catch (e) {
      debugPrint('[PERF] _saveExpense ERROR after ${swTotal.elapsedMilliseconds}ms: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG] AddExpenseWizard.build() for group: ${widget.group.id}');
    final membersAsync = ref.watch(membersProvider(widget.group.id));
    debugPrint('[DEBUG] membersAsync: $membersAsync');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return membersAsync.when(
          data: (members) {
            debugPrint('[DEBUG] Members loaded: ${members.length} members');
            if (!_membersInitialized && members.isNotEmpty) {
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

            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i <= _currentStep
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(40),
                            ),
                          ),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: i <= _currentStep
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(40),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: i <= _currentStep
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(120),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Step title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ['Essentials', 'Split', 'Review'][_currentStep],
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentStep = i),
                    children: [
                      _buildStep1(members),
                      _buildStep2(members),
                      _buildStep3(members),
                    ],
                  ),
                ),
                // Bottom buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24,
                      MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () => _goToStep(_currentStep - 1),
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox.shrink(),
                      if (_currentStep < 2)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                          onPressed: (_currentStep == 0 && _step1Valid) ||
                                  (_currentStep == 1 && _step2Valid)
                              ? () => _goToStep(_currentStep + 1)
                              : null,
                          child: const Text('Next'),
                        ),
                      if (_currentStep == 2)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                          onPressed: _step1Valid && _step2Valid
                              ? _saveExpense
                              : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Add Expense'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () {
            debugPrint('[DEBUG] Members loading...');
            return const Center(child: CircularProgressIndicator());
          },
          error: (e, stack) {
            debugPrint('[DEBUG] Members ERROR: $e');
            debugPrint('[DEBUG] Members STACK: $stack');
            return Center(child: Text('Error: $e'));
          },
        );
      },
    );
  }

  String _nextDueDateLabel() {
    final base = _selectedDate;
    DateTime next;
    switch (_recurrenceInterval) {
      case 'weekly':
        next = base.add(const Duration(days: 7));
        break;
      case 'biweekly':
        next = base.add(const Duration(days: 14));
        break;
      case 'monthly':
      default:
        final nm = base.month == 12 ? 1 : base.month + 1;
        final ny = base.month == 12 ? base.year + 1 : base.year;
        final lastDay = DateTime(ny, nm + 1, 0).day;
        next = DateTime(ny, nm, base.day.clamp(1, lastDay));
    }
    return '${next.day.toString().padLeft(2, '0')}.${next.month.toString().padLeft(2, '0')}.${next.year}';
  }

  Widget _buildStep1(List<Member> members) {
    debugPrint('[DEBUG] _buildStep1 called with ${members.length} members');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Description
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
          const SizedBox(height: 20),
          // Category grid picker
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
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
          const SizedBox(height: 20),
          // Paid by chips (horizontal scroll)
          Text('Paid by', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: members.map((member) {
                final isSelected = _selectedPayerIds.contains(member.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(member.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPayerIds.add(member.id);
                        } else {
                          _selectedPayerIds.remove(member.id);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Date picker
          Text('Date', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Recurring toggle (Issue #48)
          Row(
            children: [
              const Icon(Icons.repeat, size: 20),
              const SizedBox(width: 8),
              Text('Wiederkehrend', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'weekly', label: Text('Wöchentlich')),
                ButtonSegment(value: 'biweekly', label: Text('2-wöchentl.')),
                ButtonSegment(value: 'monthly', label: Text('Monatlich')),
              ],
              selected: {_recurrenceInterval},
              onSelectionChanged: (s) =>
                  setState(() => _recurrenceInterval = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              'Nächste Ausführung: ${_nextDueDateLabel()}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 16),
          // Currency selector
          Row(
            children: [
              Text('Currency', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: CurrencyConverter.supportedCurrencies.map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Text('$code  ${getCurrencySymbol(code)}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCurrency = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom numpad
          AmountNumpad(
            onAmountChanged: (amount) {
              setState(() => _numpadAmount = amount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(List<Member> members) {
    final amount = _numpadAmount;
    final selectedMembers =
        members.where((m) => _selectedSplitMemberIds.contains(m.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          // Member toggle chips
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
          const SizedBox(height: 4),
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
          // Live split preview (Issue #51) — rebuilds when custom inputs change
          if (selectedMembers.isNotEmpty && amount > 0)
            ValueListenableBuilder<int>(
              valueListenable: _splitInputNotifier,
              builder: (_, __, ___) =>
                  _buildLiveSplitPreview(selectedMembers, amount),
            ),
          // Custom split inputs for non-equal
          if (_splitType != 'equal') _buildSplitInputs(members),
        ],
      ),
    );
  }

  /// Animated live-preview of who pays how much (Issue #51).
  Widget _buildLiveSplitPreview(List<Member> selectedMembers, double amount) {
    // Compute amounts per member
    final Map<String, double> memberAmounts = {};
    if (_splitType == 'equal') {
      final perPerson = amount / selectedMembers.length;
      for (final m in selectedMembers) {
        memberAmounts[m.id] = perPerson;
      }
    } else {
      // For custom splits, use live controller values
      double totalShares = 0;
      if (_splitType == 'shares') {
        for (final m in selectedMembers) {
          totalShares += double.tryParse(_getController(m.id).text) ?? 0;
        }
      }
      for (final m in selectedMembers) {
        final val = double.tryParse(_getController(m.id).text) ?? 0;
        switch (_splitType) {
          case 'exact':
            memberAmounts[m.id] = val;
            break;
          case 'percent':
            memberAmounts[m.id] = amount * val / 100;
            break;
          case 'shares':
            memberAmounts[m.id] =
                totalShares > 0 ? amount * val / totalShares : 0;
            break;
        }
      }
    }

    final maxAmount =
        memberAmounts.values.fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Split-Vorschau',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...selectedMembers.map((m) {
              final memberAmt = memberAmounts[m.id] ?? 0;
              final ratio = maxAmount > 0 ? memberAmt / maxAmount : 0.0;
              final currency = _selectedCurrency;
              final symbol = getCurrencySymbol(currency);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$symbol${memberAmt.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio.toDouble()),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(40),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _autoFillExactSplit(List<Member> selectedMembers) {
    if (_splitType != 'exact') return;
    final amount = _numpadAmount;
    if (amount <= 0) return;

    // Find members with empty input
    final emptyMembers = <String>[];
    double filledTotal = 0;
    for (final m in selectedMembers) {
      final text = _getController(m.id).text;
      final val = double.tryParse(text);
      if (text.isEmpty || val == null) {
        emptyMembers.add(m.id);
      } else {
        filledTotal += val;
      }
    }

    // Auto-fill only when exactly one member has no input
    if (emptyMembers.length == 1) {
      final remaining = amount - filledTotal;
      if (remaining >= 0) {
        _getController(emptyMembers.first).text = remaining.toStringAsFixed(2);
      }
    }
  }

  Widget _buildSplitInputs(List<Member> members) {
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

    return ValueListenableBuilder<int>(
      valueListenable: _splitInputNotifier,
      builder: (context, _, __) {
        double total = 0;
        for (final m in selectedMembers) {
          total += double.tryParse(_getController(m.id).text) ?? 0;
        }

        String? validationText;
        Color? validationColor;
        if (_splitType == 'exact') {
          final diff = amount - total;
          if (diff.abs() > 0.01) {
            validationText =
                '\$${diff.abs().toStringAsFixed(2)} ${diff > 0 ? 'remaining' : 'over'}';
            validationColor = AppTheme.negativeColor;
          } else {
            validationText = 'Amounts match';
            validationColor = AppTheme.positiveColor;
          }
        } else if (_splitType == 'percent') {
          final diff = 100 - total;
          if (diff.abs() > 0.1) {
            validationText =
                '${diff.abs().toStringAsFixed(1)}% ${diff > 0 ? 'remaining' : 'over'}';
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
                memberAmount =
                    '\$${(amount * share / total).toStringAsFixed(2)}';
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
                        onChanged: (_) {
                          _splitInputNotifier.value++;
                          _autoFillExactSplit(selectedMembers);
                        },
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
      },
    );
  }

  Widget _buildStep3(List<Member> members) {
    final amount = _numpadAmount;
    final description = _descriptionController.text.trim();
    final payerNames = members
        .where((m) => _selectedPayerIds.contains(m.id))
        .map((m) => m.name)
        .toList();
    final payerName = payerNames.isNotEmpty ? payerNames.join(', ') : 'Unknown';
    final perPerson = _selectedSplitMemberIds.isNotEmpty
        ? amount / _selectedSplitMemberIds.length
        : 0.0;
    final memberMap = {for (var m in members) m.id: m.name};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Summary card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(getCategoryData(_selectedCategory).icon,
                          size: 18,
                          color: getCategoryData(_selectedCategory).color),
                      const SizedBox(width: 4),
                      Text(
                        getCategoryData(_selectedCategory).label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 4),
                      Text('Paid by $payerName'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Receipt Photo section
          Text('Receipt Photo',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showReceiptPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(80),
                  width: 1.5,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60),
              ),
              child: _uploadingReceipt
                  ? const Center(child: CircularProgressIndicator())
                  : _receiptFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_receiptFile!, fit: BoxFit.cover),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _receiptFile = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 32,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 6),
                        Text('Add Receipt (optional)',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Split details
          Text('Split Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${_splitType[0].toUpperCase()}${_splitType.substring(1)} split among ${_selectedSplitMemberIds.length} people',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ...(_selectedSplitMemberIds.map((id) {
            final name = memberMap[id] ?? 'Unknown';
            double splitAmount;
            if (_splitType == 'equal') {
              splitAmount = perPerson;
            } else {
              final customSplits = _calculateCustomSplits(amount);
              splitAmount = customSplits?[id] ?? 0;
            }
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              title: Text(name),
              trailing: Text(
                '\$${splitAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          })),
        ],
      ),
    );
  }
}
