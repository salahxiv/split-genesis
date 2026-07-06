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

  @override
  String get cancel => 'Cancel';

  @override
  String get goBack => 'Go Back';

  @override
  String get joinGroupTitle => 'Join Group';

  @override
  String get joinGroupScanHint => 'Point at a Splitty group QR code';

  @override
  String get joinGroupTryScanner => 'Try QR Scanner';

  @override
  String get joinGroupDefaultName => 'Group';

  @override
  String joinGroupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String joinGroupNotFoundWithCode(String code) {
    return 'No group found with code \"$code\"';
  }

  @override
  String get joinGroupConnectionError =>
      'Could not connect. Check your internet connection.';

  @override
  String get joinGroupNotFoundQr => 'No group found with this QR code.';

  @override
  String get joinGroupJoinFailed => 'Failed to join group. Please try again.';

  @override
  String get joinGroupInvalidQr =>
      'Invalid QR code. Please scan a Split Genesis group QR.';

  @override
  String get joinGroupInvalidQrFormat => 'Invalid QR code format.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to\nSplitty';

  @override
  String get onboardingWelcomeSubtitle =>
      'Split expenses with friends,\nsimply and fairly.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingWelcomeFootnote =>
      'Free · No account needed · Works offline';

  @override
  String get onboardingSettleTitle => 'Fair settlements,\nalways';

  @override
  String get onboardingSettleSubtitle =>
      'We track exactly who owes what — so when\nit\'s time to settle, everyone pays fairly.';

  @override
  String get onboardingFeatureSimplify => 'Automatic debt simplification';

  @override
  String get onboardingFeatureOffline => 'Works offline, syncs automatically';

  @override
  String get onboardingFeaturePrivate => 'Your data stays private';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingDiagramOtherApps => 'OTHER APPS';

  @override
  String get onboardingDiagramBeforeCaption =>
      'A owes B, B owes C — confusing!';

  @override
  String get onboardingDiagramAfterCaption => 'A pays C directly. Done. ✓';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameSubtitle => 'So your friends know who you are.';

  @override
  String get onboardingNamePlaceholder => 'Your name';

  @override
  String get delete => 'Delete';

  @override
  String get balanceSettled => 'Settled up';

  @override
  String get homeJoinCodePlaceholder => 'e.g., A1B2C3D4';

  @override
  String get homeJoinAction => 'Join';

  @override
  String get homeGroupNotFoundByCode => 'No group found with this code';

  @override
  String get homeJoinTooltip => 'Join group';

  @override
  String get homeNewGroupTooltip => 'New group';

  @override
  String get homeEmptyTitle => 'No groups yet';

  @override
  String get homeEmptySubtitle => 'Create a group to start splitting expenses';

  @override
  String get homeCreateFirstGroup => 'Create your first group';

  @override
  String get homeCreateNewGroup => 'Create New Group';

  @override
  String get homeDeleteGroupTitle => 'Delete group';

  @override
  String homeDeleteGroupMessage(String name) {
    return 'Delete \"$name\" and all its expenses? This cannot be undone.';
  }

  @override
  String homePersonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get addGroupTitle => 'New Group';

  @override
  String get addGroupCreate => 'Create';

  @override
  String get addGroupErrorMinMembers => 'Add at least 2 members';

  @override
  String addGroupErrorCreate(String error) {
    return 'Error creating group: $error';
  }

  @override
  String get addGroupSelectCurrency => 'Select Currency';

  @override
  String get addGroupSectionName => 'GROUP NAME';

  @override
  String get addGroupNamePlaceholder => 'Weekend Trip, Rent, …';

  @override
  String get addGroupSectionType => 'TYPE';

  @override
  String get addGroupSectionCurrency => 'CURRENCY';

  @override
  String get addGroupCurrency => 'Currency';

  @override
  String get addGroupSectionMembers => 'MEMBERS';

  @override
  String addGroupMembersAdded(int count) {
    return '$count added';
  }

  @override
  String get addGroupMemberPlaceholder => 'Add member name…';

  @override
  String get addGroupHintMinMembers =>
      'Add at least 2 members to create a group.';

  @override
  String get addGroupHintOneMore => 'Add one more member.';

  @override
  String get addGroupCreatedTitle => 'Group Created';

  @override
  String get addGroupOpen => 'Open';

  @override
  String get addGroupInviteHint =>
      'Invite others by sharing the QR code or share code below.';

  @override
  String get addGroupCodeCopied => 'Code copied!';

  @override
  String get addGroupOpenGroup => 'Open Group';

  @override
  String get groupDetailRenameGroupTitle => 'Rename Group';

  @override
  String get groupDetailGroupNamePlaceholder => 'Group Name';

  @override
  String get groupDetailSave => 'Save';

  @override
  String groupDetailCsvExportSubject(String name) {
    return '$name – Expenses Export';
  }

  @override
  String groupDetailCsvExportFailed(String error) {
    return 'CSV export failed: $error';
  }

  @override
  String groupDetailPdfExportSubject(String name) {
    return '$name – Export';
  }

  @override
  String groupDetailPdfExportFailed(String error) {
    return 'PDF export failed: $error';
  }

  @override
  String groupDetailShareText(String name, String code) {
    return 'Join my group \"$name\" on Split Genesis!\nTap: splitgenesis://join/$code\nOr enter code: $code';
  }

  @override
  String groupDetailInviteTo(String name) {
    return 'Invite to \"$name\"';
  }

  @override
  String get groupDetailInviteCode => 'Invite Code';

  @override
  String get groupDetailCodeCopied => 'Code copied to clipboard';

  @override
  String get groupDetailCopyCode => 'Copy Code';

  @override
  String get groupDetailShareInvite => 'Share Invite';

  @override
  String get groupDetailNeedTwoMembers =>
      'Need at least 2 members to record a payment';

  @override
  String get groupDetailRecordPayment => 'Record Payment';

  @override
  String get groupDetailFrom => 'From';

  @override
  String get groupDetailTo => 'To';

  @override
  String get groupDetailAmount => 'Amount';

  @override
  String get groupDetailRecord => 'Record';

  @override
  String get groupDetailUnknownMember => 'Unknown';

  @override
  String get groupDetailPaymentRecorded => 'Payment recorded';

  @override
  String groupDetailPaymentError(String error) {
    return 'Error recording payment: $error';
  }

  @override
  String get groupDetailAddMember => 'Add Member';

  @override
  String get groupDetailName => 'Name';

  @override
  String get groupDetailAdd => 'Add';

  @override
  String groupDetailMemberAdded(String name) {
    return '$name added to group';
  }

  @override
  String get groupDetailAddExpense => 'Add Expense';

  @override
  String get groupDetailMembers => 'Members';

  @override
  String get groupDetailStatistics => 'Statistics';

  @override
  String get groupDetailRename => 'Rename';

  @override
  String get groupDetailExportCsv => 'Export CSV';

  @override
  String get groupDetailExportPdf => 'Export PDF';

  @override
  String get groupDetailExpensesTab => 'Expenses';

  @override
  String get groupDetailBalancesTab => 'Balances';

  @override
  String get groupDetailActivityTab => 'Activity';

  @override
  String get groupDetailTotalYouAreOwed => 'You are owed in total';

  @override
  String get groupDetailTotalYouOwe => 'You owe in total';

  @override
  String get groupDetailAllSettled => 'All settled up';

  @override
  String get groupDetailToday => 'Today';

  @override
  String get groupDetailYesterday => 'Yesterday';

  @override
  String get groupDetailYouAreOwed => 'You are owed';

  @override
  String get groupDetailYouOwe => 'You owe';

  @override
  String get groupDetailFilterExpenses => 'Filter Expenses';

  @override
  String get groupDetailCategory => 'Category';

  @override
  String get groupDetailAll => 'All';

  @override
  String get groupDetailPaidBy => 'Paid by';

  @override
  String get groupDetailDateRange => 'Date range';

  @override
  String get groupDetailAllTime => 'All time';

  @override
  String groupDetailDateRangeValue(String start, String end) {
    return '$start — $end';
  }

  @override
  String get groupDetailClearDateFilter => 'Clear date filter';

  @override
  String get groupDetailResetAllFilters => 'Reset all filters';

  @override
  String get groupDetailNoExpenses => 'No expenses yet';

  @override
  String get groupDetailFirstExpense => 'Add first expense';

  @override
  String get groupDetailSearchExpenses => 'Search expenses…';

  @override
  String get groupDetailFilter => 'Filter';

  @override
  String groupDetailFilteredCount(int count, int total) {
    return '$count of $total expenses';
  }

  @override
  String get groupDetailClear => 'Clear';

  @override
  String get groupDetailSwipeHint => 'Swipe left on an expense to delete it';

  @override
  String get groupDetailGotIt => 'Got it';

  @override
  String get groupDetailNoMatchingExpenses => 'No matching expenses';

  @override
  String get groupDetailDeleteExpenseTitle => 'Delete Expense';

  @override
  String groupDetailDeleteExpenseMessage(String description, String amount) {
    return '\"$description\" ($amount) will be permanently deleted.';
  }

  @override
  String groupDetailPaidByName(String name) {
    return 'Paid by $name';
  }

  @override
  String get groupDetailWhoOwesWhom => 'WHO OWES WHOM';

  @override
  String get groupDetailNoBalances => 'No balances to show';

  @override
  String get groupDetailDebtsSimplified =>
      'Debts simplified — automatic netting active.';

  @override
  String get groupDetailSettleUp => 'Settle up';

  @override
  String get legalTitle => 'Legal';

  @override
  String get legalTabPrivacy => 'Privacy Policy';

  @override
  String get legalTabTerms => 'Terms of Service';

  @override
  String get legalPrivacyHeaderTitle => 'Privacy Policy';

  @override
  String get legalPrivacyHeaderSubtitle => 'Last updated: March 2026';

  @override
  String get legalPrivacySection1Title => '1. Data Controller';

  @override
  String get legalPrivacySection1Body =>
      'Split Genesis is operated by Salah AI Company (\"we\", \"us\", \"our\"). You can reach us at: legal@split-genesis.app\n\nAs the responsible party within the meaning of the DSGVO (GDPR), we are committed to protecting your personal data.';

  @override
  String get legalPrivacySection2Title => '2. What Data We Collect';

  @override
  String get legalPrivacySection2Body =>
      'We collect the minimum data necessary to operate Split Genesis:\n\n• Account data: email address and display name (provided by you at sign-up)\n• Group data: group names, member lists, expense descriptions and amounts\n• Device data: device type and app version (for crash reporting only)\n• Usage data: anonymous feature usage statistics (no personal identifiers)\n\nWe do NOT collect: location, contacts, microphone, camera, or advertising IDs.';

  @override
  String get legalPrivacySection3Title =>
      '3. Purpose and Legal Basis (Art. 6 DSGVO)';

  @override
  String get legalPrivacySection3Body =>
      'Your data is processed for the following purposes:\n\n• To provide the expense-splitting service (Art. 6(1)(b) DSGVO — contract performance)\n• To sync data across your devices via Supabase (Art. 6(1)(b) DSGVO)\n• To detect and fix technical errors (Art. 6(1)(f) DSGVO — legitimate interest)\n\nWe do not process your data for advertising or sell it to third parties.';

  @override
  String get legalPrivacySection4Title => '4. Data Storage and Processors';

  @override
  String get legalPrivacySection4Body =>
      'Your data is stored on Supabase infrastructure (PostgreSQL database) hosted in the EU (Frankfurt, Germany). Supabase B.V. acts as our data processor under a Data Processing Agreement (DPA) compliant with Art. 28 DSGVO.\n\nCrash reports are processed by our self-hosted Bugsink instance on Hetzner (Germany). No data is sent to third-party crash analytics providers.';

  @override
  String get legalPrivacySection5Title => '5. Retention Period';

  @override
  String get legalPrivacySection5Body =>
      'Account and expense data is retained for as long as your account is active. If you delete your account, all associated data (groups, expenses, members) is permanently deleted within 30 days.\n\nAnonymous usage statistics are retained for up to 12 months then auto-deleted.';

  @override
  String get legalPrivacySection6Title => '6. Your Rights (Art. 15–22 DSGVO)';

  @override
  String get legalPrivacySection6Body =>
      'You have the right to:\n\n• Access: request a copy of all data we hold about you (Art. 15)\n• Rectification: correct inaccurate data (Art. 16)\n• Erasure: delete your account and all data (\"right to be forgotten\", Art. 17)\n• Portability: export your data in machine-readable format (Art. 20)\n• Objection: object to processing based on legitimate interests (Art. 21)\n\nTo exercise your rights, contact us at: legal@split-genesis.app\n\nYou also have the right to lodge a complaint with your local supervisory authority (in Germany: the Datenschutzbeauftragter of your federal state).';

  @override
  String get legalPrivacySection7Title => '7. How to Delete Your Account';

  @override
  String get legalPrivacySection7Body =>
      'You can delete your account and all data at any time:\n\n1. Open Settings in Split Genesis\n2. Scroll to the bottom → \"Delete Account\"\n3. Confirm deletion — all data is queued for removal\n4. Complete deletion occurs within 30 days\n\nAlternatively, email us at legal@split-genesis.app with subject \"Account Deletion Request\".';

  @override
  String get legalPrivacySection8Title => '8. Children’s Privacy';

  @override
  String get legalPrivacySection8Body =>
      'Split Genesis is not directed at children under 13 (EU: under 16). We do not knowingly collect data from children. If you believe a child has provided us data, contact us immediately.';

  @override
  String get legalPrivacySection9Title => '9. Contact';

  @override
  String get legalPrivacySection9Body =>
      'Data protection questions: legal@split-genesis.app\nResponse time: within 30 days as required by Art. 12 DSGVO.';

  @override
  String get legalLinkPrivacyWeb => 'Full Privacy Policy (Web)';

  @override
  String get legalTermsHeaderTitle => 'Terms of Service';

  @override
  String get legalTermsHeaderSubtitle => 'Effective: March 2026';

  @override
  String get legalTermsSection1Title => '1. Acceptance';

  @override
  String get legalTermsSection1Body =>
      'By using Split Genesis, you agree to these Terms of Service. If you do not agree, do not use the app. These terms are governed by German law.';

  @override
  String get legalTermsSection2Title => '2. Service Description';

  @override
  String get legalTermsSection2Body =>
      'Split Genesis is an expense-splitting app that allows groups of people to track shared expenses and calculate who owes whom. The app is provided \"as is\" for personal, non-commercial use.';

  @override
  String get legalTermsSection3Title => '3. Account Responsibilities';

  @override
  String get legalTermsSection3Body =>
      '• You are responsible for maintaining the confidentiality of your account\n• You must provide accurate information during sign-up\n• You must not use the app for unlawful purposes\n• You must not attempt to reverse-engineer or disrupt the service\n• You are responsible for all activity under your account';

  @override
  String get legalTermsSection4Title => '4. User Content';

  @override
  String get legalTermsSection4Body =>
      'You retain ownership of all content you enter into Split Genesis (expense names, amounts, notes). By using the service, you grant us a limited license to store and process this content solely to provide the service to you and your group members.';

  @override
  String get legalTermsSection5Title => '5. Accuracy of Calculations';

  @override
  String get legalTermsSection5Body =>
      'Split Genesis performs expense calculations in good faith, but we cannot guarantee the accuracy of all calculations in all edge cases. Always verify important financial settlements independently. We are not liable for financial losses arising from incorrect calculations.';

  @override
  String get legalTermsSection6Title => '6. Service Availability';

  @override
  String get legalTermsSection6Body =>
      'We aim for high availability but do not guarantee 100% uptime. We may perform maintenance that causes temporary interruptions. We will notify users of planned downtime where possible.';

  @override
  String get legalTermsSection7Title => '7. Termination';

  @override
  String get legalTermsSection7Body =>
      'You may terminate your account at any time via Settings → Delete Account. We reserve the right to suspend or terminate accounts that violate these terms. Upon termination, your data is deleted per our Privacy Policy (30 days).';

  @override
  String get legalTermsSection8Title => '8. Limitation of Liability';

  @override
  String get legalTermsSection8Body =>
      'To the maximum extent permitted by applicable law, Split Genesis and Salah AI Company are not liable for indirect, incidental, or consequential damages. Our total liability is limited to amounts you paid to us in the past 12 months (or €50 if no payment was made).';

  @override
  String get legalTermsSection9Title => '9. Changes to Terms';

  @override
  String get legalTermsSection9Body =>
      'We may update these terms. Material changes will be notified in-app. Continued use after changes constitutes acceptance of the new terms.';

  @override
  String get legalTermsSection10Title => '10. Contact and Disputes';

  @override
  String get legalTermsSection10Body =>
      'For questions or disputes: legal@split-genesis.app\n\nApplicable law: Federal Republic of Germany\nJurisdiction: Courts of Hamburg, Germany\n\nEU Online Dispute Resolution: https://ec.europa.eu/consumers/odr';

  @override
  String get legalLinkTermsWeb => 'Full Terms of Service (Web)';

  @override
  String get settleUpTitle => 'Settle Up';

  @override
  String get settleUpOutstandingDebts => 'Outstanding debts';

  @override
  String settleUpLoadError(String error) {
    return 'Error loading: $error';
  }

  @override
  String get settleUpTryAgain => 'Try Again';

  @override
  String get settleUpAllSettledTitle => 'All settled up!';

  @override
  String settleUpNoDebtsIn(String groupName) {
    return 'No outstanding debts in \"$groupName\"';
  }

  @override
  String get settleUpBackToGroup => 'Back to Group';

  @override
  String settleUpOpenCount(int count) {
    return 'Open: $count';
  }

  @override
  String settleUpTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get settleUpSettleAllTitle => 'Settle all';

  @override
  String settleUpSettleAllMessage(int count) {
    return 'Mark all $count debts as settled? This updates the group balances.';
  }

  @override
  String settleUpSettleAllAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Settle $count debts',
      one: 'Settle 1 debt',
    );
    return '$_temp0';
  }

  @override
  String settleUpPartialPaidSnack(String from, String amount, String to) {
    return '$from paid $amount (partial) to $to';
  }

  @override
  String settleUpSettledSnack(String from, String amount, String to) {
    return '$from settled $amount with $to';
  }

  @override
  String get settleUpOwes => 'owes';

  @override
  String get settleUpAmount => 'Amount';

  @override
  String get settleUpAmountMustBePositive => 'Amount must be greater than 0';

  @override
  String settleUpCannotExceed(String amount) {
    return 'Cannot exceed $amount';
  }

  @override
  String settleUpOwesTo(String from, String to) {
    return '$from owes $to';
  }

  @override
  String settleUpOfTotal(String amount) {
    return 'of $amount total';
  }

  @override
  String get settleUpSettleFull => 'Settle full';

  @override
  String get settleUpPaymentMethod => 'Payment method';

  @override
  String get settleUpBankTransfer => 'Bank transfer';

  @override
  String get settleUpBankTransferComingSoon => 'Bank transfer: coming soon';

  @override
  String get settleUpChange => 'Change';

  @override
  String settleUpConfirmPaymentAmount(String amount) {
    return 'Confirm payment ($amount)';
  }

  @override
  String get settleUpConfirmPayment => 'Confirm payment';

  @override
  String get settleUpMarkedImmediately =>
      'The amount will be marked as settled immediately.';

  @override
  String get expenseDetailYou => 'You';

  @override
  String get expenseDetailUnknown => 'Unknown';

  @override
  String get expenseDetailTitle => 'Expense Details';

  @override
  String get expenseDetailPaidBy => 'Paid by';

  @override
  String get expenseDetailDate => 'Date';

  @override
  String get expenseDetailCategory => 'Category';

  @override
  String get expenseDetailSplitDetails => 'Split Details';

  @override
  String get expenseDetailReceipt => 'Receipt';

  @override
  String get expenseDetailReceiptLoadError => 'Could not load receipt';

  @override
  String get expenseDetailComments => 'Comments';

  @override
  String get expenseDetailBeFirstComment => 'Be the first to comment';

  @override
  String get expenseDetailAddCommentHint => 'Add a comment…';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityEmpty => 'No activity yet';

  @override
  String get activityEmptyCreateGroup => 'Create a group to get started';

  @override
  String get activityEmptyHint => 'Actions will appear here';

  @override
  String get activityJustNow => 'Just now';

  @override
  String activityMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String activityHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String activityDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get activityYesterday => 'Yesterday';

  @override
  String get activityToday => 'Today';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsYourNameHint => 'Your name';

  @override
  String get settingsTapToSetName => 'Tap to set your name';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDefaultCurrency => 'Default Currency';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsCurrencyHelp =>
      'Used as the default when creating new expenses.';

  @override
  String get settingsAboutHeader => 'About';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsAboutRow => 'About';

  @override
  String get settingsPrivacyTerms => 'Privacy & Terms';

  @override
  String get settingsBuiltWithFlutter => 'Built with Flutter';

  @override
  String get settingsMadeWithLove => 'Made with love';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutCopyright =>
      '© 2026 Split Genesis. All rights reserved.';

  @override
  String get settingsAboutClose => 'Close';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get groupSettingsRenameTitle => 'Change name';

  @override
  String get groupSettingsNameHint => 'Group name';

  @override
  String get groupSettingsSave => 'Save';

  @override
  String get groupSettingsChooseSymbol => 'Choose symbol';

  @override
  String get groupSettingsSymbolComingSoon => 'Saving symbol: coming soon';

  @override
  String get groupSettingsCurrencyComingSoon =>
      'Changing currency: coming soon';

  @override
  String get groupSettingsLeaveTitle => 'Leave group?';

  @override
  String get groupSettingsLeaveMessage =>
      'You’ll be removed from the member list. This action can’t be undone.';

  @override
  String get groupSettingsLeave => 'Leave';

  @override
  String get groupSettingsNotMember => 'You’re not a member of this group.';

  @override
  String get groupSettingsDeleteTitle => 'Delete group?';

  @override
  String get groupSettingsDeleteMessage =>
      'All expenses, members and activities of this group will be deleted. This can’t be undone.';

  @override
  String get groupSettingsName => 'Name';

  @override
  String get groupSettingsSymbol => 'Symbol';

  @override
  String get groupSettingsCurrency => 'Currency';

  @override
  String get groupSettingsManageMembers => 'Manage members';

  @override
  String get groupSettingsLeaveGroup => 'Leave group';

  @override
  String get groupSettingsDeleteGroup => 'Delete group';

  @override
  String get accountYou => 'You';

  @override
  String get accountTitle => 'Account';

  @override
  String accountDefaultCurrency(String currency) {
    return 'Default currency: $currency';
  }

  @override
  String get accountMyStats => 'MY STATISTICS';

  @override
  String get accountTotalSpent => 'Total spent';

  @override
  String get accountTotalSettled => 'Total settled';

  @override
  String get accountSettings => 'Settings';

  @override
  String get accountPersonalData => 'Personal details';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get accountBankDetails => 'Bank details';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountComingSoon(String feature) {
    return '$feature: coming soon';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsComingSoon => 'Coming soon';

  @override
  String get friendsComingSoonBody =>
      'Soon you’ll be able to add friends and settle up even without a group.';

  @override
  String get addExpenseTitle => 'New expense';

  @override
  String get addExpenseEditTitle => 'Edit expense';

  @override
  String get addExpenseWhatFor => 'What for?';

  @override
  String get addExpensePaidBy => 'Paid by';

  @override
  String get addExpenseSave => 'Save';

  @override
  String get addExpenseMoreDetails => 'More details';

  @override
  String get addExpenseCategoryLabel => 'Category';

  @override
  String get addExpenseCategorySection => 'CATEGORY';

  @override
  String get addExpenseSplitTypeLabel => 'Split type';

  @override
  String get addExpenseSplitEqual => 'Equal';

  @override
  String get addExpenseSplitExact => 'Exact';

  @override
  String get addExpenseSplitShares => 'Shares';

  @override
  String get addExpenseSplitAmong => 'Split among';

  @override
  String get addExpenseSplitLabel => 'Split';

  @override
  String get addExpenseSelectAll => 'Select All';

  @override
  String get addExpenseDeselectAll => 'Deselect All';

  @override
  String get addExpenseCategorySelectedHint => 'Selected category';

  @override
  String get addExpenseCategorySelectHint => 'Tap to select category';

  @override
  String get addExpenseDescriptionRequired => 'Please enter a description';

  @override
  String get addExpenseAmountRequired => 'Please enter an amount';

  @override
  String get addExpensePayerRequired => 'Please choose who paid';

  @override
  String get addExpenseSplitMembersRequired =>
      'Please select members to split with';

  @override
  String get addExpenseSelectPersonRequired =>
      'Please select at least one person';

  @override
  String addExpenseExactSumError(String amount) {
    return 'Amounts must add up to $amount';
  }

  @override
  String get addExpensePercentSumError => 'Percentages must add up to 100%';

  @override
  String get addExpenseSharesError => 'Please enter valid shares';

  @override
  String addExpenseSaveError(String error) {
    return 'Error saving expense: $error';
  }

  @override
  String addExpenseError(String error) {
    return 'Error: $error';
  }

  @override
  String addExpenseLoadError(String error) {
    return 'Error loading: $error';
  }

  @override
  String get addExpenseRetry => 'Try again';

  @override
  String get addExpenseApply => 'Apply';

  @override
  String addExpensePerPerson(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$amount per person ($_temp0)';
  }

  @override
  String addExpenseAmountRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String addExpenseAmountOver(String amount) {
    return '$amount over';
  }

  @override
  String get addExpenseAmountsMatch => 'Amounts match';

  @override
  String get addExpensePercentagesMatch => 'Percentages match (100%)';

  @override
  String addExpenseTotalShares(String shares) {
    return 'Total shares: $shares';
  }

  @override
  String get addExpenseRecurring => 'Recurring';

  @override
  String get addExpenseCustomizeSplit => 'Customize split →';

  @override
  String get addExpenseCustomizeSplitSoon => 'Customize split: coming soon';

  @override
  String get addExpenseDateToday => 'Today';

  @override
  String get addExpenseDateYesterday => 'Yesterday';

  @override
  String get addExpenseCategoryMore => 'More';

  @override
  String get addExpenseCategoryFood => 'Food';

  @override
  String get addExpenseCategoryGroceries => 'Groceries';

  @override
  String get addExpenseCategoryTravel => 'Travel';

  @override
  String get memberDetailLoadError => 'Failed to load member details';

  @override
  String get memberDetailTransactionHistory => 'Transaction History';

  @override
  String get memberDetailNoTransactions => 'No transactions yet';

  @override
  String get memberDetailGetsBack => 'gets back';

  @override
  String get memberDetailOwes => 'owes';

  @override
  String get memberDetailStatPaidFor => 'Paid for';

  @override
  String get memberDetailStatInvolvedIn => 'Involved in';

  @override
  String get memberDetailStatSettlements => 'Settlements';

  @override
  String memberDetailYouPaid(String amount) {
    return 'You paid $amount';
  }

  @override
  String memberDetailYourShare(String amount) {
    return 'Your share $amount';
  }

  @override
  String memberDetailPaymentFrom(String name) {
    return 'Payment from $name';
  }

  @override
  String memberDetailPaymentTo(String name) {
    return 'Payment to $name';
  }

  @override
  String get memberDetailReceived => 'Received';

  @override
  String get memberDetailSent => 'Sent';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsFilterThisMonth => 'This month';

  @override
  String get statsFilterAll => 'All';

  @override
  String get statsErrorStatistics => 'Error loading statistics';

  @override
  String get statsErrorPayerData => 'Error loading payer data';

  @override
  String get statsErrorMemberData => 'Error loading member data';

  @override
  String get statsEmptyTitle => 'No expenses yet';

  @override
  String get statsTotalGroupSpend => 'Total Group Spend';

  @override
  String statsExpensesRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses recorded',
      one: '1 expense recorded',
    );
    return '$_temp0';
  }

  @override
  String get statsByCategory => 'By Category';

  @override
  String get statsMonthlySpending => 'Monthly Spending';

  @override
  String get statsPerMemberPaid => 'Per Member Paid';

  @override
  String get statsUnknownMember => 'Unknown';

  @override
  String get manageMembersTitle => 'Members';

  @override
  String get manageMembersAddSection => 'ADD MEMBER';

  @override
  String get manageMembersNamePlaceholder => 'New member name…';

  @override
  String get manageMembersMembersSection => 'MEMBERS';

  @override
  String get manageMembersEmpty => 'No members yet';

  @override
  String get manageMembersSwipeHint => 'Swipe left to remove a member.';

  @override
  String get manageMembersRemoveTitle => 'Remove Member';

  @override
  String manageMembersRemoveMessage(String name) {
    return 'Remove \"$name\" from this group?';
  }

  @override
  String get manageMembersRemoveAction => 'Remove';

  @override
  String manageMembersCannotRemove(String name) {
    return 'Cannot remove $name — they have linked expenses';
  }
}
