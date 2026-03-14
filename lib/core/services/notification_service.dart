import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../config/ntfy_config.dart';

/// Handles both local (on-device) and remote (ntfy.sh) push notifications.
///
/// ## Architecture
/// - **Local notifications**: shown via [flutter_local_notifications] for
///   immediate in-app feedback (current user's device).
/// - **ntfy.sh push**: sent via HTTP POST so *other* group members receive
///   a push notification on their devices (they subscribe to the group topic).
///
/// ## ntfy.sh Topic Strategy
/// Each group gets a unique topic derived from its UUID:
///   `splitgenesis-{groupUuid}` (public server)
///   `{groupUuid}` (self-hosted server with [NtfyConfig.topicPrefix] = "")
///
/// Users subscribe to their groups' topics using the ntfy app or any ntfy client.
///
/// ## Self-hosted Setup (CEO / Hetzner)
/// ```
/// docker run -p 80:80 binwiederhier/ntfy serve
/// ```
/// Then set `NTFY_BASE_URL=https://ntfy.yourdomain.com` via `--dart-define`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ──────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────

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

  // ──────────────────────────────────────────────
  // Local notification helpers
  // ──────────────────────────────────────────────

  Future<void> _showLocal({
    required String title,
    required String body,
    String channel = 'expenses',
    String channelName = 'Expenses',
    String channelDescription = 'Expense notifications',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ──────────────────────────────────────────────
  // ntfy.sh remote push
  // ──────────────────────────────────────────────

  /// Send a push notification to all subscribers of [groupUuid]'s topic.
  ///
  /// Uses HTTP POST to the ntfy server as documented at https://ntfy.sh/docs/publish/
  ///
  /// Headers supported:
  ///   - `Title`: notification title
  ///   - `Priority`: 1 (min) – 5 (max), default 3
  ///   - `Tags`: comma-separated ntfy emoji tags, e.g. "money_with_wings"
  ///   - `Authorization`: Bearer token (if self-hosted + auth enabled)
  Future<void> _sendNtfy({
    required String groupUuid,
    required String title,
    required String body,
    String priority = '3',
    String tags = '',
  }) async {
    final topic = NtfyConfig.topicForGroup(groupUuid);
    final url = Uri.parse('${NtfyConfig.ntfyBaseUrl}/$topic');

    final headers = <String, String>{
      'Content-Type': 'text/plain; charset=utf-8',
      'Title': title,
      'Priority': priority,
      if (tags.isNotEmpty) 'Tags': tags,
      if (NtfyConfig.ntfyToken.isNotEmpty)
        'Authorization': 'Bearer ${NtfyConfig.ntfyToken}',
    };

    try {
      final response = await http
          .post(url, headers: headers, body: utf8.encode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        // Log but don't throw — push failure should never crash the app
        // ignore: avoid_print
        print(
          '[ntfy] Push failed for topic $topic: '
          'HTTP ${response.statusCode} — ${response.body}',
        );
      }
    } catch (e) {
      // Network error: silently ignore (offline-first app)
      // ignore: avoid_print
      print('[ntfy] Push error for topic $topic: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Public API — Expense events
  // ──────────────────────────────────────────────

  /// Notify group members that a new expense was added.
  ///
  /// Call this after successfully persisting the expense to the database.
  Future<void> showExpenseAdded({
    required String groupName,
    required String description,
    required double amount,
    required String paidByName,
    String? groupUuid,
  }) async {
    final title = 'New expense in $groupName';
    final body =
        '$paidByName paid \$${amount.toStringAsFixed(2)} for $description';

    // Local notification for the current user
    await _showLocal(title: title, body: body);

    // Remote push for other group members
    if (groupUuid != null) {
      await _sendNtfy(
        groupUuid: groupUuid,
        title: title,
        body: body,
        priority: '3',
        tags: 'money_with_wings',
      );
    }
  }

  /// Notify group members that an expense was updated.
  Future<void> showExpenseUpdated({
    required String groupName,
    required String description,
    String? groupUuid,
  }) async {
    final title = 'Expense updated in $groupName';

    await _showLocal(title: title, body: description);

    if (groupUuid != null) {
      await _sendNtfy(
        groupUuid: groupUuid,
        title: title,
        body: description,
        priority: '2',
        tags: 'pencil',
      );
    }
  }

  // ──────────────────────────────────────────────
  // Public API — Debt events
  // ──────────────────────────────────────────────

  /// Notify group members that a debt was settled.
  Future<void> showDebtSettled({
    required String groupName,
    required String settledByName,
    required double amount,
    required String owedToName,
    String? groupUuid,
  }) async {
    final title = 'Debt settled in $groupName';
    final body =
        '$settledByName settled \$${amount.toStringAsFixed(2)} with $owedToName';

    await _showLocal(
      title: title,
      body: body,
      channel: 'settlements',
      channelName: 'Settlements',
      channelDescription: 'Debt settlement notifications',
    );

    if (groupUuid != null) {
      await _sendNtfy(
        groupUuid: groupUuid,
        title: title,
        body: body,
        priority: '3',
        tags: 'white_check_mark',
      );
    }
  }

  // ──────────────────────────────────────────────
  // Public API — Member events
  // ──────────────────────────────────────────────

  /// Notify group members that a new member joined.
  Future<void> showMemberJoined({
    required String groupName,
    required String memberName,
    String? groupUuid,
  }) async {
    final title = 'New member in $groupName';
    final body = '$memberName joined the group.';

    await _showLocal(
      title: title,
      body: body,
      channel: 'members',
      channelName: 'Members',
      channelDescription: 'Group membership notifications',
    );

    if (groupUuid != null) {
      await _sendNtfy(
        groupUuid: groupUuid,
        title: title,
        body: body,
        priority: '2',
        tags: 'wave',
      );
    }
  }

  /// Notify group members that a member left.
  Future<void> showMemberLeft({
    required String groupName,
    required String memberName,
    String? groupUuid,
  }) async {
    final title = 'Member left $groupName';
    final body = '$memberName left the group.';

    await _showLocal(
      title: title,
      body: body,
      channel: 'members',
      channelName: 'Members',
      channelDescription: 'Group membership notifications',
    );

    if (groupUuid != null) {
      await _sendNtfy(
        groupUuid: groupUuid,
        title: title,
        body: body,
        priority: '2',
        tags: 'wave',
      );
    }
  }
}
