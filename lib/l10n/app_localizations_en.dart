import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String syncChanges(int count) => count == 1 ? '1 change synced' : '$count changes synced';

  @override
  String get recurringWeekly => 'Weekly';

  @override
  String get recurringBiweekly => 'Every 2 weeks';

  @override
  String get recurringMonthly => 'Monthly';

  @override
  String recurringNextExecution(String date) => 'Next execution: $date';
}
