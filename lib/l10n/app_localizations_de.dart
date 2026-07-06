// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String syncChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen synchronisiert',
      one: '1 Änderung synchronisiert',
    );
    return '$_temp0';
  }

  @override
  String get recurringWeekly => 'Wöchentlich';

  @override
  String get recurringBiweekly => '2-wöchentl.';

  @override
  String get recurringMonthly => 'Monatlich';

  @override
  String recurringNextExecution(String date) {
    return 'Nächste Ausführung: $date';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get goBack => 'Zurück';

  @override
  String get joinGroupTitle => 'Gruppe beitreten';

  @override
  String get joinGroupScanHint =>
      'Richte die Kamera auf einen Split-Genesis-Gruppen-QR-Code';

  @override
  String get joinGroupTryScanner => 'QR-Scanner verwenden';

  @override
  String get joinGroupDefaultName => 'Gruppe';

  @override
  String joinGroupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String joinGroupNotFoundWithCode(String code) {
    return 'Keine Gruppe mit Code „$code“ gefunden';
  }

  @override
  String get joinGroupConnectionError =>
      'Keine Verbindung. Bitte prüfe deine Internetverbindung.';

  @override
  String get joinGroupNotFoundQr => 'Keine Gruppe zu diesem QR-Code gefunden.';

  @override
  String get joinGroupJoinFailed =>
      'Beitritt fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get joinGroupInvalidQr =>
      'Ungültiger QR-Code. Bitte scanne einen Split-Genesis-Gruppen-QR-Code.';

  @override
  String get joinGroupInvalidQrFormat => 'Ungültiges QR-Code-Format.';
}
