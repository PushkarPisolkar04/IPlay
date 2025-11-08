import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sound_service.dart';
import 'leaderboard_service.dart';

/// XP Service - Handles all XP calculations and rewards
class XPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

  // XP Constants from documentation
  static const int DAILY_XP_CAP = 1000;
  static const int REALM_COMPLETION_BONUS = 300;
  static const int FIRST_LOGIN_BONUS = 10;
  static const int SEVEN_DAY_STREAK_BONUS = 100;

  // Level Difficulty XP (base values)
  static const Map<String, int> DIFFICULTY_XP = {
    'easy': 50,
    'medium': 100,
    'hard': 150,
    'expert': 200,
  };

  // Replay XP reduction percentages
  static const List<double> REPLAY_XP_MULTIPLIERS = [
    1.0,   // 1st attempt: 100%
    0.25,  // 2nd attempt: 25%
    0.10,  // 3rd attempt: 10%
    0.0,   // 4th+ attempt: 0%
  ];

  /// Calculate XP for completing a level based on difficulty and attempts
  int calculateLevelXP({
    required String difficulty,
    required int attemptCount,
    int? customXP,
  }) {
    // Use custom XP if provided, otherwise use difficulty tier
    final baseXP = customXP ?? DIFFICULTY_XP[difficulty.toLowerCase()] ?? 100;

    // Apply replay multiplier
    final multiplierIndex = (attemptCount - 1).clamp(0, REPLAY_XP_MULTIPLIERS.length - 1);
    final multiplier = REPLAY_XP_MULTIPLIERS[multiplierIndex];

    return (baseXP * multiplier).round();
  }

  /// Check if user has reached daily XP cap
  /// Returns: {hasReachedCap: bool, currentDailyXP: int, remainingXP: int}
  Future<Map<String, dynamic>> checkDailyXPCap(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query all progress updates from today
      final todayProgress = await _firestore
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .where('lastAttemptAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('lastAttemptAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int totalDailyXP = 0;
      for (final doc in todayProgress.docs) {
        totalDailyXP += (doc.data()['xpEarned'] as int?) ?? 0;
      }

      final hasReachedCap = totalDailyXP >= DAILY_XP_CAP;
      final remainingXP = (DAILY_XP_CAP - totalDailyXP).clamp(0, DAILY_XP_CAP);

      return {
        'hasReachedCap': hasReachedCap,
        'currentDailyXP': totalDailyXP,
        'remainingXP': remainingXP,
      };
    } catch (e) {
      // print('Error checking daily XP cap: $e');
      return {
        'hasReachedCap': false,
        'currentDailyXP': 0,
        'remainingXP': DAILY_XP_CAP,
      };
    }
  }

  /// Award first login of day bonus
  /// Returns XP awarded (10 if eligible, 0 if already claimed today)
  Future<int> awardFirstLoginBonus(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final lastActiveDate = (userData['lastActiveDate'] as Timestamp?)?.toDate();

      if (lastActiveDate == null) {
        // First time logging in
        await _firestore.collection('users').doc(userId).update({
          'totalXP': FieldValue.increment(FIRST_LOGIN_BONUS),
          'lastActiveDate': Timestamp.now(),
        });
        // Play XP gain sound
        SoundService.playXPGain();
        return FIRST_LOGIN_BONUS;
      }

      final now = DateTime.now();
      final lastActiveDay = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
      final today = DateTime(now.year, now.month, now.day);

      // Check if it's a new day
      if (today.isAfter(lastActiveDay)) {
        await _firestore.collection('users').doc(userId).update({
          'totalXP': FieldValue.increment(FIRST_LOGIN_BONUS),
          'lastActiveDate': Timestamp.now(),
        });
        // Play XP gain sound
        SoundService.playXPGain();
        return FIRST_LOGIN_BONUS;
      }

      return 0; // Already logged in today
    } catch (e) {
      // print('Error awarding first login bonus: $e');
      return 0;
    }
  }

  /// Award 7-day streak milestone bonus
  /// Returns XP awarded (100 if user has 7+ day streak, 0 otherwise)
  Future<int> awardStreakMilestoneBonus(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final currentStreak = userData['currentStreak'] as int? ?? 0;

      // Check if user just reached 7-day streak (or multiples of 7)
      if (currentStreak > 0 && currentStreak % 7 == 0) {
        // Check if we already awarded bonus for this streak milestone
        final lastStreakBonusAt = userData['lastStreakBonusAt'] as Timestamp?;
        final now = DateTime.now();

        if (lastStreakBonusAt == null || 
            now.difference(lastStreakBonusAt.toDate()).inDays >= 7) {
          await _firestore.collection('users').doc(userId).update({
            'totalXP': FieldValue.increment(SEVEN_DAY_STREAK_BONUS),
            'lastStreakBonusAt': Timestamp.now(),
          });
          // Play XP gain sound
          SoundService.playXPGain();
          return SEVEN_DAY_STREAK_BONUS;
        }
      }

      return 0;
    } catch (e) {
      // print('Error awarding streak milestone bonus: $e');
      return 0;
    }
  }

  /// Award realm completion bonus
  /// Returns XP awarded (300 if realm is completed, 0 otherwise)
  Future<int> awardRealmCompletionBonus({
    required String userId,
    required String realmId,
    required int levelsCompleted,
    required int totalLevels,
  }) async {
    try {
      // Check if realm is fully completed
      if (levelsCompleted < totalLevels) return 0;

      // Check if we already awarded completion bonus for this realm
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final progressSummary = userData['progressSummary'] as Map<String, dynamic>? ?? {};
      final realmProgress = progressSummary[realmId] as Map<String, dynamic>? ?? {};
      
      final completionBonusAwarded = realmProgress['completionBonusAwarded'] as bool? ?? false;

      if (!completionBonusAwarded) {
        await _firestore.collection('users').doc(userId).update({
          'totalXP': FieldValue.increment(REALM_COMPLETION_BONUS),
          'progressSummary.$realmId.completionBonusAwarded': true,
        });
        // Play XP gain sound
        SoundService.playXPGain();
        return REALM_COMPLETION_BONUS;
      }

      return 0;
    } catch (e) {
      // print('Error awarding realm completion bonus: $e');
      return 0;
    }
  }

  /// Calculate actual XP to award considering daily cap
  /// Returns: {xpToAward: int, cappedAmount: int, warning: bool}
  Future<Map<String, dynamic>> calculateAwardedXP({
    required String userId,
    required int earnedXP,
  }) async {
    final capStatus = await checkDailyXPCap(userId);
    final remainingXP = capStatus['remainingXP'] as int;
    final hasReachedCap = capStatus['hasReachedCap'] as bool;

    if (hasReachedCap) {
      return {
        'xpToAward': 0,
        'cappedAmount': earnedXP,
        'warning': true,
        'message': 'Daily XP cap reached! Come back tomorrow to earn more XP.',
      };
    }

    if (earnedXP > remainingXP) {
      return {
        'xpToAward': remainingXP,
        'cappedAmount': earnedXP - remainingXP,
        'warning': true,
        'message': 'You\'re close to your daily XP cap! You earned $remainingXP XP (${ earnedXP - remainingXP} XP capped).',
      };
    }

    return {
      'xpToAward': earnedXP,
      'cappedAmount': 0,
      'warning': false,
      'message': null,
    };
  }

  /// Get user's XP stats for today
  Future<Map<String, dynamic>> getTodayXPStats(String userId) async {
    final capStatus = await checkDailyXPCap(userId);
    final currentDailyXP = capStatus['currentDailyXP'] as int;
    final remainingXP = capStatus['remainingXP'] as int;
    final progressPercentage = (currentDailyXP / DAILY_XP_CAP * 100).round();

    return {
      'currentDailyXP': currentDailyXP,
      'dailyXPCap': DAILY_XP_CAP,
      'remainingXP': remainingXP,
      'progressPercentage': progressPercentage,
      'hasReachedCap': capStatus['hasReachedCap'],
    };
  }

  /// Award XP and check for rank changes
  /// This is a convenience method that awards XP and triggers rank change notifications
  Future<void> awardXPAndCheckRank({
    required String userId,
    required int xpAmount,
  }) async {
    try {
      // Award the XP
      await _firestore.collection('users').doc(userId).update({
        'totalXP': FieldValue.increment(xpAmount),
      });

      // Check for rank changes and send notifications if needed
      // Run this asynchronously to not block the XP award
      _leaderboardService.monitorUserRankChanges(userId: userId).catchError((e) {
        // print('Error monitoring rank changes: $e');
      });
    } catch (e) {
      // print('Error awarding XP and checking rank: $e');
    }
  }
}

