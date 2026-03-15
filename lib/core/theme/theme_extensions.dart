import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Convenience extension for dark-mode-aware color selection
extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// iOS-style grouped background (F2F2F7 light / true black OLED dark)
  Color get iosGroupedBackground =>
      isDark ? AppTheme.oledBlack : AppTheme.surfaceColor;

  /// iOS-style card / inset grouped row background (white light / 1C1C1E dark)
  Color get iosCardBackground =>
      isDark ? AppTheme.darkCard : Colors.white;

  /// Second-level card (white light / 2C2C2E dark)
  Color get iosCardHigherBackground =>
      isDark ? AppTheme.darkCardHigher : Colors.white;

  /// Separator color
  Color get iosSeparator =>
      isDark ? AppTheme.darkSeparator : const Color(0xFFE5E5EA);

  /// Secondary label color (per Apple HIG)
  Color get iosSecondaryLabel =>
      isDark ? const Color(0xFFAEAEB2) : const Color(0xFF6D6D72);
}
