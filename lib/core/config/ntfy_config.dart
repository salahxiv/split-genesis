/// ntfy.sh configuration for self-hosted push notifications.
///
/// CEO policy: self-hosted first — no vendor lock-in.
/// Default points to the public ntfy.sh server.
/// To use a self-hosted instance (e.g. on Hetzner):
///   1. Deploy ntfy: `docker run -p 80:80 binwiederhier/ntfy serve`
///   2. Change [ntfyBaseUrl] to your server URL, e.g. "https://ntfy.yourdomain.com"
class NtfyConfig {
  NtfyConfig._();

  /// Base URL of the ntfy server.
  /// Override with your self-hosted instance URL.
  ///
  /// Example (public):    "https://ntfy.sh"
  /// Example (Hetzner):   "https://ntfy.example.com"
  static const String ntfyBaseUrl = String.fromEnvironment(
    'NTFY_BASE_URL',
    defaultValue: 'https://ntfy.sh',
  );

  /// Topic prefix to avoid collisions on the public server.
  /// Topics are constructed as: "$topicPrefix-$groupUuid"
  ///
  /// On a self-hosted server this can be left empty ("").
  static const String topicPrefix = String.fromEnvironment(
    'NTFY_TOPIC_PREFIX',
    defaultValue: 'splitgenesis',
  );

  /// Optional Bearer token for authenticated ntfy instances.
  /// Leave empty for public/open server.
  ///
  /// Set via:  flutter run --dart-define=NTFY_TOKEN=tk_yourtoken
  static const String ntfyToken = String.fromEnvironment(
    'NTFY_TOKEN',
    defaultValue: '',
  );

  /// Build the topic name for a given group UUID.
  /// Format: "{prefix}-{groupUuid}" (public) or "{groupUuid}" (self-hosted).
  static String topicForGroup(String groupUuid) {
    if (topicPrefix.isEmpty) return groupUuid;
    return '$topicPrefix-$groupUuid';
  }
}
