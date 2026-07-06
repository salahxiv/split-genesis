// TODO(stitch): Friends-Domain (Models, DB v15, Sync) folgt in eigenem Plan.
// Aktuell nur Tab-Slot mit Stitch-Look – Empty State.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryLabel = isDark
        ? AppTheme.iosSecondaryLabel
        : const Color(0xFF6E6E73);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.friendsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(28),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.person_2_fill,
                  size: 44,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.friendsComingSoon,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.friendsComingSoonBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryLabel,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
