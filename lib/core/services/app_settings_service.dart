import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for persisted app settings.
abstract class AppSettingsKeys {
  static const simplifyDebts = 'app_settings_simplify_debts';
}

/// App-wide settings stored in SharedPreferences.
///
/// All settings are persisted locally and survive app restarts.
/// Default values match the product spec (simplify debts: ON).
class AppSettings {
  const AppSettings({
    this.simplifyDebts = true,
  });

  /// When `true` (default), the "Simplify Debts" algorithm minimises the
  /// number of transactions needed to settle all balances.
  ///
  /// Matches the behaviour of Splitwise / Tricount / Settle Up.
  /// Users can disable this in Settings to see raw pairwise debts instead.
  final bool simplifyDebts;

  AppSettings copyWith({bool? simplifyDebts}) {
    return AppSettings(
      simplifyDebts: simplifyDebts ?? this.simplifyDebts,
    );
  }
}

/// Riverpod notifier that loads/persists [AppSettings].
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      simplifyDebts: prefs.getBool(AppSettingsKeys.simplifyDebts) ?? true,
    );
  }

  /// Toggles the "Simplify Debts" setting and persists it.
  Future<void> setSimplifyDebts(bool value) async {
    state = state.copyWith(simplifyDebts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppSettingsKeys.simplifyDebts, value);
  }
}

/// Global provider for [AppSettings].
///
/// Usage:
/// ```dart
/// final settings = ref.watch(appSettingsProvider);
/// final simplify = settings.simplifyDebts; // bool
/// ```
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (_) => AppSettingsNotifier(),
);
