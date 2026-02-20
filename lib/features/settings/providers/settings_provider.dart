import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'theme_mode';
const _kDefaultCurrency = 'default_currency';
const _kDisplayName = 'display_name';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_kThemeMode) ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }
}

final defaultCurrencyProvider =
    StateNotifierProvider<DefaultCurrencyNotifier, String>((ref) {
  return DefaultCurrencyNotifier();
});

class DefaultCurrencyNotifier extends StateNotifier<String> {
  DefaultCurrencyNotifier() : super('USD') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kDefaultCurrency) ?? 'USD';
  }

  Future<void> set(String currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultCurrency, currency);
  }
}

final displayNameProvider =
    StateNotifierProvider<DisplayNameNotifier, String>((ref) {
  return DisplayNameNotifier();
});

class DisplayNameNotifier extends StateNotifier<String> {
  DisplayNameNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kDisplayName) ?? '';
  }

  Future<void> set(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, name);
  }
}
