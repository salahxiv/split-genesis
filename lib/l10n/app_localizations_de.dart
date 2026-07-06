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

  @override
  String get groupDetailRenameGroupTitle => 'Gruppe umbenennen';

  @override
  String get groupDetailGroupNamePlaceholder => 'Gruppenname';

  @override
  String get groupDetailSave => 'Speichern';

  @override
  String groupDetailCsvExportSubject(String name) {
    return '$name – Ausgaben-Export';
  }

  @override
  String groupDetailCsvExportFailed(String error) {
    return 'CSV-Export fehlgeschlagen: $error';
  }

  @override
  String groupDetailPdfExportSubject(String name) {
    return '$name – Export';
  }

  @override
  String groupDetailPdfExportFailed(String error) {
    return 'PDF-Export fehlgeschlagen: $error';
  }

  @override
  String groupDetailShareText(String name, String code) {
    return 'Tritt meiner Gruppe „$name“ auf Split Genesis bei!\nTippe: splitgenesis://join/$code\nOder gib den Code ein: $code';
  }

  @override
  String groupDetailInviteTo(String name) {
    return 'Einladung zu „$name“';
  }

  @override
  String get groupDetailInviteCode => 'Beitrittscode';

  @override
  String get groupDetailCodeCopied => 'Code in die Zwischenablage kopiert';

  @override
  String get groupDetailCopyCode => 'Code kopieren';

  @override
  String get groupDetailShareInvite => 'Einladung teilen';

  @override
  String get groupDetailNeedTwoMembers =>
      'Mindestens 2 Mitglieder nötig, um eine Zahlung zu erfassen';

  @override
  String get groupDetailRecordPayment => 'Zahlung erfassen';

  @override
  String get groupDetailFrom => 'Von';

  @override
  String get groupDetailTo => 'An';

  @override
  String get groupDetailAmount => 'Betrag';

  @override
  String get groupDetailRecord => 'Erfassen';

  @override
  String get groupDetailUnknownMember => 'Unbekannt';

  @override
  String get groupDetailPaymentRecorded => 'Zahlung erfasst';

  @override
  String groupDetailPaymentError(String error) {
    return 'Fehler beim Erfassen der Zahlung: $error';
  }

  @override
  String get groupDetailAddMember => 'Mitglied hinzufügen';

  @override
  String get groupDetailName => 'Name';

  @override
  String get groupDetailAdd => 'Hinzufügen';

  @override
  String groupDetailMemberAdded(String name) {
    return '$name zur Gruppe hinzugefügt';
  }

  @override
  String get groupDetailAddExpense => 'Ausgabe hinzufügen';

  @override
  String get groupDetailMembers => 'Mitglieder';

  @override
  String get groupDetailStatistics => 'Statistik';

  @override
  String get groupDetailRename => 'Umbenennen';

  @override
  String get groupDetailExportCsv => 'CSV exportieren';

  @override
  String get groupDetailExportPdf => 'PDF exportieren';

  @override
  String get groupDetailExpensesTab => 'Ausgaben';

  @override
  String get groupDetailBalancesTab => 'Schulden';

  @override
  String get groupDetailActivityTab => 'Aktivität';

  @override
  String get groupDetailTotalYouAreOwed => 'Du bekommst insgesamt';

  @override
  String get groupDetailTotalYouOwe => 'Du schuldest insgesamt';

  @override
  String get groupDetailAllSettled => 'Alles ausgeglichen';

  @override
  String get groupDetailToday => 'Heute';

  @override
  String get groupDetailYesterday => 'Gestern';

  @override
  String get groupDetailYouAreOwed => 'Du bekommst';

  @override
  String get groupDetailYouOwe => 'Du schuldest';

  @override
  String get groupDetailFilterExpenses => 'Ausgaben filtern';

  @override
  String get groupDetailCategory => 'Kategorie';

  @override
  String get groupDetailAll => 'Alle';

  @override
  String get groupDetailPaidBy => 'Bezahlt von';

  @override
  String get groupDetailDateRange => 'Zeitraum';

  @override
  String get groupDetailAllTime => 'Gesamter Zeitraum';

  @override
  String groupDetailDateRangeValue(String start, String end) {
    return '$start — $end';
  }

  @override
  String get groupDetailClearDateFilter => 'Datumsfilter entfernen';

  @override
  String get groupDetailResetAllFilters => 'Alle Filter zurücksetzen';

  @override
  String get groupDetailNoExpenses => 'Noch keine Ausgaben';

  @override
  String get groupDetailFirstExpense => 'Erste Ausgabe hinzufügen';

  @override
  String get groupDetailSearchExpenses => 'Ausgaben suchen…';

  @override
  String get groupDetailFilter => 'Filter';

  @override
  String groupDetailFilteredCount(int count, int total) {
    return '$count von $total Ausgaben';
  }

  @override
  String get groupDetailClear => 'Zurücksetzen';

  @override
  String get groupDetailSwipeHint =>
      'Wische eine Ausgabe nach links, um sie zu löschen';

  @override
  String get groupDetailGotIt => 'Verstanden';

  @override
  String get groupDetailNoMatchingExpenses => 'Keine passenden Ausgaben';

  @override
  String get groupDetailDeleteExpenseTitle => 'Ausgabe löschen';

  @override
  String groupDetailDeleteExpenseMessage(String description, String amount) {
    return '„$description“ ($amount) wird dauerhaft gelöscht.';
  }

  @override
  String groupDetailPaidByName(String name) {
    return 'Bezahlt von $name';
  }

  @override
  String get groupDetailWhoOwesWhom => 'WER SCHULDET WEM';

  @override
  String get groupDetailNoBalances => 'Keine Salden vorhanden';

  @override
  String get groupDetailDebtsSimplified =>
      'Schulden vereinfacht — automatische Verrechnung aktiv.';

  @override
  String get groupDetailSettleUp => 'Ausgleichen';

  @override
  String get legalTitle => 'Rechtliches';

  @override
  String get legalTabPrivacy => 'Datenschutz';

  @override
  String get legalTabTerms => 'Nutzungsbedingungen';

  @override
  String get legalPrivacyHeaderTitle => 'Datenschutzerklärung';

  @override
  String get legalPrivacyHeaderSubtitle => 'Zuletzt aktualisiert: März 2026';

  @override
  String get legalPrivacySection1Title => '1. Verantwortlicher';

  @override
  String get legalPrivacySection1Body =>
      'Split Genesis wird von der Salah AI Company betrieben („wir“, „uns“, „unser“). Sie erreichen uns unter: legal@split-genesis.app\n\nAls Verantwortlicher im Sinne der DSGVO (GDPR) verpflichten wir uns, Ihre personenbezogenen Daten zu schützen.';

  @override
  String get legalPrivacySection2Title => '2. Welche Daten wir erheben';

  @override
  String get legalPrivacySection2Body =>
      'Wir erheben nur die zum Betrieb von Split Genesis unbedingt erforderlichen Daten:\n\n• Kontodaten: E-Mail-Adresse und Anzeigename (von Ihnen bei der Registrierung angegeben)\n• Gruppendaten: Gruppennamen, Mitgliederlisten, Ausgabenbeschreibungen und Beträge\n• Gerätedaten: Gerätetyp und App-Version (ausschließlich zur Fehlerberichterstattung)\n• Nutzungsdaten: anonyme Statistiken zur Funktionsnutzung (keine personenbezogenen Kennungen)\n\nWir erheben NICHT: Standort, Kontakte, Mikrofon, Kamera oder Werbe-IDs.';

  @override
  String get legalPrivacySection3Title =>
      '3. Zweck und Rechtsgrundlage (Art. 6 DSGVO)';

  @override
  String get legalPrivacySection3Body =>
      'Ihre Daten werden für folgende Zwecke verarbeitet:\n\n• Zur Bereitstellung des Dienstes zum Teilen von Ausgaben (Art. 6(1)(b) DSGVO — Vertragserfüllung)\n• Zur Synchronisierung Ihrer Daten über Ihre Geräte hinweg via Supabase (Art. 6(1)(b) DSGVO)\n• Zur Erkennung und Behebung technischer Fehler (Art. 6(1)(f) DSGVO — berechtigtes Interesse)\n\nWir verarbeiten Ihre Daten nicht zu Werbezwecken und verkaufen sie nicht an Dritte.';

  @override
  String get legalPrivacySection4Title =>
      '4. Datenspeicherung und Auftragsverarbeiter';

  @override
  String get legalPrivacySection4Body =>
      'Ihre Daten werden auf der Supabase-Infrastruktur (PostgreSQL-Datenbank) gespeichert, die in der EU (Frankfurt, Deutschland) gehostet wird. Die Supabase B.V. handelt als unser Auftragsverarbeiter auf Grundlage eines Auftragsverarbeitungsvertrags (AVV) gemäß Art. 28 DSGVO.\n\nAbsturzberichte werden von unserer selbst gehosteten Bugsink-Instanz auf Hetzner (Deutschland) verarbeitet. Es werden keine Daten an Drittanbieter für Absturzanalysen übermittelt.';

  @override
  String get legalPrivacySection5Title => '5. Speicherdauer';

  @override
  String get legalPrivacySection5Body =>
      'Konto- und Ausgabendaten werden so lange gespeichert, wie Ihr Konto aktiv ist. Wenn Sie Ihr Konto löschen, werden alle zugehörigen Daten (Gruppen, Ausgaben, Mitglieder) innerhalb von 30 Tagen dauerhaft gelöscht.\n\nAnonyme Nutzungsstatistiken werden bis zu 12 Monate gespeichert und danach automatisch gelöscht.';

  @override
  String get legalPrivacySection6Title => '6. Ihre Rechte (Art. 15–22 DSGVO)';

  @override
  String get legalPrivacySection6Body =>
      'Sie haben das Recht auf:\n\n• Auskunft: eine Kopie aller Daten anzufordern, die wir über Sie speichern (Art. 15)\n• Berichtigung: unrichtige Daten korrigieren zu lassen (Art. 16)\n• Löschung: Ihr Konto und alle Daten zu löschen („Recht auf Vergessenwerden“, Art. 17)\n• Datenübertragbarkeit: Ihre Daten in einem maschinenlesbaren Format zu exportieren (Art. 20)\n• Widerspruch: der Verarbeitung auf Grundlage berechtigter Interessen zu widersprechen (Art. 21)\n\nUm Ihre Rechte auszuüben, kontaktieren Sie uns unter: legal@split-genesis.app\n\nSie haben zudem das Recht, eine Beschwerde bei Ihrer zuständigen Aufsichtsbehörde einzureichen (in Deutschland: der bzw. die Datenschutzbeauftragte Ihres Bundeslandes).';

  @override
  String get legalPrivacySection7Title => '7. So löschen Sie Ihr Konto';

  @override
  String get legalPrivacySection7Body =>
      'Sie können Ihr Konto und alle Daten jederzeit löschen:\n\n1. Öffnen Sie die Einstellungen in Split Genesis\n2. Scrollen Sie nach ganz unten → „Konto löschen“\n3. Bestätigen Sie die Löschung — alle Daten werden zur Entfernung vorgemerkt\n4. Die vollständige Löschung erfolgt innerhalb von 30 Tagen\n\nAlternativ senden Sie uns eine E-Mail an legal@split-genesis.app mit dem Betreff „Antrag auf Kontolöschung“.';

  @override
  String get legalPrivacySection8Title => '8. Datenschutz für Kinder';

  @override
  String get legalPrivacySection8Body =>
      'Split Genesis richtet sich nicht an Kinder unter 13 Jahren (EU: unter 16 Jahren). Wir erheben nicht wissentlich Daten von Kindern. Wenn Sie glauben, dass ein Kind uns Daten übermittelt hat, kontaktieren Sie uns bitte umgehend.';

  @override
  String get legalPrivacySection9Title => '9. Kontakt';

  @override
  String get legalPrivacySection9Body =>
      'Fragen zum Datenschutz: legal@split-genesis.app\nAntwortzeit: innerhalb von 30 Tagen gemäß Art. 12 DSGVO.';

  @override
  String get legalLinkPrivacyWeb => 'Vollständige Datenschutzerklärung (Web)';

  @override
  String get legalTermsHeaderTitle => 'Nutzungsbedingungen';

  @override
  String get legalTermsHeaderSubtitle => 'Gültig ab: März 2026';

  @override
  String get legalTermsSection1Title => '1. Annahme';

  @override
  String get legalTermsSection1Body =>
      'Durch die Nutzung von Split Genesis stimmen Sie diesen Nutzungsbedingungen zu. Wenn Sie nicht einverstanden sind, nutzen Sie die App nicht. Diese Bedingungen unterliegen deutschem Recht.';

  @override
  String get legalTermsSection2Title => '2. Leistungsbeschreibung';

  @override
  String get legalTermsSection2Body =>
      'Split Genesis ist eine App zum Teilen von Ausgaben, die es Personengruppen ermöglicht, gemeinsame Ausgaben zu erfassen und zu berechnen, wer wem etwas schuldet. Die App wird „wie besehen“ für den persönlichen, nicht-kommerziellen Gebrauch bereitgestellt.';

  @override
  String get legalTermsSection3Title => '3. Pflichten des Kontoinhabers';

  @override
  String get legalTermsSection3Body =>
      '• Sie sind für die Vertraulichkeit Ihres Kontos verantwortlich\n• Sie müssen bei der Registrierung zutreffende Angaben machen\n• Sie dürfen die App nicht für rechtswidrige Zwecke nutzen\n• Sie dürfen nicht versuchen, den Dienst zurückzuentwickeln (Reverse Engineering) oder zu stören\n• Sie sind für sämtliche Aktivitäten unter Ihrem Konto verantwortlich';

  @override
  String get legalTermsSection4Title => '4. Nutzerinhalte';

  @override
  String get legalTermsSection4Body =>
      'Sie behalten das Eigentum an allen Inhalten, die Sie in Split Genesis eingeben (Ausgabenbezeichnungen, Beträge, Notizen). Durch die Nutzung des Dienstes gewähren Sie uns eine eingeschränkte Lizenz, diese Inhalte zu speichern und zu verarbeiten, ausschließlich um den Dienst für Sie und Ihre Gruppenmitglieder bereitzustellen.';

  @override
  String get legalTermsSection5Title => '5. Richtigkeit der Berechnungen';

  @override
  String get legalTermsSection5Body =>
      'Split Genesis führt Ausgabenberechnungen nach bestem Wissen durch, wir können jedoch nicht die Richtigkeit aller Berechnungen in allen Sonderfällen garantieren. Überprüfen Sie wichtige finanzielle Ausgleiche stets unabhängig. Wir haften nicht für finanzielle Verluste, die aus fehlerhaften Berechnungen entstehen.';

  @override
  String get legalTermsSection6Title => '6. Verfügbarkeit des Dienstes';

  @override
  String get legalTermsSection6Body =>
      'Wir streben eine hohe Verfügbarkeit an, garantieren jedoch keine Betriebszeit von 100 %. Wir können Wartungsarbeiten durchführen, die zu vorübergehenden Unterbrechungen führen. Wir werden die Nutzer nach Möglichkeit über geplante Ausfallzeiten informieren.';

  @override
  String get legalTermsSection7Title => '7. Kündigung';

  @override
  String get legalTermsSection7Body =>
      'Sie können Ihr Konto jederzeit über Einstellungen → Konto löschen kündigen. Wir behalten uns das Recht vor, Konten, die gegen diese Bedingungen verstoßen, zu sperren oder zu kündigen. Nach der Kündigung werden Ihre Daten gemäß unserer Datenschutzerklärung (innerhalb von 30 Tagen) gelöscht.';

  @override
  String get legalTermsSection8Title => '8. Haftungsbeschränkung';

  @override
  String get legalTermsSection8Body =>
      'Soweit nach geltendem Recht zulässig, haften Split Genesis und die Salah AI Company nicht für indirekte, beiläufig entstandene oder Folgeschäden. Unsere Gesamthaftung ist auf die Beträge beschränkt, die Sie in den vergangenen 12 Monaten an uns gezahlt haben (oder €50, falls keine Zahlung erfolgt ist).';

  @override
  String get legalTermsSection9Title => '9. Änderungen der Bedingungen';

  @override
  String get legalTermsSection9Body =>
      'Wir können diese Bedingungen aktualisieren. Über wesentliche Änderungen werden wir Sie in der App informieren. Die weitere Nutzung nach Änderungen gilt als Annahme der neuen Bedingungen.';

  @override
  String get legalTermsSection10Title => '10. Kontakt und Streitigkeiten';

  @override
  String get legalTermsSection10Body =>
      'Bei Fragen oder Streitigkeiten: legal@split-genesis.app\n\nAnwendbares Recht: Bundesrepublik Deutschland\nGerichtsstand: Gerichte in Hamburg, Deutschland\n\nEU-Online-Streitbeilegung: https://ec.europa.eu/consumers/odr';

  @override
  String get legalLinkTermsWeb => 'Vollständige Nutzungsbedingungen (Web)';

  @override
  String get settleUpTitle => 'Ausgleichen';

  @override
  String get settleUpOutstandingDebts => 'Offene Schulden';

  @override
  String settleUpLoadError(String error) {
    return 'Fehler beim Laden: $error';
  }

  @override
  String get settleUpTryAgain => 'Erneut versuchen';

  @override
  String get settleUpAllSettledTitle => 'Alles ausgeglichen!';

  @override
  String settleUpNoDebtsIn(String groupName) {
    return 'Keine offenen Schulden in „$groupName“';
  }

  @override
  String get settleUpBackToGroup => 'Zurück zur Gruppe';

  @override
  String settleUpOpenCount(int count) {
    return 'Offen: $count';
  }

  @override
  String settleUpTotal(String amount) {
    return 'Gesamt: $amount';
  }

  @override
  String get settleUpSettleAllTitle => 'Alle ausgleichen';

  @override
  String settleUpSettleAllMessage(int count) {
    return 'Alle $count Schulden als beglichen markieren? Das aktualisiert die Gruppensalden.';
  }

  @override
  String settleUpSettleAllAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schulden ausgleichen',
      one: '1 Schuld ausgleichen',
    );
    return '$_temp0';
  }

  @override
  String settleUpPartialPaidSnack(String from, String amount, String to) {
    return '$from zahlte $amount (Teilbetrag) an $to';
  }

  @override
  String settleUpSettledSnack(String from, String amount, String to) {
    return '$from hat $amount mit $to ausgeglichen';
  }

  @override
  String get settleUpOwes => 'schuldet';

  @override
  String get settleUpAmount => 'Betrag';

  @override
  String get settleUpAmountMustBePositive => 'Betrag muss größer als 0 sein';

  @override
  String settleUpCannotExceed(String amount) {
    return 'Darf $amount nicht überschreiten';
  }

  @override
  String settleUpOwesTo(String from, String to) {
    return '$from schuldet $to';
  }

  @override
  String settleUpOfTotal(String amount) {
    return 'von $amount Gesamtschuld';
  }

  @override
  String get settleUpSettleFull => 'Voll ausgleichen';

  @override
  String get settleUpPaymentMethod => 'Zahlungsmethode';

  @override
  String get settleUpBankTransfer => 'Bankverbindung';

  @override
  String get settleUpBankTransferComingSoon => 'Bankverbindung: kommt bald';

  @override
  String get settleUpChange => 'Ändern';

  @override
  String settleUpConfirmPaymentAmount(String amount) {
    return 'Zahlung bestätigen ($amount)';
  }

  @override
  String get settleUpConfirmPayment => 'Zahlung bestätigen';

  @override
  String get settleUpMarkedImmediately =>
      'Der Betrag wird sofort als beglichen markiert.';

  @override
  String get expenseDetailYou => 'Du';

  @override
  String get expenseDetailUnknown => 'Unbekannt';

  @override
  String get expenseDetailTitle => 'Ausgabendetails';

  @override
  String get expenseDetailPaidBy => 'Bezahlt von';

  @override
  String get expenseDetailDate => 'Datum';

  @override
  String get expenseDetailCategory => 'Kategorie';

  @override
  String get expenseDetailSplitDetails => 'Aufteilung';

  @override
  String get expenseDetailReceipt => 'Beleg';

  @override
  String get expenseDetailReceiptLoadError =>
      'Beleg konnte nicht geladen werden';

  @override
  String get expenseDetailComments => 'Kommentare';

  @override
  String get expenseDetailBeFirstComment => 'Sei der Erste, der kommentiert';

  @override
  String get expenseDetailAddCommentHint => 'Kommentar hinzufügen …';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String get activityEmpty => 'Noch keine Aktivität';

  @override
  String get activityEmptyCreateGroup => 'Erstelle eine Gruppe, um loszulegen';

  @override
  String get activityEmptyHint => 'Aktionen erscheinen hier';

  @override
  String get activityJustNow => 'Gerade eben';

  @override
  String activityMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String activityHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String activityDaysAgo(int count) {
    return 'vor $count Tg.';
  }

  @override
  String get activityYesterday => 'Gestern';

  @override
  String get activityToday => 'Heute';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsYourNameHint => 'Dein Name';

  @override
  String get settingsTapToSetName => 'Tippen, um deinen Namen festzulegen';

  @override
  String get settingsDisplayName => 'Anzeigename';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsDefaultCurrency => 'Standardwährung';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsCurrencyHelp =>
      'Wird als Standard beim Erstellen neuer Ausgaben verwendet.';

  @override
  String get settingsAboutHeader => 'Info';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get settingsAboutRow => 'Über die App';

  @override
  String get settingsPrivacyTerms => 'Datenschutz & Nutzungsbedingungen';

  @override
  String get settingsBuiltWithFlutter => 'Mit Flutter entwickelt';

  @override
  String get settingsMadeWithLove => 'Mit Liebe gemacht';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutCopyright =>
      '© 2026 Split Genesis. Alle Rechte vorbehalten.';

  @override
  String get settingsAboutClose => 'Schließen';

  @override
  String get groupSettingsTitle => 'Gruppen-Einstellungen';

  @override
  String get groupSettingsRenameTitle => 'Name ändern';

  @override
  String get groupSettingsNameHint => 'Gruppenname';

  @override
  String get groupSettingsSave => 'Speichern';

  @override
  String get groupSettingsChooseSymbol => 'Symbol wählen';

  @override
  String get groupSettingsSymbolComingSoon =>
      'Symbol speichern: in Kürze verfügbar';

  @override
  String get groupSettingsCurrencyComingSoon =>
      'Währungsänderung: in Kürze verfügbar';

  @override
  String get groupSettingsLeaveTitle => 'Gruppe verlassen?';

  @override
  String get groupSettingsLeaveMessage =>
      'Du wirst aus der Mitgliederliste entfernt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get groupSettingsLeave => 'Verlassen';

  @override
  String get groupSettingsNotMember => 'Du bist kein Mitglied dieser Gruppe.';

  @override
  String get groupSettingsDeleteTitle => 'Gruppe löschen?';

  @override
  String get groupSettingsDeleteMessage =>
      'Alle Ausgaben, Mitglieder und Aktivitäten dieser Gruppe werden gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get groupSettingsName => 'Name';

  @override
  String get groupSettingsSymbol => 'Symbol';

  @override
  String get groupSettingsCurrency => 'Währung';

  @override
  String get groupSettingsManageMembers => 'Mitglieder verwalten';

  @override
  String get groupSettingsLeaveGroup => 'Gruppe verlassen';

  @override
  String get groupSettingsDeleteGroup => 'Gruppe löschen';

  @override
  String get accountYou => 'Du';

  @override
  String get accountTitle => 'Konto';

  @override
  String accountDefaultCurrency(String currency) {
    return 'Standardwährung: $currency';
  }

  @override
  String get accountMyStats => 'MEINE STATISTIKEN';

  @override
  String get accountTotalSpent => 'Gesamt ausgegeben';

  @override
  String get accountTotalSettled => 'Gesamt ausgeglichen';

  @override
  String get accountSettings => 'Einstellungen';

  @override
  String get accountPersonalData => 'Persönliche Daten';

  @override
  String get accountNotifications => 'Benachrichtigungen';

  @override
  String get accountBankDetails => 'Bankverbindung';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String accountComingSoon(String feature) {
    return '$feature: kommt bald';
  }

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsComingSoon => 'Bald verfügbar';

  @override
  String get friendsComingSoonBody =>
      'Bald kannst du Freund:innen hinzufügen und auch ohne Gruppe abrechnen.';

  @override
  String get addExpenseTitle => 'Neue Ausgabe';

  @override
  String get addExpenseEditTitle => 'Ausgabe bearbeiten';

  @override
  String get addExpenseWhatFor => 'Wofür?';

  @override
  String get addExpensePaidBy => 'Bezahlt von';

  @override
  String get addExpenseSave => 'Speichern';

  @override
  String get addExpenseMoreDetails => 'Mehr Details';

  @override
  String get addExpenseCategoryLabel => 'Kategorie';

  @override
  String get addExpenseCategorySection => 'KATEGORIE';

  @override
  String get addExpenseSplitTypeLabel => 'Aufteilungsart';

  @override
  String get addExpenseSplitEqual => 'Gleich';

  @override
  String get addExpenseSplitExact => 'Exakt';

  @override
  String get addExpenseSplitShares => 'Anteile';

  @override
  String get addExpenseSplitAmong => 'Aufteilen zwischen';

  @override
  String get addExpenseSplitLabel => 'Aufteilen';

  @override
  String get addExpenseSelectAll => 'Alle auswählen';

  @override
  String get addExpenseDeselectAll => 'Alle abwählen';

  @override
  String get addExpenseCategorySelectedHint => 'Ausgewählte Kategorie';

  @override
  String get addExpenseCategorySelectHint => 'Zum Auswählen tippen';

  @override
  String get addExpenseDescriptionRequired => 'Bitte gib eine Beschreibung ein';

  @override
  String get addExpenseAmountRequired => 'Bitte gib einen Betrag ein';

  @override
  String get addExpensePayerRequired => 'Bitte wähle, wer bezahlt hat';

  @override
  String get addExpenseSplitMembersRequired =>
      'Bitte wähle Mitglieder zum Aufteilen';

  @override
  String get addExpenseSelectPersonRequired =>
      'Bitte wähle mindestens eine Person';

  @override
  String addExpenseExactSumError(String amount) {
    return 'Beträge müssen sich auf $amount addieren';
  }

  @override
  String get addExpensePercentSumError =>
      'Prozente müssen sich auf 100% addieren';

  @override
  String get addExpenseSharesError => 'Bitte gib gültige Anteile ein';

  @override
  String addExpenseSaveError(String error) {
    return 'Fehler beim Speichern der Ausgabe: $error';
  }

  @override
  String addExpenseError(String error) {
    return 'Fehler: $error';
  }

  @override
  String addExpenseLoadError(String error) {
    return 'Fehler beim Laden: $error';
  }

  @override
  String get addExpenseRetry => 'Erneut versuchen';

  @override
  String get addExpenseApply => 'Übernehmen';

  @override
  String addExpensePerPerson(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$amount pro Person ($_temp0)';
  }

  @override
  String addExpenseAmountRemaining(String amount) {
    return '$amount übrig';
  }

  @override
  String addExpenseAmountOver(String amount) {
    return '$amount zu viel';
  }

  @override
  String get addExpenseAmountsMatch => 'Beträge stimmen';

  @override
  String get addExpensePercentagesMatch => 'Prozente stimmen (100%)';

  @override
  String addExpenseTotalShares(String shares) {
    return 'Anteile gesamt: $shares';
  }

  @override
  String get addExpenseRecurring => 'Wiederkehrend';

  @override
  String get addExpenseCustomizeSplit => 'Split anpassen →';

  @override
  String get addExpenseCustomizeSplitSoon =>
      'Split anpassen: in Kürze verfügbar';

  @override
  String get addExpenseDateToday => 'Heute';

  @override
  String get addExpenseDateYesterday => 'Gestern';

  @override
  String get addExpenseCategoryMore => 'Mehr';

  @override
  String get addExpenseCategoryFood => 'Essen';

  @override
  String get addExpenseCategoryGroceries => 'Einkauf';

  @override
  String get addExpenseCategoryTravel => 'Reise';

  @override
  String get memberDetailLoadError =>
      'Mitgliederdetails konnten nicht geladen werden';

  @override
  String get memberDetailTransactionHistory => 'Transaktionsverlauf';

  @override
  String get memberDetailNoTransactions => 'Noch keine Transaktionen';

  @override
  String get memberDetailGetsBack => 'bekommt';

  @override
  String get memberDetailOwes => 'schuldet';

  @override
  String get memberDetailStatPaidFor => 'Bezahlt für';

  @override
  String get memberDetailStatInvolvedIn => 'Beteiligt an';

  @override
  String get memberDetailStatSettlements => 'Ausgleiche';

  @override
  String memberDetailYouPaid(String amount) {
    return 'Du hast $amount bezahlt';
  }

  @override
  String memberDetailYourShare(String amount) {
    return 'Dein Anteil $amount';
  }

  @override
  String memberDetailPaymentFrom(String name) {
    return 'Zahlung von $name';
  }

  @override
  String memberDetailPaymentTo(String name) {
    return 'Zahlung an $name';
  }

  @override
  String get memberDetailReceived => 'Erhalten';

  @override
  String get memberDetailSent => 'Gesendet';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsFilterThisMonth => 'Dieser Monat';

  @override
  String get statsFilterAll => 'Alles';

  @override
  String get statsErrorStatistics => 'Fehler beim Laden der Statistik';

  @override
  String get statsErrorPayerData => 'Fehler beim Laden der Zahlerdaten';

  @override
  String get statsErrorMemberData => 'Fehler beim Laden der Mitgliederdaten';

  @override
  String get statsEmptyTitle => 'Noch keine Ausgaben';

  @override
  String get statsTotalGroupSpend => 'Gesamtausgaben der Gruppe';

  @override
  String statsExpensesRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben erfasst',
      one: '1 Ausgabe erfasst',
    );
    return '$_temp0';
  }

  @override
  String get statsByCategory => 'Nach Kategorie';

  @override
  String get statsMonthlySpending => 'Monatliche Ausgaben';

  @override
  String get statsPerMemberPaid => 'Pro Mitglied bezahlt';

  @override
  String get statsUnknownMember => 'Unbekannt';

  @override
  String get manageMembersTitle => 'Mitglieder';

  @override
  String get manageMembersAddSection => 'MITGLIED HINZUFÜGEN';

  @override
  String get manageMembersNamePlaceholder => 'Name des neuen Mitglieds…';

  @override
  String get manageMembersMembersSection => 'MITGLIEDER';

  @override
  String get manageMembersEmpty => 'Noch keine Mitglieder';

  @override
  String get manageMembersSwipeHint =>
      'Zum Entfernen eines Mitglieds nach links wischen.';

  @override
  String get manageMembersRemoveTitle => 'Mitglied entfernen';

  @override
  String manageMembersRemoveMessage(String name) {
    return '„$name“ aus dieser Gruppe entfernen?';
  }

  @override
  String get manageMembersRemoveAction => 'Entfernen';

  @override
  String manageMembersCannotRemove(String name) {
    return '$name kann nicht entfernt werden — verknüpfte Ausgaben vorhanden';
  }
}
