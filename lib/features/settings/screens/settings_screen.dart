import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

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

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Split Genesis',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.call_split,
          color: Colors.white,
          size: 28,
        ),
      ),
      applicationLegalese: '© 2026 Split Genesis. All rights reserved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final displayName = ref.watch(displayNameProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // --- Profile Section ---
          _SectionHeader(label: 'Profile', icon: Icons.person),
          _SectionCard(
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
                                  child: TextField(
                                    controller: _displayNameController,
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: InputDecoration(
                                      hintText: 'Your name',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onSubmitted: (_) => _saveDisplayName(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _saveDisplayName,
                                  icon: const Icon(Icons.check, size: 18),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(36, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _displayNameController.text = displayName;
                                    setState(() => _isEditingName = false);
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(36, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.isEmpty
                                      ? 'Tap to set your name'
                                      : displayName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: displayName.isEmpty
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onSurface,
                                    fontStyle: displayName.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Display name',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (!_isEditingName)
                      IconButton(
                        onPressed: () =>
                            setState(() => _isEditingName = true),
                        icon: Icon(
                          Icons.edit_outlined,
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
          _SectionHeader(label: 'Appearance', icon: Icons.palette),
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Theme',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> selected) {
                    ref.read(themeModeProvider.notifier).set(
                        selected.first);
                  },
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                  ],
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Default Currency Section ---
          _SectionHeader(
            label: 'Default Currency',
            icon: Icons.attach_money,
          ),
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DropdownButtonFormField<String>(
                  value: defaultCurrency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  isExpanded: true,
                  items: _currencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(_currencyLabels[currency] ?? currency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref.read(defaultCurrencyProvider.notifier).set(
                          newValue);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Used as the default when creating new expenses.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- About Section ---
          _SectionHeader(label: 'About', icon: Icons.info_outline),
          _SectionCard(
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('App Version'),
                trailing: Text(
                  '1.0.0',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              ListTile(
                leading: Icon(
                  Icons.gavel_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Licenses'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: _showAboutDialog,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              ListTile(
                leading: Icon(
                  Icons.favorite_outline,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Built with Flutter'),
                trailing: Text(
                  'Made with love',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// A styled section header with an icon and label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card-style container for grouping settings list tiles.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
