import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> showExpenseAdded({
    required String groupName,
    required String description,
    required double amount,
    required String paidByName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'expenses',
      'Expenses',
      channelDescription: 'Expense notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Expense added to $groupName',
      '$paidByName paid \$${amount.toStringAsFixed(2)} for $description',
      details,
    );
  }

  Future<void> showExpenseUpdated({
    required String groupName,
    required String description,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'expenses',
      'Expenses',
      channelDescription: 'Expense notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Expense updated in $groupName',
      description,
      details,
    );
  }
}
