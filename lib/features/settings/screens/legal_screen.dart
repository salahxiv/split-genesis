import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_extensions.dart';

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
    return Scaffold(
      backgroundColor: context.iosGroupedBackground,
      appBar: AppBar(
        title: const Text('Legal'),
        centerTitle: true,
        backgroundColor: context.iosGroupedBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedTab,
              onValueChanged: (int? value) {
                if (value != null) setState(() => _selectedTab = value);
              },
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Privacy Policy'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Terms of Service'),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LegalHeader(
          title: 'Privacy Policy',
          subtitle: 'Last updated: March 2026',
          icon: CupertinoIcons.shield,
        ),
        const SizedBox(height: 20),

        _LegalSection(
          title: '1. Data Controller',
          body:
              'Split Genesis is operated by Salah AI Company ("we", "us", "our"). '
              'You can reach us at: legal@split-genesis.app\n\n'
              'As the responsible party within the meaning of the DSGVO (GDPR), '
              'we are committed to protecting your personal data.',
        ),

        _LegalSection(
          title: '2. What Data We Collect',
          body:
              'We collect the minimum data necessary to operate Split Genesis:\n\n'
              '• Account data: email address and display name (provided by you at sign-up)\n'
              '• Group data: group names, member lists, expense descriptions and amounts\n'
              '• Device data: device type and app version (for crash reporting only)\n'
              '• Usage data: anonymous feature usage statistics (no personal identifiers)\n\n'
              'We do NOT collect: location, contacts, microphone, camera, or advertising IDs.',
        ),

        _LegalSection(
          title: '3. Purpose and Legal Basis (Art. 6 DSGVO)',
          body:
              'Your data is processed for the following purposes:\n\n'
              '• To provide the expense-splitting service (Art. 6(1)(b) DSGVO — contract performance)\n'
              '• To sync data across your devices via Supabase (Art. 6(1)(b) DSGVO)\n'
              '• To detect and fix technical errors (Art. 6(1)(f) DSGVO — legitimate interest)\n\n'
              'We do not process your data for advertising or sell it to third parties.',
        ),

        _LegalSection(
          title: '4. Data Storage and Processors',
          body:
              'Your data is stored on Supabase infrastructure (PostgreSQL database) '
              'hosted in the EU (Frankfurt, Germany). Supabase B.V. acts as our data processor '
              'under a Data Processing Agreement (DPA) compliant with Art. 28 DSGVO.\n\n'
              'Crash reports are processed by our self-hosted Bugsink instance on Hetzner (Germany). '
              'No data is sent to third-party crash analytics providers.',
        ),

        _LegalSection(
          title: '5. Retention Period',
          body:
              'Account and expense data is retained for as long as your account is active. '
              'If you delete your account, all associated data (groups, expenses, members) '
              'is permanently deleted within 30 days.\n\n'
              'Anonymous usage statistics are retained for up to 12 months then auto-deleted.',
        ),

        _LegalSection(
          title: '6. Your Rights (Art. 15–22 DSGVO)',
          body:
              'You have the right to:\n\n'
              '• Access: request a copy of all data we hold about you (Art. 15)\n'
              '• Rectification: correct inaccurate data (Art. 16)\n'
              '• Erasure: delete your account and all data ("right to be forgotten", Art. 17)\n'
              '• Portability: export your data in machine-readable format (Art. 20)\n'
              '• Objection: object to processing based on legitimate interests (Art. 21)\n\n'
              'To exercise your rights, contact us at: legal@split-genesis.app\n\n'
              'You also have the right to lodge a complaint with your local supervisory authority '
              '(in Germany: the Datenschutzbeauftragter of your federal state).',
        ),

        _LegalSection(
          title: '7. How to Delete Your Account',
          body:
              'You can delete your account and all data at any time:\n\n'
              '1. Open Settings in Split Genesis\n'
              '2. Scroll to the bottom → "Delete Account"\n'
              '3. Confirm deletion — all data is queued for removal\n'
              '4. Complete deletion occurs within 30 days\n\n'
              'Alternatively, email us at legal@split-genesis.app with subject "Account Deletion Request".',
        ),

        _LegalSection(
          title: '8. Children\'s Privacy',
          body:
              'Split Genesis is not directed at children under 13 (EU: under 16). '
              'We do not knowingly collect data from children. '
              'If you believe a child has provided us data, contact us immediately.',
        ),

        _LegalSection(
          title: '9. Contact',
          body: 'Data protection questions: legal@split-genesis.app\n'
              'Response time: within 30 days as required by Art. 12 DSGVO.',
        ),

        const SizedBox(height: 8),
        _LegalLinkButton(
          label: 'Full Privacy Policy (Web)',
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LegalHeader(
          title: 'Terms of Service',
          subtitle: 'Effective: March 2026',
          icon: CupertinoIcons.doc_text,
        ),
        const SizedBox(height: 20),

        _LegalSection(
          title: '1. Acceptance',
          body:
              'By using Split Genesis, you agree to these Terms of Service. '
              'If you do not agree, do not use the app. '
              'These terms are governed by German law.',
        ),

        _LegalSection(
          title: '2. Service Description',
          body:
              'Split Genesis is an expense-splitting app that allows groups of people '
              'to track shared expenses and calculate who owes whom. '
              'The app is provided "as is" for personal, non-commercial use.',
        ),

        _LegalSection(
          title: '3. Account Responsibilities',
          body:
              '• You are responsible for maintaining the confidentiality of your account\n'
              '• You must provide accurate information during sign-up\n'
              '• You must not use the app for unlawful purposes\n'
              '• You must not attempt to reverse-engineer or disrupt the service\n'
              '• You are responsible for all activity under your account',
        ),

        _LegalSection(
          title: '4. User Content',
          body:
              'You retain ownership of all content you enter into Split Genesis (expense names, amounts, notes). '
              'By using the service, you grant us a limited license to store and process this content '
              'solely to provide the service to you and your group members.',
        ),

        _LegalSection(
          title: '5. Accuracy of Calculations',
          body:
              'Split Genesis performs expense calculations in good faith, but we cannot guarantee '
              'the accuracy of all calculations in all edge cases. '
              'Always verify important financial settlements independently. '
              'We are not liable for financial losses arising from incorrect calculations.',
        ),

        _LegalSection(
          title: '6. Service Availability',
          body:
              'We aim for high availability but do not guarantee 100% uptime. '
              'We may perform maintenance that causes temporary interruptions. '
              'We will notify users of planned downtime where possible.',
        ),

        _LegalSection(
          title: '7. Termination',
          body:
              'You may terminate your account at any time via Settings → Delete Account. '
              'We reserve the right to suspend or terminate accounts that violate these terms. '
              'Upon termination, your data is deleted per our Privacy Policy (30 days).',
        ),

        _LegalSection(
          title: '8. Limitation of Liability',
          body:
              'To the maximum extent permitted by applicable law, Split Genesis and Salah AI Company '
              'are not liable for indirect, incidental, or consequential damages. '
              'Our total liability is limited to amounts you paid to us in the past 12 months '
              '(or €50 if no payment was made).',
        ),

        _LegalSection(
          title: '9. Changes to Terms',
          body:
              'We may update these terms. Material changes will be notified in-app. '
              'Continued use after changes constitutes acceptance of the new terms.',
        ),

        _LegalSection(
          title: '10. Contact and Disputes',
          body:
              'For questions or disputes: legal@split-genesis.app\n\n'
              'Applicable law: Federal Republic of Germany\n'
              'Jurisdiction: Courts of Hamburg, Germany\n\n'
              'EU Online Dispute Resolution: https://ec.europa.eu/consumers/odr',
        ),

        const SizedBox(height: 8),
        _LegalLinkButton(
          label: 'Full Terms of Service (Web)',
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
            borderRadius: BorderRadius.circular(12),
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
