import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../l10n/app_localizations.dart';

/// Legal information screen — Privacy Policy & Terms of Service.
///
/// DSGVO / GDPR compliant per Article 13 requirements:
/// - Identifies the data controller
/// - Describes what data is collected and for what purpose
/// - States the legal basis (Art. 6(1)(b) DSGVO — contract)
/// - States the retention period
/// - Documents the user's right to deletion / portability
///
/// Linked from Settings → About → Legal.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  int _selectedTab = 0;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        title: Text(l10n.legalTitle),
        centerTitle: true,
        backgroundColor: context.iosGroupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM, vertical: 12),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedTab,
              onValueChanged: (int? value) {
                if (value != null) setState(() => _selectedTab = value);
              },
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.legalTabPrivacy),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l10n.legalTabTerms),
                ),
              },
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _PrivacyPolicyTab(onLaunchUrl: _launchUrl)
                : _TermsOfServiceTab(onLaunchUrl: _launchUrl),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy Policy ────────────────────────────────────────────────────────

class _PrivacyPolicyTab extends StatelessWidget {
  const _PrivacyPolicyTab({required this.onLaunchUrl});

  final Future<void> Function(String url) onLaunchUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LegalHeader(
          title: l10n.legalPrivacyHeaderTitle,
          subtitle: l10n.legalPrivacyHeaderSubtitle,
          icon: CupertinoIcons.shield,
        ),
        const SizedBox(height: 20),

        _LegalSection(
          title: l10n.legalPrivacySection1Title,
          body: l10n.legalPrivacySection1Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection2Title,
          body: l10n.legalPrivacySection2Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection3Title,
          body: l10n.legalPrivacySection3Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection4Title,
          body: l10n.legalPrivacySection4Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection5Title,
          body: l10n.legalPrivacySection5Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection6Title,
          body: l10n.legalPrivacySection6Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection7Title,
          body: l10n.legalPrivacySection7Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection8Title,
          body: l10n.legalPrivacySection8Body,
        ),

        _LegalSection(
          title: l10n.legalPrivacySection9Title,
          body: l10n.legalPrivacySection9Body,
        ),

        const SizedBox(height: 8),
        _LegalLinkButton(
          label: l10n.legalLinkPrivacyWeb,
          url: 'https://split-genesis.app/privacy',
          onLaunchUrl: onLaunchUrl,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Terms of Service ──────────────────────────────────────────────────────

class _TermsOfServiceTab extends StatelessWidget {
  const _TermsOfServiceTab({required this.onLaunchUrl});

  final Future<void> Function(String url) onLaunchUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LegalHeader(
          title: l10n.legalTermsHeaderTitle,
          subtitle: l10n.legalTermsHeaderSubtitle,
          icon: CupertinoIcons.doc_text,
        ),
        const SizedBox(height: 20),

        _LegalSection(
          title: l10n.legalTermsSection1Title,
          body: l10n.legalTermsSection1Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection2Title,
          body: l10n.legalTermsSection2Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection3Title,
          body: l10n.legalTermsSection3Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection4Title,
          body: l10n.legalTermsSection4Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection5Title,
          body: l10n.legalTermsSection5Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection6Title,
          body: l10n.legalTermsSection6Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection7Title,
          body: l10n.legalTermsSection7Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection8Title,
          body: l10n.legalTermsSection8Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection9Title,
          body: l10n.legalTermsSection9Body,
        ),

        _LegalSection(
          title: l10n.legalTermsSection10Title,
          body: l10n.legalTermsSection10Body,
        ),

        const SizedBox(height: 8),
        _LegalLinkButton(
          label: l10n.legalLinkTermsWeb,
          url: 'https://split-genesis.app/terms',
          onLaunchUrl: onLaunchUrl,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkButton extends StatelessWidget {
  const _LegalLinkButton({
    required this.label,
    required this.url,
    required this.onLaunchUrl,
  });

  final String label;
  final String url;
  final Future<void> Function(String url) onLaunchUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      onPressed: () => onLaunchUrl(url),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_up_right_square, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
