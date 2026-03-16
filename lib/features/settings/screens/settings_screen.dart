import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/ios_section.dart';
import '../providers/settings_provider.dart';
import 'legal_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _isEditingName = false;

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'MXN',
  ];

  static const Map<String, String> _currencyLabels = {
    'USD': 'US Dollar (USD)',
    'EUR': 'Euro (EUR)',
    'GBP': 'British Pound (GBP)',
    'JPY': 'Japanese Yen (JPY)',
    'CAD': 'Canadian Dollar (CAD)',
    'AUD': 'Australian Dollar (AUD)',
    'CHF': 'Swiss Franc (CHF)',
    'CNY': 'Chinese Yuan (CNY)',
    'INR': 'Indian Rupee (INR)',
    'MXN': 'Mexican Peso (MXN)',
  };

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(displayNameProvider);
    _displayNameController.text = currentName;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  void _saveDisplayName() {
    final newName = _displayNameController.text.trim();
    ref.read(displayNameProvider.notifier).set(newName);
    setState(() {
      _isEditingName = false;
    });
  }

  void _showCurrencyPicker(String currentCurrency) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Default Currency'),
        actions: _currencies.map((currency) {
          return CupertinoActionSheetAction(
            onPressed: () {
              ref.read(defaultCurrencyProvider.notifier).set(currency);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currencyLabels[currency] ?? currency),
                if (currency == currentCurrency)
                  const Icon(CupertinoIcons.checkmark,
                      size: 16, color: CupertinoColors.activeBlue),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.iosCardBackground,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.arrow_branch,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Split Genesis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: context.iosSecondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u00a9 2026 Split Genesis. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: context.iosSecondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final displayName = ref.watch(displayNameProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Map ThemeMode to segment index
    final segmentIndex = themeMode == ThemeMode.light
        ? 0
        : themeMode == ThemeMode.dark
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            backgroundColor: context.iosGroupedBackground,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // --- Profile Section ---
                IosSection(
                  header: 'Profile',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              _getInitials(displayName),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isEditingName
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: CupertinoTextField(
                                          controller:
                                              _displayNameController,
                                          autofocus: true,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          placeholder: 'Your name',
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          onSubmitted: (_) =>
                                              _saveDisplayName(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minSize: 36,
                                        onPressed: _saveDisplayName,
                                        child: Icon(
                                          CupertinoIcons
                                              .checkmark_circle_fill,
                                          color: colorScheme.primary,
                                          size: 28,
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minSize: 36,
                                        onPressed: () {
                                          _displayNameController.text =
                                              displayName;
                                          setState(() =>
                                              _isEditingName = false);
                                        },
                                        child: Icon(
                                          CupertinoIcons
                                              .xmark_circle_fill,
                                          color: CupertinoColors
                                              .systemGrey,
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName.isEmpty
                                            ? 'Tap to set your name'
                                            : displayName,
                                        style:
                                            textTheme.titleMedium?.copyWith(
                                          color: displayName.isEmpty
                                              ? colorScheme
                                                  .onSurfaceVariant
                                              : colorScheme.onSurface,
                                          fontStyle: displayName.isEmpty
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Display name',
                                        style: textTheme.bodySmall
                                            ?.copyWith(
                                          color: context.iosSecondaryLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (!_isEditingName)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 36,
                              onPressed: () =>
                                  setState(() => _isEditingName = true),
                              child: Icon(
                                CupertinoIcons.pencil,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Appearance Section ---
                IosSection(
                  header: 'Appearance',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoSlidingSegmentedControl<int>(
                            groupValue: segmentIndex,
                            onValueChanged: (int? value) {
                              if (value == null) return;
                              final mode = value == 0
                                  ? ThemeMode.light
                                  : value == 2
                                      ? ThemeMode.dark
                                      : ThemeMode.system;
                              ref
                                  .read(themeModeProvider.notifier)
                                  .set(mode);
                            },
                            children: const {
                              0: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('Light'),
                              ),
                              1: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('System'),
                              ),
                              2: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('Dark'),
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Default Currency Section ---
                IosSection(
                  header: 'Default Currency',
                  children: [
                    IosSectionRow(
                      leading: Icon(
                        CupertinoIcons.money_dollar_circle,
                        color: context.iosSecondaryLabel,
                      ),
                      title: 'Currency',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            defaultCurrency,
                            style: textTheme.bodyMedium?.copyWith(
                              color: context.iosSecondaryLabel,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            size: 14,
                            color: context.iosSecondaryLabel,
                          ),
                        ],
                      ),
                      onTap: () =>
                          _showCurrencyPicker(defaultCurrency),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Used as the default when creating new expenses.',
                        style: textTheme.bodySmall?.copyWith(
                          color: context.iosSecondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- About Section ---
                IosSection(
                  header: 'About',
                  children: [
                    IosSectionRow(
                      leading: Icon(
                        CupertinoIcons.info,
                        color: context.iosSecondaryLabel,
                      ),
                      title: 'App Version',
                      trailing: Text(
                        '1.0.0',
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.iosSecondaryLabel,
                        ),
                      ),
                    ),
                    IosSectionRow(
                      leading: Icon(
                        CupertinoIcons.doc_text,
                        color: context.iosSecondaryLabel,
                      ),
                      title: 'About',
                      onTap: _showAboutSheet,
                    ),
                    IosSectionRow(
                      leading: Icon(
                        CupertinoIcons.shield,
                        color: context.iosSecondaryLabel,
                      ),
                      title: 'Privacy & Terms',
                      onTap: () => Navigator.push(
                        context,
                        slideRoute(const LegalScreen()),
                      ),
                    ),
                    IosSectionRow(
                      leading: Icon(
                        CupertinoIcons.heart,
                        color: context.iosSecondaryLabel,
                      ),
                      title: 'Built with Flutter',
                      trailing: Text(
                        'Made with love',
                        style: textTheme.bodySmall?.copyWith(
                          color: context.iosSecondaryLabel,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Extra bottom padding for tab bar
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
