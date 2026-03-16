// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String syncChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes synced',
      one: '1 change synced',
    );
    return '$_temp0';
  }

  @override
  String get recurringWeekly => 'Weekly';

  @override
  String get recurringBiweekly => 'Every 2 weeks';

  @override
  String get recurringMonthly => 'Monthly';

  @override
  String recurringNextExecution(String date) {
    return 'Next execution: $date';
  }
}
