import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Snackbar shown after offline queue sync flush
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change synced} other{{count} changes synced}}'**
  String syncChanges(int count);

  /// Recurring expense interval: every week
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringWeekly;

  /// Recurring expense interval: every 2 weeks
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get recurringBiweekly;

  /// Recurring expense interval: every month
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringMonthly;

  /// Label showing next scheduled execution date
  ///
  /// In en, this message translates to:
  /// **'Next execution: {date}'**
  String recurringNextExecution(String date);

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic back / dismiss button
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Join-group screen title and primary action button
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupTitle;

  /// Overlay hint shown while the QR scanner is active
  ///
  /// In en, this message translates to:
  /// **'Point at a Splitty group QR code'**
  String get joinGroupScanHint;

  /// Secondary action on the join-error state that opens the QR scanner
  ///
  /// In en, this message translates to:
  /// **'Try QR Scanner'**
  String get joinGroupTryScanner;

  /// Fallback group name when the fetched group has no name
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get joinGroupDefaultName;

  /// Member-count badge on the join-group preview
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String joinGroupMemberCount(int count);

  /// Error when no group matches the entered share code
  ///
  /// In en, this message translates to:
  /// **'No group found with code \"{code}\"'**
  String joinGroupNotFoundWithCode(String code);

  /// Error when the group lookup or join fails due to connectivity
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your internet connection.'**
  String get joinGroupConnectionError;

  /// Error when a scanned QR code resolves to no group
  ///
  /// In en, this message translates to:
  /// **'No group found with this QR code.'**
  String get joinGroupNotFoundQr;

  /// Error when joining the group fails
  ///
  /// In en, this message translates to:
  /// **'Failed to join group. Please try again.'**
  String get joinGroupJoinFailed;

  /// Error when a scanned QR code is not a Split Genesis group link
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Please scan a Split Genesis group QR.'**
  String get joinGroupInvalidQr;

  /// Error when a scanned QR code cannot be parsed as a URI
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format.'**
  String get joinGroupInvalidQrFormat;

  /// Onboarding page 1 hero title ('Splitty' is the product brand, not translated)
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nSplitty'**
  String get onboardingWelcomeTitle;

  /// Onboarding page 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Split expenses with friends,\nsimply and fairly.'**
  String get onboardingWelcomeSubtitle;

  /// Primary onboarding CTA (welcome page and name page)
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// Reassurance footnote under the welcome CTA
  ///
  /// In en, this message translates to:
  /// **'Free · No account needed · Works offline'**
  String get onboardingWelcomeFootnote;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Fair settlements,\nalways'**
  String get onboardingSettleTitle;

  /// Onboarding page 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'We track exactly who owes what — so when\nit\'s time to settle, everyone pays fairly.'**
  String get onboardingSettleSubtitle;

  /// Onboarding feature bullet: debt simplification
  ///
  /// In en, this message translates to:
  /// **'Automatic debt simplification'**
  String get onboardingFeatureSimplify;

  /// Onboarding feature bullet: offline support
  ///
  /// In en, this message translates to:
  /// **'Works offline, syncs automatically'**
  String get onboardingFeatureOffline;

  /// Onboarding feature bullet: privacy
  ///
  /// In en, this message translates to:
  /// **'Your data stays private'**
  String get onboardingFeaturePrivate;

  /// Advance to the next onboarding page
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Label above the 'before' state of the debt-simplification diagram
  ///
  /// In en, this message translates to:
  /// **'OTHER APPS'**
  String get onboardingDiagramOtherApps;

  /// Caption for the 'before' (unsimplified) diagram state
  ///
  /// In en, this message translates to:
  /// **'A owes B, B owes C — confusing!'**
  String get onboardingDiagramBeforeCaption;

  /// Caption for the 'after' (simplified) diagram state
  ///
  /// In en, this message translates to:
  /// **'A pays C directly. Done. ✓'**
  String get onboardingDiagramAfterCaption;

  /// Onboarding page 3 title asking for the user's display name
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingNameTitle;

  /// Onboarding page 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'So your friends know who you are.'**
  String get onboardingNameSubtitle;

  /// Placeholder for the display-name text field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingNamePlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
