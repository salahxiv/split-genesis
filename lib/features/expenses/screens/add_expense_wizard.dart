import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/services/activity_logger.dart';
import '../../groups/models/group.dart';
import '../../members/models/member.dart';
import '../../members/providers/members_provider.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../../../l10n/app_localizations.dart';

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
  final _amountController = TextEditingController();
  String _selectedCategory = 'general';
  bool _categoryExpanded = false;
  bool _detailsExpanded = false;
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
    _amountController.dispose();
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

  /// Fast-path: equal split across all members — skip Step 2 entirely
  bool get _isFastPath =>
      _step1Valid &&
      _splitType == 'equal' &&
      _selectedSplitMemberIds.isNotEmpty;

  Future<void> _saveExpenseFastPath() async {
    // Called from Step 1 when fast-path is active — save immediately
    await _saveExpense();
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickReceipt(ImageSource.camera);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('Take Photo'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickReceipt(ImageSource.gallery);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.photo, size: 20),
                SizedBox(width: 8),
                Text('Choose from Gallery'),
              ],
            ),
          ),
          if (_receiptFile != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                setState(() => _receiptFile = null);
                Navigator.pop(ctx);
              },
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPayerPicker(List<Member> members) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Who paid?'),
        actions: members.map((member) {
          final isSelected = _selectedPayerIds.contains(member.id);
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedPayerIds.clear();
                _selectedPayerIds.add(member.id);
              });
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(member.name),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark, size: 16, color: CupertinoColors.activeBlue),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
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
                ? 'Individual amounts must add up to ${formatCurrency(amount, _selectedCurrency)}'
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
    final theme = Theme.of(context);

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
                    color: theme.colorScheme.onSurface.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Step indicator — only show when on step 2+ or custom split chosen
                if (_currentStep >= 1 || _splitType != 'equal')
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      for (int i = 0; i < 2; i++) ...[
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i <= _currentStep
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withAlpha(40),
                            ),
                          ),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: i <= _currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(40),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: i <= _currentStep
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withAlpha(120),
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
                      ['Essentials', 'Split & Save'][_currentStep],
                      style: theme.textTheme.titleLarge
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
                      _buildStep2Combined(members),
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
                      // On step 0: fast-path Save (equal split) or Customize Split
                      if (_currentStep == 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CupertinoButton.filled(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              onPressed: (_isFastPath && !_saving) ? _saveExpenseFastPath : (_step1Valid ? () => _goToStep(1) : null),
                              child: _saving
                                  ? const CupertinoActivityIndicator(color: Colors.white)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_isFastPath ? CupertinoIcons.checkmark_alt : CupertinoIcons.arrow_right, size: 18),
                                        const SizedBox(width: 6),
                                        Text(_isFastPath ? 'Save' : 'Customize Split'),
                                      ],
                                    ),
                            ),
                            if (_isFastPath)
                              CupertinoButton(
                                padding: const EdgeInsets.only(top: 8),
                                onPressed: _step1Valid ? () => _goToStep(1) : null,
                                child: Text(
                                  'Customize split',
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (_currentStep == 1)
                        CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          onPressed: _step1Valid && _step2Valid && !_saving
                              ? _saveExpense
                              : null,
                          child: _saving
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(CupertinoIcons.checkmark_alt, size: 18),
                                    SizedBox(width: 6),
                                    Text('Add Expense'),
                                  ],
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () {
            debugPrint('[DEBUG] Members loading...');
            return const Center(child: CupertinoActivityIndicator());
          },
          error: (e, stack) {
            debugPrint('[DEBUG] Members ERROR: $e');
            debugPrint('[DEBUG] Members STACK: $stack');
            return AppErrorHandler.errorWidget(e);
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
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCat = getCategoryData(_selectedCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Amount — native keyboard
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                color: theme.colorScheme.onSurface.withAlpha(60),
              ),
              prefixText: '${getCurrencySymbol(_selectedCurrency)} ',
              prefixStyle: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
              border: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              if (amount != _numpadAmount) {
                setState(() => _numpadAmount = amount);
              }
            },
          ),
          // Inline equal-split preview
          if (_numpadAmount > 0 && _selectedSplitMemberIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '= ${formatCurrency(_numpadAmount / _selectedSplitMemberIds.length, _selectedCurrency)} each (${_selectedSplitMemberIds.length} people)',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., Dinner, Groceries',
              border: OutlineInputBorder(),
              prefixIcon: Icon(CupertinoIcons.text_alignleft),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          // Paid by — tappable row
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showPayerPicker(members),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _selectedPayerIds.isNotEmpty
                          ? members.firstWhere((m) => _selectedPayerIds.contains(m.id), orElse: () => members.first).name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Paid by', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selectedPayerIds.isEmpty
                          ? 'Select...'
                          : members.where((m) => _selectedPayerIds.contains(m.id)).map((m) => m.name).join(', '),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_forward, size: 14, color: theme.colorScheme.onSurface.withAlpha(80)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Collapsed summary showing defaults
          GestureDetector(
            onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.slider_horizontal_3, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text('More Details', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  // Summary of current values when collapsed
                  if (!_detailsExpanded) ...[
                    Icon(selectedCat.icon, size: 14, color: selectedCat.color),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat.MMMd().format(_selectedDate),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCurrency,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _detailsExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 14,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ],
              ),
            ),
          ),
          if (_detailsExpanded) ...[
            const SizedBox(height: 12),
            // Category — collapsible, shows selected chip
            GestureDetector(
              onTap: () => setState(() => _categoryExpanded = !_categoryExpanded),
              child: Row(
                children: [
                  Icon(selectedCat.icon, size: 18, color: selectedCat.color),
                  const SizedBox(width: 8),
                  Text(selectedCat.label, style: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedCat.color,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(width: 4),
                  Icon(
                    _categoryExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 18,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                  const Spacer(),
                  Text('Category', style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  )),
                ],
              ),
            ),
            if (_categoryExpanded) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: expenseCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.key;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat.key;
                      _categoryExpanded = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withAlpha(30)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? cat.color : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Date picker
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
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(CupertinoIcons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurface.withAlpha(120)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Recurring toggle (Issue #48)
            Row(
              children: [
                const Icon(CupertinoIcons.repeat, size: 20),
                const SizedBox(width: 8),
                Text('Wiederkehrend', style: theme.textTheme.titleSmall),
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
                segments: [
                  ButtonSegment(value: 'weekly', label: Text(AppLocalizations.of(context).recurringWeekly)),
                  ButtonSegment(value: 'biweekly', label: Text(AppLocalizations.of(context).recurringBiweekly)),
                  ButtonSegment(value: 'monthly', label: Text(AppLocalizations.of(context).recurringMonthly)),
                ],
                selected: {_recurrenceInterval},
                onSelectionChanged: (s) =>
                    setState(() => _recurrenceInterval = s.first),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).recurringNextExecution(_nextDueDateLabel()),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
            const SizedBox(height: 16),
            // Currency selector
            Row(
              children: [
                Text('Currency', style: theme.textTheme.titleSmall),
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
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep2Combined(List<Member> members) {
    final amount = _numpadAmount;
    final selectedMembers =
        members.where((m) => _selectedSplitMemberIds.contains(m.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Split type descriptions
    const splitDescriptions = {
      'equal': 'Everyone pays the same',
      'exact': 'Enter exact amounts',
      'percent': 'Split by percentage',
      'shares': 'Split by ratio',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // ── Split Type: CupertinoSlidingSegmentedControl ──────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _splitType,
              thumbColor: isDark ? const Color(0xFF3A3A3C) : Colors.white,
              backgroundColor: Colors.transparent,
              children: const {
                'equal': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Equal', style: TextStyle(fontSize: 13)),
                ),
                'exact': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Exact', style: TextStyle(fontSize: 13)),
                ),
                'percent': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('%', style: TextStyle(fontSize: 13)),
                ),
                'shares': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Shares', style: TextStyle(fontSize: 13)),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  setState(() => _splitType = value);
                }
              },
            ),
          ),
          const SizedBox(height: 6),
          // Description
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              splitDescriptions[_splitType] ?? '',
              key: ValueKey(_splitType),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Split among: iOS grouped list ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPLIT AMONG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 28,
                onPressed: () {
                  setState(() {
                    if (_selectedSplitMemberIds.length == members.length) {
                      _selectedSplitMemberIds.clear();
                    } else {
                      _selectedSplitMemberIds.clear();
                      _selectedSplitMemberIds.addAll(members.map((m) => m.id));
                    }
                  });
                },
                child: Text(
                  _selectedSplitMemberIds.length == members.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(members.length, (i) {
                final member = members[i];
                final isSelected = _selectedSplitMemberIds.contains(member.id);
                final isLast = i == members.length - 1;

                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? const Radius.circular(12) : Radius.zero,
                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedSplitMemberIds.remove(member.id);
                          } else {
                            _selectedSplitMemberIds.add(member.id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Checkmark circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withAlpha(60),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      CupertinoIcons.checkmark,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              member.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            // Show split amount for equal split
                            if (isSelected && _splitType == 'equal' && amount > 0)
                              Text(
                                formatCurrency(
                                  amount / _selectedSplitMemberIds.length,
                                  _selectedCurrency,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 52,
                        color: isDark
                            ? Colors.white.withAlpha(12)
                            : Colors.black.withAlpha(12),
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Live split preview
          if (selectedMembers.isNotEmpty && amount > 0)
            ValueListenableBuilder<int>(
              valueListenable: _splitInputNotifier,
              builder: (_, __, ___) =>
                  _buildLiveSplitPreview(selectedMembers, amount),
            ),

          // Custom split inputs for non-equal
          if (_splitType != 'equal') ...[
            const SizedBox(height: 8),
            _buildSplitInputs(members),
          ],

          const SizedBox(height: 24),

          // Receipt Photo section
          Text('Receipt Photo',
              style: theme.textTheme.titleSmall
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
                  color: theme.colorScheme.outline.withAlpha(80),
                  width: 1.5,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              ),
              child: _uploadingReceipt
                  ? const Center(child: CupertinoActivityIndicator())
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
                                child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.camera,
                            size: 32,
                            color: theme.colorScheme.outline),
                        const SizedBox(height: 6),
                        Text('Add Receipt (optional)',
                            style: TextStyle(
                                color: theme.colorScheme.outline)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
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
                Icon(CupertinoIcons.chart_bar,
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
                          formatCurrency(memberAmt, _selectedCurrency),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    String placeholder;
    String suffixLabel;
    switch (_splitType) {
      case 'percent':
        suffixLabel = '%';
        placeholder = '0';
        break;
      case 'exact':
        suffixLabel = getCurrencySymbol(_selectedCurrency);
        placeholder = '0.00';
        break;
      case 'shares':
        suffixLabel = 'x';
        placeholder = '1';
        break;
      default:
        suffixLabel = '';
        placeholder = '0';
    }

    return ValueListenableBuilder<int>(
      valueListenable: _splitInputNotifier,
      builder: (context, _, __) {
        double total = 0;
        for (final m in selectedMembers) {
          total += double.tryParse(_getController(m.id).text) ?? 0;
        }

        // Validation
        String? validationText;
        bool isValid = false;
        if (_splitType == 'exact') {
          final diff = amount - total;
          if (diff.abs() > 0.01) {
            validationText =
                '${getCurrencySymbol(_selectedCurrency)}${diff.abs().toStringAsFixed(2)} ${diff > 0 ? 'remaining' : 'over budget'}';
          } else {
            validationText = '\u2713 Amounts match';
            isValid = true;
          }
        } else if (_splitType == 'percent') {
          final diff = 100 - total;
          if (diff.abs() > 0.1) {
            validationText =
                '${diff.abs().toStringAsFixed(1)}% ${diff > 0 ? 'remaining' : 'over 100%'}';
          } else {
            validationText = '\u2713 100% allocated';
            isValid = true;
          }
        } else if (_splitType == 'shares' && total > 0) {
          validationText = '${total.toStringAsFixed(0)} total shares';
          isValid = true;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'CUSTOM AMOUNTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(selectedMembers.length, (i) {
                  final member = selectedMembers[i];
                  final controller = _getController(member.id);
                  final isLast = i == selectedMembers.length - 1;

                  // Computed dollar amount for display
                  String? computedAmount;
                  if (_splitType == 'percent') {
                    final pct = double.tryParse(controller.text) ?? 0;
                    computedAmount =
                        formatCurrency(amount * pct / 100, _selectedCurrency);
                  } else if (_splitType == 'shares' && total > 0) {
                    final share = double.tryParse(controller.text) ?? 0;
                    computedAmount =
                        formatCurrency(amount * share / total, _selectedCurrency);
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                member.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoTextField(
                                controller: controller,
                                placeholder: placeholder,
                                suffix: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    suffixLabel,
                                    style: TextStyle(
                                      color: colorScheme.onSurface
                                          .withAlpha(120),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                textAlign: TextAlign.right,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF3A3A3C)
                                      : const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 15,
                                ),
                                onChanged: (_) {
                                  _splitInputNotifier.value++;
                                  _autoFillExactSplit(selectedMembers);
                                },
                              ),
                            ),
                            if (computedAmount != null) ...[
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  computedAmount,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          color: isDark
                              ? Colors.white.withAlpha(12)
                              : Colors.black.withAlpha(12),
                        ),
                    ],
                  );
                }),
              ),
            ),
            // Validation row
            if (validationText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    Icon(
                      isValid
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.exclamationmark_circle_fill,
                      size: 14,
                      color: isValid
                          ? AppTheme.positiveColor
                          : AppTheme.negativeColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      validationText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isValid
                            ? AppTheme.positiveColor
                            : AppTheme.negativeColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
