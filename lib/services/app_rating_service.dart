import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

/// Service for managing app rating prompts
class AppRatingService {
  static const String _realmsCompletedKey = 'realms_completed_count';
  static const String _gamesPlayedKey = 'games_played_count';
  static const String _lastRatingPromptKey = 'last_rating_prompt_date';
  static const String _hasRatedKey = 'has_rated_app';

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Check if rating prompt should be shown
  static Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if user has already rated
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) return false;

    // Check last prompt date (don't show more than once per month)
    final lastPromptDate = prefs.getString(_lastRatingPromptKey);
    if (lastPromptDate != null) {
      final lastPrompt = DateTime.parse(lastPromptDate);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSinceLastPrompt < 30) return false;
    }

    // Check if user has completed 5 realms
    final realmsCompleted = prefs.getInt(_realmsCompletedKey) ?? 0;
    if (realmsCompleted >= 5) return true;

    // Check if user has played 10 games
    final gamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 0;
    if (gamesPlayed >= 10) return true;

    return false;
  }

  /// Show rating prompt
  static Future<void> showRatingPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if in-app review is available
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        
        // Update last prompt date
        await prefs.setString(
          _lastRatingPromptKey,
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      // print('Error showing rating prompt: $e');
    }
  }

  /// Open app store for rating
  static Future<void> openAppStore() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'YOUR_APP_STORE_ID', // TODO: Replace with actual App Store ID
      );
    } catch (e) {
      // print('Error opening app store: $e');
    }
  }

  /// Increment realms completed count
  static Future<void> incrementRealmsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_realmsCompletedKey) ?? 0;
    await prefs.setInt(_realmsCompletedKey, currentCount + 1);
    
    // Check if we should show rating prompt
    if (await shouldShowRatingPrompt()) {
      await showRatingPrompt();
    }
  }

  /// Increment games played count
  static Future<void> incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_gamesPlayedKey) ?? 0;
    await prefs.setInt(_gamesPlayedKey, currentCount + 1);
    
    // Check if we should show rating prompt
    if (await shouldShowRatingPrompt()) {
      await showRatingPrompt();
    }
  }

  /// Mark app as rated
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  /// Get realms completed count
  static Future<int> getRealmsCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_realmsCompletedKey) ?? 0;
  }

  /// Get games played count
  static Future<int> getGamesPlayedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gamesPlayedKey) ?? 0;
  }

  /// Reset rating prompt data (for testing)
  static Future<void> resetRatingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_realmsCompletedKey);
    await prefs.remove(_gamesPlayedKey);
    await prefs.remove(_lastRatingPromptKey);
    await prefs.remove(_hasRatedKey);
  }
}
