import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/group.dart';
import '../models/group_type.dart';
import '../providers/groups_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../balances/screens/group_detail_screen.dart';

class AddGroupScreen extends ConsumerStatefulWidget {
  const AddGroupScreen({super.key});

  @override
  ConsumerState<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends ConsumerState<AddGroupScreen> {
  final _groupNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberNameFocus = FocusNode();
  final _memberNames = <String>[];
  String _selectedType = 'other';
  String _selectedCurrency = 'USD';
  bool _creating = false;

  Group? _createdGroup;
  bool _showQrCode = false;

  static const _currencies = [
    ('USD', 'US Dollar', '\$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('CAD', 'Canadian Dollar', 'CA\$'),
    ('AUD', 'Australian Dollar', 'A\$'),
    ('CHF', 'Swiss Franc', 'Fr'),
    ('CNY', 'Chinese Yuan', '¥'),
    ('INR', 'Indian Rupee', '₹'),
    ('MXN', 'Mexican Peso', 'MX\$'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final defaultCurrency = ref.read(defaultCurrencyProvider);
      setState(() => _selectedCurrency = defaultCurrency);
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNameController.dispose();
    _memberNameFocus.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isNotEmpty &&
        !_memberNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _memberNames.add(name);
        _memberNameController.clear();
      });
      _memberNameFocus.requestFocus();
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;
    if (_memberNames.length < 2) {
      _showError('Add at least 2 members');
      return;
    }

    setState(() => _creating = true);
    try {
      final group = await ref.read(groupsProvider.notifier).addGroup(
            groupName,
            currency: _selectedCurrency,
            type: _selectedType,
          );

      final membersNotifier = ref.read(membersProvider(group.id).notifier);
      for (final name in _memberNames) {
        await membersNotifier.addMember(name);
      }

      if (mounted) {
        setState(() {
          _createdGroup = group;
          _showQrCode = true;
          _creating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        _showError('Error creating group: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showCurrencyPicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Currency'),
        actions: _currencies.map((c) {
          final (code, name, symbol) = c;
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedCurrency = code);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$symbol  $code',
                    style: TextStyle(
                      fontWeight: _selectedCurrency == code
                          ? FontWeight.w700
                          : FontWeight.normal,
                    )),
                const SizedBox(width: 8),
                Text(name,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    )),
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

  void _proceedToGroup() {
    if (_createdGroup == null) return;
    Navigator.pushReplacement(
      context,
      slideRoute(GroupDetailScreen(group: _createdGroup!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showQrCode && _createdGroup != null) {
      return _buildQrCodeScreen(_createdGroup!);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final canCreate =
        _groupNameController.text.trim().isNotEmpty && _memberNames.length >= 2;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: (canCreate && !_creating) ? _createGroup : null,
            child: _creating
                ? const CupertinoActivityIndicator()
                : Text(
                    'Create',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: canCreate
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(80),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── Group Name ──────────────────────────────────────
          _SectionHeader(label: 'GROUP NAME'),
          _IosGroupedCard(
            isDark: isDark,
            child: _IosTextField(
              controller: _groupNameController,
              placeholder: 'Weekend Trip, Rent, …',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 28),

          // ── Type ─────────────────────────────────────────────
          _SectionHeader(label: 'TYPE'),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: groupTypes.map((type) {
                final isSelected = _selectedType == type.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withAlpha(30)
                            : (isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(
                                color: type.color.withAlpha(180), width: 1.5)
                            : Border.all(color: Colors.transparent),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withAlpha(isDark ? 40 : 12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(type.icon,
                              color: isSelected
                                  ? type.color
                                  : colorScheme.onSurface.withAlpha(100),
                              size: 24),
                          const SizedBox(height: 6),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? type.color
                                  : colorScheme.onSurface.withAlpha(140),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // ── Currency ──────────────────────────────────────────
          _SectionHeader(label: 'CURRENCY'),
          _IosGroupedCard(
            isDark: isDark,
            child: CupertinoListTile(
              title: const Text('Currency'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCurrency,
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(CupertinoIcons.chevron_forward,
                      size: 14,
                      color: colorScheme.onSurface.withAlpha(80)),
                ],
              ),
              onTap: _showCurrencyPicker,
            ),
          ),

          const SizedBox(height: 28),

          // ── Members ───────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _SectionHeader(label: 'MEMBERS')),
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 6),
                child: Text(
                  '${_memberNames.length} added',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ),
            ],
          ),
          _IosGroupedCard(
            isDark: isDark,
            child: Column(
              children: [
                // Add member input row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField.borderless(
                          controller: _memberNameController,
                          focusNode: _memberNameFocus,
                          placeholder: 'Add member name…',
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addMember(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                          ),
                          placeholderStyle: TextStyle(
                            color: colorScheme.onSurface.withAlpha(80),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 36,
                        onPressed: _addMember,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_memberNames.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(20),
                    indent: 16,
                  ),
                  // Member list
                  ...List.generate(_memberNames.length, (i) {
                    final name = _memberNames[i];
                    final isLast = i == _memberNames.length - 1;
                    return Column(
                      children: [
                        CupertinoListTile(
                          leading: CircleAvatar(
                            radius: 17,
                            backgroundColor:
                                colorScheme.primaryContainer,
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(name),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 30,
                            onPressed: () {
                              setState(() => _memberNames.removeAt(i));
                            },
                            child: Icon(
                              CupertinoIcons.minus_circle_fill,
                              color: CupertinoColors.systemRed
                                  .resolveFrom(context),
                              size: 22,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark
                                ? Colors.white.withAlpha(12)
                                : Colors.black.withAlpha(12),
                            indent: 52,
                          ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),

          if (_memberNames.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _memberNames.isEmpty
                    ? 'Add at least 2 members to create a group.'
                    : 'Add one more member.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQrCodeScreen(Group group) {
    final deepLink = 'splitgenesis://join?groupId=${group.id}';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        title: const Text('Group Created'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _proceedToGroup,
            child: const Text('Open',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Success badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.positiveColor.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        color: AppTheme.positiveColor, size: 34),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                group.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Invite others by sharing the QR code or share code below.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
              ),
              const SizedBox(height: 32),
              // QR Code
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 60 : 24),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: deepLink,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: colorScheme.primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Share code chip
              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Code copied!'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag,
                            size: 15, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          group.shareCode,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.copy,
                            size: 14,
                            color: colorScheme.onSurface.withAlpha(100)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _proceedToGroup,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Open Group',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared iOS-style helpers ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color:
              Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
    );
  }
}

class _IosGroupedCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _IosGroupedCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: child,
    );
  }
}

class _IosTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const _IosTextField({
    required this.controller,
    required this.placeholder,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: CupertinoTextField.borderless(
        controller: controller,
        placeholder: placeholder,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        placeholderStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface.withAlpha(80),
        ),
      ),
    );
  }
}
