import 'app_localizations.dart';

class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe() : super('de');

  @override
  String syncChanges(int count) =>
      count == 1 ? '1 Änderung synchronisiert' : '$count Änderungen synchronisiert';

  @override
  String get recurringWeekly => 'Wöchentlich';

  @override
  String get recurringBiweekly => '2-wöchentl.';

  @override
  String get recurringMonthly => 'Monatlich';

  @override
  String recurringNextExecution(String date) => 'Nächste Ausführung: $date';
}
