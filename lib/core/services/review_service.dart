import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles in-app review prompting logic.
/// Rules:
///   - Trigger after 3 successful Settle-Ups (not before the first!)
///   - 90-day cooldown between prompts
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const String _completedSettleUpsKey = 'review_completed_settle_ups';
  static const String _lastReviewPromptKey = 'review_last_prompt_date';
  static const int _requiredSettleUps = 3;
  static const int _cooldownDays = 90;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Call this after every successful Settle-Up.
  /// Increments the counter and triggers review prompt when eligible.
  Future<void> onSettleUpCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    // Increment settle-up counter
    final currentCount = prefs.getInt(_completedSettleUpsKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_completedSettleUpsKey, newCount);

    // Only attempt review if we've hit the threshold
    if (newCount < _requiredSettleUps) return;

    // Check 90-day cooldown
    final lastPromptMs = prefs.getInt(_lastReviewPromptKey);
    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      final daysSince = DateTime.now().difference(lastPrompt).inDays;
      if (daysSince < _cooldownDays) return;
    }

    // All conditions met — request review
    await _requestReview(prefs);
  }

  Future<void> _requestReview(SharedPreferences prefs) async {
    final isAvailable = await _inAppReview.isAvailable();
    if (!isAvailable) return;

    await _inAppReview.requestReview();

    // Record timestamp so cooldown applies
    await prefs.setInt(
      _lastReviewPromptKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// For testing/debugging: reset all counters
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedSettleUpsKey);
    await prefs.remove(_lastReviewPromptKey);
  }
}
