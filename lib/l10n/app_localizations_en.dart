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
}
