import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // iOS-inspired color palette
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color positiveColor = Color(0xFF34C759);
  static const Color negativeColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color surfaceColor = Color(0xFFF2F2F7); // iOS systemGroupedBackground

  // OLED Dark Mode colors — true black hierarchy
  static const Color oledBlack = Color(0xFF000000);      // OLED true black scaffold
  static const Color darkSurface = Color(0xFF0A0A0A);    // Near-black for main surfaces
  static const Color darkCard = Color(0xFF1C1C1E);       // iOS dark card (elevated)
  static const Color darkCardHigher = Color(0xFF2C2C2E); // Second-level cards
  static const Color darkSeparator = Color(0xFF38383A);  // Dividers / borders

  // Spacing constants
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;

  // Opacity constants (use with Color.withAlpha)
  static const double subtleAlpha = 80 / 255;
  static const double secondaryAlpha = 130 / 255;

  // Shared padding
  static const EdgeInsets horizontalPadding =
      EdgeInsets.symmetric(horizontal: 16);

  /// iOS-style subtle shadow for cards and containers
  static BoxDecoration iosCardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCard : Colors.white,
      borderRadius: BorderRadius.circular(13),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: surfaceColor,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.2),
        displayMedium:
            TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        displaySmall:
            TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
        headlineMedium:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
        titleSmall:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(fontSize: 17, height: 1.5),
        bodyMedium: TextStyle(fontSize: 15, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, height: 1.4),
        labelLarge:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.grey.shade200,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.dark,
        // OLED: true black surface/background
        surface: oledBlack,
        onSurface: Colors.white,
        surfaceContainer: darkCard,
        surfaceContainerHighest: darkCardHigher,
        surfaceContainerHigh: darkCard,
        surfaceContainerLow: darkSurface,
        surfaceContainerLowest: oledBlack,
        outline: darkSeparator,
        outlineVariant: const Color(0xFF2C2C2E),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: oledBlack,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: oledBlack,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: darkSeparator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: darkSeparator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.white),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.white),
        displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.white),
        headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Colors.white),
        titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Colors.white),
        titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.white),
        titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.white),
        bodyLarge:
            TextStyle(fontSize: 17, height: 1.5, color: Colors.white),
        bodyMedium:
            TextStyle(fontSize: 15, height: 1.5, color: Colors.white),
        bodySmall: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFFAEAEB2)), // iOS secondaryLabel
        labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: darkSeparator,
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: darkCard,
        side: BorderSide(color: darkSeparator),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: darkSeparator,
        labelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFF8E8E93),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withAlpha(50),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        barBackgroundColor: oledBlack,
        scaffoldBackgroundColor: oledBlack,
      ),
    );
  }
}
