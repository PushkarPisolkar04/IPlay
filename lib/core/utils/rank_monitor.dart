import '../services/leaderboard_service.dart';

/// Utility to monitor rank changes after XP updates
class RankMonitor {
  static final LeaderboardService _leaderboardService = LeaderboardService();

  /// Check for rank changes and send notifications
  /// Call this after any XP update
  static Future<void> checkRankChanges(String userId) async {
    try {
      await _leaderboardService.monitorUserRankChanges(userId: userId);
    } catch (e) {
      // Silently fail - rank monitoring is not critical
    }
  }
}
