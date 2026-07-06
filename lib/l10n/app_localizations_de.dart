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

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei\nSplitty';

  @override
  String get onboardingWelcomeSubtitle =>
      'Teile Ausgaben mit Freunden –\neinfach und fair.';

  @override
  String get onboardingGetStarted => 'Los geht’s';

  @override
  String get onboardingWelcomeFootnote =>
      'Kostenlos · Kein Konto nötig · Funktioniert offline';

  @override
  String get onboardingSettleTitle => 'Faire Abrechnungen,\nimmer';

  @override
  String get onboardingSettleSubtitle =>
      'Wir behalten genau im Blick, wer wem was schuldet –\nbeim Abrechnen zahlt jeder fair.';

  @override
  String get onboardingFeatureSimplify => 'Automatische Schuldenvereinfachung';

  @override
  String get onboardingFeatureOffline =>
      'Funktioniert offline, synchronisiert automatisch';

  @override
  String get onboardingFeaturePrivate => 'Deine Daten bleiben privat';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingDiagramOtherApps => 'ANDERE APPS';

  @override
  String get onboardingDiagramBeforeCaption =>
      'A schuldet B, B schuldet C – verwirrend!';

  @override
  String get onboardingDiagramAfterCaption => 'A zahlt direkt an C. Fertig. ✓';

  @override
  String get onboardingNameTitle => 'Wie heißt du?';

  @override
  String get onboardingNameSubtitle =>
      'Damit deine Freunde wissen, wer du bist.';

  @override
  String get onboardingNamePlaceholder => 'Dein Name';

  @override
  String get delete => 'Löschen';

  @override
  String get balanceSettled => 'Ausgeglichen';

  @override
  String get homeJoinCodePlaceholder => 'z. B. A1B2C3D4';

  @override
  String get homeJoinAction => 'Beitreten';

  @override
  String get homeGroupNotFoundByCode => 'Keine Gruppe mit diesem Code gefunden';

  @override
  String get homeJoinTooltip => 'Gruppe beitreten';

  @override
  String get homeNewGroupTooltip => 'Neue Gruppe';

  @override
  String get homeEmptyTitle => 'Noch keine Gruppen';

  @override
  String get homeEmptySubtitle => 'Erstelle eine Gruppe, um Ausgaben zu teilen';

  @override
  String get homeCreateFirstGroup => 'Erste Gruppe anlegen';

  @override
  String get homeCreateNewGroup => 'Neue Gruppe anlegen';

  @override
  String get homeDeleteGroupTitle => 'Gruppe löschen';

  @override
  String homeDeleteGroupMessage(String name) {
    return '„$name“ und alle Ausgaben löschen? Kann nicht rückgängig gemacht werden.';
  }

  @override
  String homePersonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String get addGroupTitle => 'Neue Gruppe';

  @override
  String get addGroupCreate => 'Anlegen';

  @override
  String get addGroupErrorMinMembers => 'Füge mindestens 2 Mitglieder hinzu';

  @override
  String addGroupErrorCreate(String error) {
    return 'Fehler beim Anlegen der Gruppe: $error';
  }

  @override
  String get addGroupSelectCurrency => 'Währung wählen';

  @override
  String get addGroupSectionName => 'GRUPPENNAME';

  @override
  String get addGroupNamePlaceholder => 'Wochenendtrip, Miete, …';

  @override
  String get addGroupSectionType => 'TYP';

  @override
  String get addGroupSectionCurrency => 'WÄHRUNG';

  @override
  String get addGroupCurrency => 'Währung';

  @override
  String get addGroupSectionMembers => 'MITGLIEDER';

  @override
  String addGroupMembersAdded(int count) {
    return '$count hinzugefügt';
  }

  @override
  String get addGroupMemberPlaceholder => 'Name des Mitglieds…';

  @override
  String get addGroupHintMinMembers =>
      'Füge mindestens 2 Mitglieder hinzu, um eine Gruppe zu erstellen.';

  @override
  String get addGroupHintOneMore => 'Füge noch ein Mitglied hinzu.';

  @override
  String get addGroupCreatedTitle => 'Gruppe erstellt';

  @override
  String get addGroupOpen => 'Öffnen';

  @override
  String get addGroupInviteHint =>
      'Lade andere ein, indem du den QR-Code oder den Beitrittscode unten teilst.';

  @override
  String get addGroupCodeCopied => 'Code kopiert!';

  @override
  String get addGroupOpenGroup => 'Gruppe öffnen';
}
