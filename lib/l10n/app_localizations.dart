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

  /// Generic destructive delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Balance pill label when a member is neither owed nor owing
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get balanceSettled;

  /// Placeholder for the share-code field in the join-by-code dialog
  ///
  /// In en, this message translates to:
  /// **'e.g., A1B2C3D4'**
  String get homeJoinCodePlaceholder;

  /// Confirm button in the join-by-code dialog
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get homeJoinAction;

  /// Snackbar when a manually entered share code matches no group
  ///
  /// In en, this message translates to:
  /// **'No group found with this code'**
  String get homeGroupNotFoundByCode;

  /// App-bar icon tooltip that opens the join-by-code dialog
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get homeJoinTooltip;

  /// App-bar icon tooltip that opens the create-group screen
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get homeNewGroupTooltip;

  /// Empty-state title on the home screen
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get homeEmptyTitle;

  /// Empty-state subtitle on the home screen
  ///
  /// In en, this message translates to:
  /// **'Create a group to start splitting expenses'**
  String get homeEmptySubtitle;

  /// Empty-state CTA to create the first group
  ///
  /// In en, this message translates to:
  /// **'Create your first group'**
  String get homeCreateFirstGroup;

  /// Prominent create-group button below the group list
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get homeCreateNewGroup;

  /// Title of the long-press delete-group action sheet
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get homeDeleteGroupTitle;

  /// Confirmation message when deleting a group
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its expenses? This cannot be undone.'**
  String homeDeleteGroupMessage(String name);

  /// Member count subtitle on a group list item
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String homePersonCount(int count);

  /// Create-group screen title
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get addGroupTitle;

  /// Create-group confirm button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get addGroupCreate;

  /// Snackbar error when fewer than two members were added
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 members'**
  String get addGroupErrorMinMembers;

  /// Snackbar error when group creation throws
  ///
  /// In en, this message translates to:
  /// **'Error creating group: {error}'**
  String addGroupErrorCreate(String error);

  /// Currency picker action-sheet title
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get addGroupSelectCurrency;

  /// Section header above the group-name field
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME'**
  String get addGroupSectionName;

  /// Placeholder for the group-name field
  ///
  /// In en, this message translates to:
  /// **'Weekend Trip, Rent, …'**
  String get addGroupNamePlaceholder;

  /// Section header above the group-type picker
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get addGroupSectionType;

  /// Section header above the currency row
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get addGroupSectionCurrency;

  /// Label of the currency selection row
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get addGroupCurrency;

  /// Section header above the members list
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get addGroupSectionMembers;

  /// Counter of how many members have been added so far
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String addGroupMembersAdded(int count);

  /// Placeholder for the add-member text field
  ///
  /// In en, this message translates to:
  /// **'Add member name…'**
  String get addGroupMemberPlaceholder;

  /// Hint shown when no members have been added yet
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 members to create a group.'**
  String get addGroupHintMinMembers;

  /// Hint shown when exactly one member has been added
  ///
  /// In en, this message translates to:
  /// **'Add one more member.'**
  String get addGroupHintOneMore;

  /// Title of the post-creation QR/share screen
  ///
  /// In en, this message translates to:
  /// **'Group Created'**
  String get addGroupCreatedTitle;

  /// App-bar action to open the newly created group
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get addGroupOpen;

  /// Subtitle on the post-creation share screen
  ///
  /// In en, this message translates to:
  /// **'Invite others by sharing the QR code or share code below.'**
  String get addGroupInviteHint;

  /// Snackbar after tapping the share-code chip
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get addGroupCodeCopied;

  /// Primary button to enter the newly created group
  ///
  /// In en, this message translates to:
  /// **'Open Group'**
  String get addGroupOpenGroup;

  /// Title of the rename-group dialog
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get groupDetailRenameGroupTitle;

  /// Placeholder for the group name text field in the rename dialog
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupDetailGroupNamePlaceholder;

  /// Save button in the rename-group dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupDetailSave;

  /// Share sheet subject when exporting the group's expenses as CSV
  ///
  /// In en, this message translates to:
  /// **'{name} – Expenses Export'**
  String groupDetailCsvExportSubject(String name);

  /// Snackbar shown when CSV export fails
  ///
  /// In en, this message translates to:
  /// **'CSV export failed: {error}'**
  String groupDetailCsvExportFailed(String error);

  /// Share sheet subject when exporting the group as PDF
  ///
  /// In en, this message translates to:
  /// **'{name} – Export'**
  String groupDetailPdfExportSubject(String name);

  /// Snackbar shown when PDF export fails
  ///
  /// In en, this message translates to:
  /// **'PDF export failed: {error}'**
  String groupDetailPdfExportFailed(String error);

  /// Text shared via the system share sheet to invite someone to a group
  ///
  /// In en, this message translates to:
  /// **'Join my group \"{name}\" on Split Genesis!\nTap: splitgenesis://join/{code}\nOr enter code: {code}'**
  String groupDetailShareText(String name, String code);

  /// Title of the invite/share bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Invite to \"{name}\"'**
  String groupDetailInviteTo(String name);

  /// Label above the large invite code display
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get groupDetailInviteCode;

  /// Snackbar shown after copying the invite code
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get groupDetailCodeCopied;

  /// Button to copy the invite code
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get groupDetailCopyCode;

  /// Button to share the invite via the system share sheet
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get groupDetailShareInvite;

  /// Snackbar shown when trying to record a payment with fewer than two members
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 members to record a payment'**
  String get groupDetailNeedTwoMembers;

  /// Title of the record-payment dialog and the corresponding menu action
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get groupDetailRecordPayment;

  /// Label for the payer (from) dropdown in the record-payment dialog
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get groupDetailFrom;

  /// Label for the payee (to) dropdown in the record-payment dialog
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get groupDetailTo;

  /// Placeholder for the amount field in the record-payment dialog
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get groupDetailAmount;

  /// Confirm button in the record-payment dialog
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get groupDetailRecord;

  /// Fallback member name shown when a member's name cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get groupDetailUnknownMember;

  /// Snackbar shown after a payment is successfully recorded
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get groupDetailPaymentRecorded;

  /// Snackbar shown when recording a payment fails
  ///
  /// In en, this message translates to:
  /// **'Error recording payment: {error}'**
  String groupDetailPaymentError(String error);

  /// Title of the add-member dialog and the corresponding menu action
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get groupDetailAddMember;

  /// Placeholder for the name field in the add-member dialog
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groupDetailName;

  /// Confirm button in the add-member dialog
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get groupDetailAdd;

  /// Snackbar shown after a member is added
  ///
  /// In en, this message translates to:
  /// **'{name} added to group'**
  String groupDetailMemberAdded(String name);

  /// Tooltip on the floating action button that adds an expense
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get groupDetailAddExpense;

  /// Menu action to open the members screen
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupDetailMembers;

  /// Menu action to open the statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get groupDetailStatistics;

  /// Menu action to rename the group
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get groupDetailRename;

  /// Menu action to export the group as CSV
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get groupDetailExportCsv;

  /// Menu action to export the group as PDF
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get groupDetailExportPdf;

  /// Segmented control label for the expenses tab
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get groupDetailExpensesTab;

  /// Segmented control label for the balances/debts tab
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get groupDetailBalancesTab;

  /// Segmented control label for the activity tab
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get groupDetailActivityTab;

  /// Header balance card label when the user is owed money overall
  ///
  /// In en, this message translates to:
  /// **'You are owed in total'**
  String get groupDetailTotalYouAreOwed;

  /// Header balance card label when the user owes money overall
  ///
  /// In en, this message translates to:
  /// **'You owe in total'**
  String get groupDetailTotalYouOwe;

  /// Header balance card label when everyone is settled up
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get groupDetailAllSettled;

  /// Date group header for expenses dated today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupDetailToday;

  /// Date group header for expenses dated yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get groupDetailYesterday;

  /// Label of the positive status card in the balances tab
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get groupDetailYouAreOwed;

  /// Label of the negative status card in the balances tab
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get groupDetailYouOwe;

  /// Title of the expense filter bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Filter Expenses'**
  String get groupDetailFilterExpenses;

  /// Section header for the category filter
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get groupDetailCategory;

  /// Filter chip that selects all categories or all payers
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupDetailAll;

  /// Section header for the payer filter
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get groupDetailPaidBy;

  /// Section header for the date range filter
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get groupDetailDateRange;

  /// Date range button label when no range is selected
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get groupDetailAllTime;

  /// Selected date range shown on the date filter button
  ///
  /// In en, this message translates to:
  /// **'{start} — {end}'**
  String groupDetailDateRangeValue(String start, String end);

  /// Button to clear the selected date range filter
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get groupDetailClearDateFilter;

  /// Button to reset all active expense filters
  ///
  /// In en, this message translates to:
  /// **'Reset all filters'**
  String get groupDetailResetAllFilters;

  /// Empty-state title shown when the group has no expenses
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get groupDetailNoExpenses;

  /// Empty-state button to add the first expense
  ///
  /// In en, this message translates to:
  /// **'Add first expense'**
  String get groupDetailFirstExpense;

  /// Hint text of the expense search field
  ///
  /// In en, this message translates to:
  /// **'Search expenses…'**
  String get groupDetailSearchExpenses;

  /// Tooltip on the filter button
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get groupDetailFilter;

  /// Summary of how many expenses match the active filters
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} expenses'**
  String groupDetailFilteredCount(int count, int total);

  /// Button to clear all active filters from the summary row
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get groupDetailClear;

  /// One-time hint banner explaining swipe-to-delete
  ///
  /// In en, this message translates to:
  /// **'Swipe left on an expense to delete it'**
  String get groupDetailSwipeHint;

  /// Button to dismiss the swipe-to-delete hint banner
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get groupDetailGotIt;

  /// Empty-state shown when no expenses match the search or filters
  ///
  /// In en, this message translates to:
  /// **'No matching expenses'**
  String get groupDetailNoMatchingExpenses;

  /// Title and destructive action of the delete-expense confirmation sheet
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get groupDetailDeleteExpenseTitle;

  /// Confirmation message before deleting an expense
  ///
  /// In en, this message translates to:
  /// **'\"{description}\" ({amount}) will be permanently deleted.'**
  String groupDetailDeleteExpenseMessage(String description, String amount);

  /// Subtitle on an expense row showing who paid
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String groupDetailPaidByName(String name);

  /// Uppercase section header above the per-member balances list
  ///
  /// In en, this message translates to:
  /// **'WHO OWES WHOM'**
  String get groupDetailWhoOwesWhom;

  /// Empty-state text when there are no balances to display
  ///
  /// In en, this message translates to:
  /// **'No balances to show'**
  String get groupDetailNoBalances;

  /// Banner indicating that debt simplification is active
  ///
  /// In en, this message translates to:
  /// **'Debts simplified — automatic netting active.'**
  String get groupDetailDebtsSimplified;

  /// Sticky button to open the settle-up screen
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get groupDetailSettleUp;

  /// Legal screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// Segmented-control tab label for the Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalTabPrivacy;

  /// Segmented-control tab label for the Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTabTerms;

  /// Header title of the Privacy Policy tab
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyHeaderTitle;

  /// Header subtitle showing the last update date of the Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Last updated: March 2026'**
  String get legalPrivacyHeaderSubtitle;

  /// Privacy Policy section 1 title
  ///
  /// In en, this message translates to:
  /// **'1. Data Controller'**
  String get legalPrivacySection1Title;

  /// Privacy Policy section 1 body (data controller identification)
  ///
  /// In en, this message translates to:
  /// **'Split Genesis is operated by Salah AI Company (\"we\", \"us\", \"our\"). You can reach us at: legal@split-genesis.app\n\nAs the responsible party within the meaning of the DSGVO (GDPR), we are committed to protecting your personal data.'**
  String get legalPrivacySection1Body;

  /// Privacy Policy section 2 title
  ///
  /// In en, this message translates to:
  /// **'2. What Data We Collect'**
  String get legalPrivacySection2Title;

  /// Privacy Policy section 2 body (data collected, bullet list)
  ///
  /// In en, this message translates to:
  /// **'We collect the minimum data necessary to operate Split Genesis:\n\n• Account data: email address and display name (provided by you at sign-up)\n• Group data: group names, member lists, expense descriptions and amounts\n• Device data: device type and app version (for crash reporting only)\n• Usage data: anonymous feature usage statistics (no personal identifiers)\n\nWe do NOT collect: location, contacts, microphone, camera, or advertising IDs.'**
  String get legalPrivacySection2Body;

  /// Privacy Policy section 3 title
  ///
  /// In en, this message translates to:
  /// **'3. Purpose and Legal Basis (Art. 6 DSGVO)'**
  String get legalPrivacySection3Title;

  /// Privacy Policy section 3 body (purpose and legal basis, bullet list with article references)
  ///
  /// In en, this message translates to:
  /// **'Your data is processed for the following purposes:\n\n• To provide the expense-splitting service (Art. 6(1)(b) DSGVO — contract performance)\n• To sync data across your devices via Supabase (Art. 6(1)(b) DSGVO)\n• To detect and fix technical errors (Art. 6(1)(f) DSGVO — legitimate interest)\n\nWe do not process your data for advertising or sell it to third parties.'**
  String get legalPrivacySection3Body;

  /// Privacy Policy section 4 title
  ///
  /// In en, this message translates to:
  /// **'4. Data Storage and Processors'**
  String get legalPrivacySection4Title;

  /// Privacy Policy section 4 body (data storage and processors)
  ///
  /// In en, this message translates to:
  /// **'Your data is stored on Supabase infrastructure (PostgreSQL database) hosted in the EU (Frankfurt, Germany). Supabase B.V. acts as our data processor under a Data Processing Agreement (DPA) compliant with Art. 28 DSGVO.\n\nCrash reports are processed by our self-hosted Bugsink instance on Hetzner (Germany). No data is sent to third-party crash analytics providers.'**
  String get legalPrivacySection4Body;

  /// Privacy Policy section 5 title
  ///
  /// In en, this message translates to:
  /// **'5. Retention Period'**
  String get legalPrivacySection5Title;

  /// Privacy Policy section 5 body (retention period)
  ///
  /// In en, this message translates to:
  /// **'Account and expense data is retained for as long as your account is active. If you delete your account, all associated data (groups, expenses, members) is permanently deleted within 30 days.\n\nAnonymous usage statistics are retained for up to 12 months then auto-deleted.'**
  String get legalPrivacySection5Body;

  /// Privacy Policy section 6 title
  ///
  /// In en, this message translates to:
  /// **'6. Your Rights (Art. 15–22 DSGVO)'**
  String get legalPrivacySection6Title;

  /// Privacy Policy section 6 body (data subject rights, bullet list with article references)
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n\n• Access: request a copy of all data we hold about you (Art. 15)\n• Rectification: correct inaccurate data (Art. 16)\n• Erasure: delete your account and all data (\"right to be forgotten\", Art. 17)\n• Portability: export your data in machine-readable format (Art. 20)\n• Objection: object to processing based on legitimate interests (Art. 21)\n\nTo exercise your rights, contact us at: legal@split-genesis.app\n\nYou also have the right to lodge a complaint with your local supervisory authority (in Germany: the Datenschutzbeauftragter of your federal state).'**
  String get legalPrivacySection6Body;

  /// Privacy Policy section 7 title
  ///
  /// In en, this message translates to:
  /// **'7. How to Delete Your Account'**
  String get legalPrivacySection7Title;

  /// Privacy Policy section 7 body (account deletion steps, numbered list)
  ///
  /// In en, this message translates to:
  /// **'You can delete your account and all data at any time:\n\n1. Open Settings in Split Genesis\n2. Scroll to the bottom → \"Delete Account\"\n3. Confirm deletion — all data is queued for removal\n4. Complete deletion occurs within 30 days\n\nAlternatively, email us at legal@split-genesis.app with subject \"Account Deletion Request\".'**
  String get legalPrivacySection7Body;

  /// Privacy Policy section 8 title
  ///
  /// In en, this message translates to:
  /// **'8. Children’s Privacy'**
  String get legalPrivacySection8Title;

  /// Privacy Policy section 8 body (children's privacy)
  ///
  /// In en, this message translates to:
  /// **'Split Genesis is not directed at children under 13 (EU: under 16). We do not knowingly collect data from children. If you believe a child has provided us data, contact us immediately.'**
  String get legalPrivacySection8Body;

  /// Privacy Policy section 9 title
  ///
  /// In en, this message translates to:
  /// **'9. Contact'**
  String get legalPrivacySection9Title;

  /// Privacy Policy section 9 body (contact)
  ///
  /// In en, this message translates to:
  /// **'Data protection questions: legal@split-genesis.app\nResponse time: within 30 days as required by Art. 12 DSGVO.'**
  String get legalPrivacySection9Body;

  /// Link-button label opening the full Privacy Policy on the web
  ///
  /// In en, this message translates to:
  /// **'Full Privacy Policy (Web)'**
  String get legalLinkPrivacyWeb;

  /// Header title of the Terms of Service tab
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsHeaderTitle;

  /// Header subtitle showing the effective date of the Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Effective: March 2026'**
  String get legalTermsHeaderSubtitle;

  /// Terms of Service section 1 title
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance'**
  String get legalTermsSection1Title;

  /// Terms of Service section 1 body (acceptance)
  ///
  /// In en, this message translates to:
  /// **'By using Split Genesis, you agree to these Terms of Service. If you do not agree, do not use the app. These terms are governed by German law.'**
  String get legalTermsSection1Body;

  /// Terms of Service section 2 title
  ///
  /// In en, this message translates to:
  /// **'2. Service Description'**
  String get legalTermsSection2Title;

  /// Terms of Service section 2 body (service description)
  ///
  /// In en, this message translates to:
  /// **'Split Genesis is an expense-splitting app that allows groups of people to track shared expenses and calculate who owes whom. The app is provided \"as is\" for personal, non-commercial use.'**
  String get legalTermsSection2Body;

  /// Terms of Service section 3 title
  ///
  /// In en, this message translates to:
  /// **'3. Account Responsibilities'**
  String get legalTermsSection3Title;

  /// Terms of Service section 3 body (account responsibilities, bullet list)
  ///
  /// In en, this message translates to:
  /// **'• You are responsible for maintaining the confidentiality of your account\n• You must provide accurate information during sign-up\n• You must not use the app for unlawful purposes\n• You must not attempt to reverse-engineer or disrupt the service\n• You are responsible for all activity under your account'**
  String get legalTermsSection3Body;

  /// Terms of Service section 4 title
  ///
  /// In en, this message translates to:
  /// **'4. User Content'**
  String get legalTermsSection4Title;

  /// Terms of Service section 4 body (user content)
  ///
  /// In en, this message translates to:
  /// **'You retain ownership of all content you enter into Split Genesis (expense names, amounts, notes). By using the service, you grant us a limited license to store and process this content solely to provide the service to you and your group members.'**
  String get legalTermsSection4Body;

  /// Terms of Service section 5 title
  ///
  /// In en, this message translates to:
  /// **'5. Accuracy of Calculations'**
  String get legalTermsSection5Title;

  /// Terms of Service section 5 body (accuracy of calculations)
  ///
  /// In en, this message translates to:
  /// **'Split Genesis performs expense calculations in good faith, but we cannot guarantee the accuracy of all calculations in all edge cases. Always verify important financial settlements independently. We are not liable for financial losses arising from incorrect calculations.'**
  String get legalTermsSection5Body;

  /// Terms of Service section 6 title
  ///
  /// In en, this message translates to:
  /// **'6. Service Availability'**
  String get legalTermsSection6Title;

  /// Terms of Service section 6 body (service availability)
  ///
  /// In en, this message translates to:
  /// **'We aim for high availability but do not guarantee 100% uptime. We may perform maintenance that causes temporary interruptions. We will notify users of planned downtime where possible.'**
  String get legalTermsSection6Body;

  /// Terms of Service section 7 title
  ///
  /// In en, this message translates to:
  /// **'7. Termination'**
  String get legalTermsSection7Title;

  /// Terms of Service section 7 body (termination)
  ///
  /// In en, this message translates to:
  /// **'You may terminate your account at any time via Settings → Delete Account. We reserve the right to suspend or terminate accounts that violate these terms. Upon termination, your data is deleted per our Privacy Policy (30 days).'**
  String get legalTermsSection7Body;

  /// Terms of Service section 8 title
  ///
  /// In en, this message translates to:
  /// **'8. Limitation of Liability'**
  String get legalTermsSection8Title;

  /// Terms of Service section 8 body (limitation of liability)
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by applicable law, Split Genesis and Salah AI Company are not liable for indirect, incidental, or consequential damages. Our total liability is limited to amounts you paid to us in the past 12 months (or €50 if no payment was made).'**
  String get legalTermsSection8Body;

  /// Terms of Service section 9 title
  ///
  /// In en, this message translates to:
  /// **'9. Changes to Terms'**
  String get legalTermsSection9Title;

  /// Terms of Service section 9 body (changes to terms)
  ///
  /// In en, this message translates to:
  /// **'We may update these terms. Material changes will be notified in-app. Continued use after changes constitutes acceptance of the new terms.'**
  String get legalTermsSection9Body;

  /// Terms of Service section 10 title
  ///
  /// In en, this message translates to:
  /// **'10. Contact and Disputes'**
  String get legalTermsSection10Title;

  /// Terms of Service section 10 body (contact and disputes)
  ///
  /// In en, this message translates to:
  /// **'For questions or disputes: legal@split-genesis.app\n\nApplicable law: Federal Republic of Germany\nJurisdiction: Courts of Hamburg, Germany\n\nEU Online Dispute Resolution: https://ec.europa.eu/consumers/odr'**
  String get legalTermsSection10Body;

  /// Link-button label opening the full Terms of Service on the web
  ///
  /// In en, this message translates to:
  /// **'Full Terms of Service (Web)'**
  String get legalLinkTermsWeb;

  /// Settle-up screen app-bar title, sheet title, and the per-debt settle action button
  ///
  /// In en, this message translates to:
  /// **'Settle Up'**
  String get settleUpTitle;

  /// Section header above the list of open debts
  ///
  /// In en, this message translates to:
  /// **'Outstanding debts'**
  String get settleUpOutstandingDebts;

  /// Error shown when the settlements fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading: {error}'**
  String settleUpLoadError(String error);

  /// Retry button on the settle-up load-error state
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get settleUpTryAgain;

  /// Headline on the empty state when no debts remain
  ///
  /// In en, this message translates to:
  /// **'All settled up!'**
  String get settleUpAllSettledTitle;

  /// Empty-state subtitle naming the group with no open debts
  ///
  /// In en, this message translates to:
  /// **'No outstanding debts in \"{groupName}\"'**
  String settleUpNoDebtsIn(String groupName);

  /// Button that returns to the group from the all-settled state
  ///
  /// In en, this message translates to:
  /// **'Back to Group'**
  String get settleUpBackToGroup;

  /// Header card label showing the number of open debts
  ///
  /// In en, this message translates to:
  /// **'Open: {count}'**
  String settleUpOpenCount(int count);

  /// Header card label showing the total amount owed (pre-formatted currency)
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String settleUpTotal(String amount);

  /// Title of the confirm action sheet for settling every debt
  ///
  /// In en, this message translates to:
  /// **'Settle all'**
  String get settleUpSettleAllTitle;

  /// Confirmation message before settling all debts
  ///
  /// In en, this message translates to:
  /// **'Mark all {count} debts as settled? This updates the group balances.'**
  String settleUpSettleAllMessage(int count);

  /// Destructive action button that settles all debts
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Settle 1 debt} other{Settle {count} debts}}'**
  String settleUpSettleAllAction(int count);

  /// Snackbar after a partial payment is recorded
  ///
  /// In en, this message translates to:
  /// **'{from} paid {amount} (partial) to {to}'**
  String settleUpPartialPaidSnack(String from, String amount, String to);

  /// Snackbar after a debt is fully settled
  ///
  /// In en, this message translates to:
  /// **'{from} settled {amount} with {to}'**
  String settleUpSettledSnack(String from, String amount, String to);

  /// Small label under the debtor's name on a settlement card
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get settleUpOwes;

  /// Label above the debt amount on a settlement card
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get settleUpAmount;

  /// Validation error when the entered partial amount is zero or negative
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get settleUpAmountMustBePositive;

  /// Validation error when the entered partial amount exceeds the debt
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed {amount}'**
  String settleUpCannotExceed(String amount);

  /// Subtitle in the partial-payment sheet describing who owes whom
  ///
  /// In en, this message translates to:
  /// **'{from} owes {to}'**
  String settleUpOwesTo(String from, String to);

  /// Label under the amount field showing the full debt total
  ///
  /// In en, this message translates to:
  /// **'of {amount} total'**
  String settleUpOfTotal(String amount);

  /// Button that fills the amount field with the full debt
  ///
  /// In en, this message translates to:
  /// **'Settle full'**
  String get settleUpSettleFull;

  /// Label for the payment-method row in the partial-payment sheet
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get settleUpPaymentMethod;

  /// Payment method value shown as a placeholder
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get settleUpBankTransfer;

  /// Snackbar shown when tapping the not-yet-available bank-transfer option
  ///
  /// In en, this message translates to:
  /// **'Bank transfer: coming soon'**
  String get settleUpBankTransferComingSoon;

  /// Button to change the payment method
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settleUpChange;

  /// Confirm button when a partial amount is chosen
  ///
  /// In en, this message translates to:
  /// **'Confirm payment ({amount})'**
  String settleUpConfirmPaymentAmount(String amount);

  /// Confirm button when settling the full amount
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get settleUpConfirmPayment;

  /// Fine-print note under the confirm button in the partial-payment sheet
  ///
  /// In en, this message translates to:
  /// **'The amount will be marked as settled immediately.'**
  String get settleUpMarkedImmediately;

  /// Author name used for the current user's own comments
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get expenseDetailYou;

  /// Fallback name when a member cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get expenseDetailUnknown;

  /// Expense detail screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetailTitle;

  /// Info-row label for who paid the expense
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get expenseDetailPaidBy;

  /// Info-row label for the expense date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseDetailDate;

  /// Info-row label for the expense category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseDetailCategory;

  /// Section header above the per-member split breakdown
  ///
  /// In en, this message translates to:
  /// **'Split Details'**
  String get expenseDetailSplitDetails;

  /// Section header above the receipt photo
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get expenseDetailReceipt;

  /// Shown when the receipt image fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load receipt'**
  String get expenseDetailReceiptLoadError;

  /// Section header above the comments list
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get expenseDetailComments;

  /// Empty state when an expense has no comments yet
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment'**
  String get expenseDetailBeFirstComment;

  /// Placeholder for the comment input field
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get expenseDetailAddCommentHint;

  /// Activity screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// Empty-state title when there is no activity to show
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityEmpty;

  /// Empty-state subtitle on the global activity screen when no groups exist
  ///
  /// In en, this message translates to:
  /// **'Create a group to get started'**
  String get activityEmptyCreateGroup;

  /// Empty-state subtitle in a group's activity tab
  ///
  /// In en, this message translates to:
  /// **'Actions will appear here'**
  String get activityEmptyHint;

  /// Relative time for events less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get activityJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String activityMinutesAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String activityHoursAgo(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String activityDaysAgo(int count);

  /// Relative time / date-group label for the previous day
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get activityYesterday;

  /// Date-group label for the current day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get activityToday;

  /// Settings screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Profile section header on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// Placeholder for the display-name text field
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsYourNameHint;

  /// Prompt shown when no display name has been set yet
  ///
  /// In en, this message translates to:
  /// **'Tap to set your name'**
  String get settingsTapToSetName;

  /// Caption under the user name indicating it is the display name
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// Appearance section header on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Label for the light/system/dark theme selector
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Light theme segment label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// System (auto) theme segment label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Dark theme segment label
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Default currency section header and currency picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get settingsDefaultCurrency;

  /// Currency row label in the default-currency section
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// Helper text explaining the default currency setting
  ///
  /// In en, this message translates to:
  /// **'Used as the default when creating new expenses.'**
  String get settingsCurrencyHelp;

  /// About section header on the settings screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutHeader;

  /// App version row label in the about section
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// About row that opens the about sheet
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutRow;

  /// Row opening privacy policy and terms
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get settingsPrivacyTerms;

  /// About row noting the app is built with Flutter
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter'**
  String get settingsBuiltWithFlutter;

  /// Trailing caption on the Built with Flutter row
  ///
  /// In en, this message translates to:
  /// **'Made with love'**
  String get settingsMadeWithLove;

  /// Version line in the about sheet
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// Copyright line in the about sheet
  ///
  /// In en, this message translates to:
  /// **'© 2026 Split Genesis. All rights reserved.'**
  String get settingsAboutCopyright;

  /// Close button in the about sheet
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsAboutClose;

  /// Group settings screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTitle;

  /// Title of the rename-group dialog
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get groupSettingsRenameTitle;

  /// Placeholder for the group-name text field
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupSettingsNameHint;

  /// Save action in the rename-group dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get groupSettingsSave;

  /// Title of the group symbol picker sheet
  ///
  /// In en, this message translates to:
  /// **'Choose symbol'**
  String get groupSettingsChooseSymbol;

  /// Snackbar shown when trying to persist a changed group symbol
  ///
  /// In en, this message translates to:
  /// **'Saving symbol: coming soon'**
  String get groupSettingsSymbolComingSoon;

  /// Snackbar shown when trying to change the group currency
  ///
  /// In en, this message translates to:
  /// **'Changing currency: coming soon'**
  String get groupSettingsCurrencyComingSoon;

  /// Title of the leave-group confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Leave group?'**
  String get groupSettingsLeaveTitle;

  /// Body of the leave-group confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You’ll be removed from the member list. This action can’t be undone.'**
  String get groupSettingsLeaveMessage;

  /// Confirm action in the leave-group dialog
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupSettingsLeave;

  /// Snackbar shown when the user is not a member of the group
  ///
  /// In en, this message translates to:
  /// **'You’re not a member of this group.'**
  String get groupSettingsNotMember;

  /// Title of the delete-group confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get groupSettingsDeleteTitle;

  /// Body of the delete-group confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'All expenses, members and activities of this group will be deleted. This can’t be undone.'**
  String get groupSettingsDeleteMessage;

  /// Group name row label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groupSettingsName;

  /// Group symbol row label
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get groupSettingsSymbol;

  /// Group currency row label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get groupSettingsCurrency;

  /// Row opening the manage members screen
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get groupSettingsManageMembers;

  /// Danger-zone button to leave the group
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupSettingsLeaveGroup;

  /// Danger-zone button to delete the group
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupSettingsDeleteGroup;

  /// Fallback display name shown when the user has not set a name
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get accountYou;

  /// Account screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// Subtitle under the avatar showing the default currency
  ///
  /// In en, this message translates to:
  /// **'Default currency: {currency}'**
  String accountDefaultCurrency(String currency);

  /// Header above the account statistics cards
  ///
  /// In en, this message translates to:
  /// **'MY STATISTICS'**
  String get accountMyStats;

  /// Label of the lifetime spent statistics card
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get accountTotalSpent;

  /// Label of the lifetime settled statistics card
  ///
  /// In en, this message translates to:
  /// **'Total settled'**
  String get accountTotalSettled;

  /// Settings section header on the account screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettings;

  /// Row opening the personal data (settings) screen
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get accountPersonalData;

  /// Notifications row in the account settings section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountNotifications;

  /// Bank details row in the account settings section
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get accountBankDetails;

  /// Sign out button on the account screen
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Snackbar for a feature that is not available yet
  ///
  /// In en, this message translates to:
  /// **'{feature}: coming soon'**
  String accountComingSoon(String feature);

  /// Friends screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// Heading of the friends empty state
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get friendsComingSoon;

  /// Body text of the friends empty state
  ///
  /// In en, this message translates to:
  /// **'Soon you’ll be able to add friends and settle up even without a group.'**
  String get friendsComingSoonBody;

  /// Add-expense screen app-bar title when creating a new expense
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get addExpenseTitle;

  /// Add-expense screen app-bar title when editing an existing expense
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get addExpenseEditTitle;

  /// Placeholder for the expense description text field
  ///
  /// In en, this message translates to:
  /// **'What for?'**
  String get addExpenseWhatFor;

  /// Label for the payer row / picker
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get addExpensePaidBy;

  /// Save button that stores the expense
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addExpenseSave;

  /// Expandable section header revealing category/split/date options
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get addExpenseMoreDetails;

  /// Label above the category picker grid
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addExpenseCategoryLabel;

  /// Uppercase section header above the compact category row
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get addExpenseCategorySection;

  /// Label above the split-type segmented control
  ///
  /// In en, this message translates to:
  /// **'Split type'**
  String get addExpenseSplitTypeLabel;

  /// Split-type option: split the amount equally
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get addExpenseSplitEqual;

  /// Split-type option: enter exact amounts per member
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get addExpenseSplitExact;

  /// Split-type option: split by number of shares
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get addExpenseSplitShares;

  /// Label above the member selector for who shares the expense
  ///
  /// In en, this message translates to:
  /// **'Split among'**
  String get addExpenseSplitAmong;

  /// Section header above the member split pills
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get addExpenseSplitLabel;

  /// Button to select all members for the split
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get addExpenseSelectAll;

  /// Button to deselect all members from the split
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get addExpenseDeselectAll;

  /// Accessibility hint for the currently selected category tile
  ///
  /// In en, this message translates to:
  /// **'Selected category'**
  String get addExpenseCategorySelectedHint;

  /// Accessibility hint for an unselected category tile
  ///
  /// In en, this message translates to:
  /// **'Tap to select category'**
  String get addExpenseCategorySelectHint;

  /// Validation snackbar when the description is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get addExpenseDescriptionRequired;

  /// Validation snackbar when the amount is zero or empty
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get addExpenseAmountRequired;

  /// Validation snackbar when no payer is selected
  ///
  /// In en, this message translates to:
  /// **'Please choose who paid'**
  String get addExpensePayerRequired;

  /// Validation snackbar when no members are selected for the split (edit screen)
  ///
  /// In en, this message translates to:
  /// **'Please select members to split with'**
  String get addExpenseSplitMembersRequired;

  /// Validation snackbar when no member is selected for the split (add sheet)
  ///
  /// In en, this message translates to:
  /// **'Please select at least one person'**
  String get addExpenseSelectPersonRequired;

  /// Validation snackbar for exact split when member amounts do not sum to the total
  ///
  /// In en, this message translates to:
  /// **'Amounts must add up to {amount}'**
  String addExpenseExactSumError(String amount);

  /// Validation snackbar for percent split when percentages do not sum to 100
  ///
  /// In en, this message translates to:
  /// **'Percentages must add up to 100%'**
  String get addExpensePercentSumError;

  /// Validation snackbar for shares split when share values are invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter valid shares'**
  String get addExpenseSharesError;

  /// Snackbar shown when saving the expense fails (edit screen)
  ///
  /// In en, this message translates to:
  /// **'Error saving expense: {error}'**
  String addExpenseSaveError(String error);

  /// Snackbar shown when saving the expense fails (add sheet)
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String addExpenseError(String error);

  /// Error message shown when members fail to load in the add sheet
  ///
  /// In en, this message translates to:
  /// **'Error loading: {error}'**
  String addExpenseLoadError(String error);

  /// Button to retry loading members after an error
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get addExpenseRetry;

  /// Confirm button in the numpad and date picker sheets
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get addExpenseApply;

  /// Equal-split summary showing the per-person amount and headcount
  ///
  /// In en, this message translates to:
  /// **'{amount} per person ({count, plural, =1{1 person} other{{count} people}})'**
  String addExpensePerPerson(String amount, int count);

  /// Split validation showing the value still left to allocate (amount or percentage)
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining'**
  String addExpenseAmountRemaining(String amount);

  /// Split validation showing the value allocated beyond the total (amount or percentage)
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String addExpenseAmountOver(String amount);

  /// Split validation success message for exact amounts
  ///
  /// In en, this message translates to:
  /// **'Amounts match'**
  String get addExpenseAmountsMatch;

  /// Split validation success message for percentages
  ///
  /// In en, this message translates to:
  /// **'Percentages match (100%)'**
  String get addExpensePercentagesMatch;

  /// Split validation showing the sum of shares
  ///
  /// In en, this message translates to:
  /// **'Total shares: {shares}'**
  String addExpenseTotalShares(String shares);

  /// Toggle label for making the expense recurring
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get addExpenseRecurring;

  /// Button linking to a (future) custom-split editor
  ///
  /// In en, this message translates to:
  /// **'Customize split →'**
  String get addExpenseCustomizeSplit;

  /// Snackbar noting the custom-split editor is not yet available
  ///
  /// In en, this message translates to:
  /// **'Customize split: coming soon'**
  String get addExpenseCustomizeSplitSoon;

  /// Date label shown when the expense date is today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get addExpenseDateToday;

  /// Date label shown when the expense date is yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get addExpenseDateYesterday;

  /// Button in the compact category row that opens the full category grid
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get addExpenseCategoryMore;

  /// Category label: food/restaurants (compact row)
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get addExpenseCategoryFood;

  /// Category label: groceries (compact row)
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get addExpenseCategoryGroceries;

  /// Category label: travel (compact row)
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get addExpenseCategoryTravel;

  /// Error message shown when member details fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load member details'**
  String get memberDetailLoadError;

  /// Section header for the member's transaction list
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get memberDetailTransactionHistory;

  /// Empty-state text when the member has no transactions
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get memberDetailNoTransactions;

  /// Balance pill label when the member is owed money (positive balance)
  ///
  /// In en, this message translates to:
  /// **'gets back'**
  String get memberDetailGetsBack;

  /// Balance pill label when the member owes money (negative balance)
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get memberDetailOwes;

  /// Stat cell label: number of expenses this member paid for
  ///
  /// In en, this message translates to:
  /// **'Paid for'**
  String get memberDetailStatPaidFor;

  /// Stat cell label: number of expenses this member is involved in
  ///
  /// In en, this message translates to:
  /// **'Involved in'**
  String get memberDetailStatInvolvedIn;

  /// Stat cell label: number of settlements involving this member
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get memberDetailStatSettlements;

  /// Transaction subtitle when the member paid the expense
  ///
  /// In en, this message translates to:
  /// **'You paid {amount}'**
  String memberDetailYouPaid(String amount);

  /// Transaction subtitle showing the member's share of an expense
  ///
  /// In en, this message translates to:
  /// **'Your share {amount}'**
  String memberDetailYourShare(String amount);

  /// Transaction title for a settlement received from another member
  ///
  /// In en, this message translates to:
  /// **'Payment from {name}'**
  String memberDetailPaymentFrom(String name);

  /// Transaction title for a settlement sent to another member
  ///
  /// In en, this message translates to:
  /// **'Payment to {name}'**
  String memberDetailPaymentTo(String name);

  /// Transaction subtitle for a settlement the member received
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get memberDetailReceived;

  /// Transaction subtitle for a settlement the member sent
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get memberDetailSent;

  /// Statistics screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// Time filter segment: current month only
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsFilterThisMonth;

  /// Time filter segment: all time
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statsFilterAll;

  /// Error message when statistics data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading statistics'**
  String get statsErrorStatistics;

  /// Error message when payer data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading payer data'**
  String get statsErrorPayerData;

  /// Error message when member data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading member data'**
  String get statsErrorMemberData;

  /// Empty-state title when there are no expenses to show statistics for
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get statsEmptyTitle;

  /// Label on the total spend summary card
  ///
  /// In en, this message translates to:
  /// **'Total Group Spend'**
  String get statsTotalGroupSpend;

  /// Count of expenses recorded, shown under the total spend
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense recorded} other{{count} expenses recorded}}'**
  String statsExpensesRecorded(int count);

  /// Section header for the category breakdown chart
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get statsByCategory;

  /// Section header for the monthly spending chart
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get statsMonthlySpending;

  /// Section header for the per-member paid breakdown
  ///
  /// In en, this message translates to:
  /// **'Per Member Paid'**
  String get statsPerMemberPaid;

  /// Fallback name when a member's name is unavailable
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statsUnknownMember;

  /// Manage members screen app-bar title
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get manageMembersTitle;

  /// Section header above the add-member input
  ///
  /// In en, this message translates to:
  /// **'ADD MEMBER'**
  String get manageMembersAddSection;

  /// Placeholder text in the new member name input
  ///
  /// In en, this message translates to:
  /// **'New member name…'**
  String get manageMembersNamePlaceholder;

  /// Section header above the current members list
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get manageMembersMembersSection;

  /// Empty-state text when the group has no members
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get manageMembersEmpty;

  /// Hint explaining the swipe-to-remove gesture
  ///
  /// In en, this message translates to:
  /// **'Swipe left to remove a member.'**
  String get manageMembersSwipeHint;

  /// Title of the remove-member confirmation action sheet
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get manageMembersRemoveTitle;

  /// Confirmation message asking whether to remove a member
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this group?'**
  String manageMembersRemoveMessage(String name);

  /// Destructive confirm button that removes the member
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageMembersRemoveAction;

  /// Snackbar shown when a member cannot be removed because they have expenses
  ///
  /// In en, this message translates to:
  /// **'Cannot remove {name} — they have linked expenses'**
  String manageMembersCannotRemove(String name);
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
