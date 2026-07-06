import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ios_section.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/account_stats_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final displayName = ref.watch(displayNameProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final spentAsync = ref.watch(lifetimeSpentProvider);
    final settledAsync = ref.watch(lifetimeSettledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryLabel = isDark
        ? AppTheme.iosSecondaryLabel
        : const Color(0xFF6E6E73);

    final shownName = displayName.isNotEmpty ? displayName : l10n.accountYou;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.accountTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          // ── Avatar + Name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(shownName),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  shownName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.accountDefaultCurrency(defaultCurrency),
                  style: TextStyle(fontSize: 14, color: secondaryLabel),
                ),
              ],
            ),
          ),

          // ── Statistik-Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              l10n.accountMyStats,
              style: TextStyle(
                fontSize: 13,
                color: secondaryLabel,
                letterSpacing: -0.08,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: CupertinoIcons.arrow_down,
                    iconColor: AppTheme.negativeColor,
                    label: l10n.accountTotalSpent,
                    valueAsync: spentAsync,
                    currency: defaultCurrency,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: CupertinoIcons.checkmark,
                    iconColor: AppTheme.positiveColor,
                    label: l10n.accountTotalSettled,
                    valueAsync: settledAsync,
                    currency: defaultCurrency,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Einstellungen
          IosSection(
            header: l10n.accountSettings,
            children: [
              IosSectionRow(
                leading: const _LeadingIcon(CupertinoIcons.person),
                title: l10n.accountPersonalData,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IosSectionRow(
                leading: const _LeadingIcon(CupertinoIcons.bell),
                title: l10n.accountNotifications,
                onTap: () => _showComingSoon(context, l10n.accountNotifications),
              ),
              IosSectionRow(
                leading: const _LeadingIcon(CupertinoIcons.creditcard),
                title: l10n.accountBankDetails,
                onTap: () => _showComingSoon(context, l10n.accountBankDetails),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Abmelden
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.negativeColor.withAlpha(28),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _showComingSoon(context, l10n.accountSignOut),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.square_arrow_right,
                          color: AppTheme.negativeColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.accountSignOut,
                          style: const TextStyle(
                            color: AppTheme.negativeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.accountComingSoon(feature)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueAsync,
    required this.currency,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final AsyncValue<double> valueAsync;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCard : Colors.white;
    final secondaryLabel =
        isDark ? AppTheme.iosSecondaryLabel : const Color(0xFF6E6E73);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(36),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          // valueOrNull: previous value during reload, '—' before first load.
          // Avoids loading-flash on every Account tab visit.
          Text(
            valueAsync.value != null
                ? formatCurrency(valueAsync.value!, currency)
                : '—',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: valueAsync.value == null
                  ? secondaryLabel
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(28),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: AppTheme.primaryColor),
    );
  }
}
