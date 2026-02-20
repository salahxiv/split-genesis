import 'package:flutter/material.dart';

class AppTheme {
  // iOS-inspired color palette
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color positiveColor = Color(0xFF34C759);
  static const Color negativeColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color surfaceColor = Color(0xFFF9F9F9);

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
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
    const darkSurface = Color(0xFF1C1C1E);
    const darkCard = Color(0xFF2C2C2E);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: darkSurface,
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
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        color: Colors.grey.shade800,
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
        dividerColor: Colors.grey.shade800,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
