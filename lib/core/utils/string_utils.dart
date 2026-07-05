/// String helpers used across the app.
library;

/// Single-character avatar initial.
///
/// Returns the first non-whitespace character of [name] in upper case, or
/// `'?'` for empty / whitespace-only input. Crash-safe — callers don't have
/// to guard against empty names anymore.
String getInitial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}
