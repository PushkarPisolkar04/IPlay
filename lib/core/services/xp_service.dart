import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_service.dart';
import 'badge_service.dart';
import '../../services/streak_service.dart';

/// XP Service - Handles all XP calculations and rewards
class XPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final BadgeService _badgeService = BadgeService();
  final StreakService _streakService = StreakService();

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
    1.0, // 1st attempt: 100%
    0.25, // 2nd attempt: 25%
    0.10, // 3rd attempt: 10%
    0.0, // 4th+ attempt: 0%
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
    final multiplierIndex = (attemptCount - 1).clamp(
      0,
      REPLAY_XP_MULTIPLIERS.length - 1,
    );
    final multiplier = REPLAY_XP_MULTIPLIERS[multiplierIndex];

    return (baseXP * multiplier).round();
  }

  /// Check if user has reached daily XP cap
  /// Returns: {hasReachedCap: bool, currentDailyXP: int, remainingXP: int}
  ///
  /// IMPORTANT: This method checks XP from multiple sources:
  /// - Level completions (progress collection)
  /// - Daily challenges (daily_challenge_attempts collection)
  ///
  /// NOTE: Game XP is NOT included here because game_progress.totalXPEarned is cumulative.
  /// However, game XP is still capped because awardGameXP() calls calculateAwardedXP()
  /// before awarding XP. For accurate daily XP tracking across all sources, consider
  /// implementing a daily_xp_log collection that logs all XP awards with timestamps.
  Future<Map<String, dynamic>> checkDailyXPCap(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final startTimestamp = Timestamp.fromDate(startOfDay);
      final endTimestamp = Timestamp.fromDate(endOfDay);

      int totalDailyXP = 0;

      // 1. Check level completions from progress collection
      try {
        final todayProgress = await _firestore
            .collection('progress')
            .where('userId', isEqualTo: userId)
            .where('lastAttemptAt', isGreaterThanOrEqualTo: startTimestamp)
            .where('lastAttemptAt', isLessThan: endTimestamp)
            .get();

        for (final doc in todayProgress.docs) {
          totalDailyXP += (doc.data()['xpEarned'] as int?) ?? 0;
        }
      } catch (e) {
        print('⚠️ Error checking progress XP: $e');
      }

      // 2. Check daily challenge attempts
      try {
        final challengeAttempts = await _firestore
            .collection('daily_challenge_attempts')
            .where('userId', isEqualTo: userId)
            .where('attemptedAt', isGreaterThanOrEqualTo: startTimestamp)
            .where('attemptedAt', isLessThan: endTimestamp)
            .get();

        for (final doc in challengeAttempts.docs) {
          totalDailyXP += (doc.data()['xpEarned'] as int?) ?? 0;
        }
      } catch (e) {
        print('⚠️ Error checking daily challenge XP: $e');
      }

      // Note: Game XP is enforced at award time via calculateAwardedXP() in awardGameXP()
      // but cannot be accurately tracked here because game_progress.totalXPEarned is cumulative.
      // This means the displayed daily XP might be slightly inaccurate, but users cannot
      // exceed the cap because each service enforces it before awarding XP.

      final hasReachedCap = totalDailyXP >= DAILY_XP_CAP;
      final remainingXP = (DAILY_XP_CAP - totalDailyXP).clamp(0, DAILY_XP_CAP);

      return {
        'hasReachedCap': hasReachedCap,
        'currentDailyXP': totalDailyXP,
        'remainingXP': remainingXP,
      };
    } catch (e) {
      print('❌ Error checking daily XP cap: $e');
      return {
        'hasReachedCap': false,
        'currentDailyXP': 0,
        'remainingXP': DAILY_XP_CAP,
      };
    }
  }

  /// Award first login of day bonus
  /// Returns XP awarded (10 if eligible, 0 if already claimed today or cap reached)
  /// Note: This method does NOT update streaks - streaks are updated when XP is earned through activities
  /// Enforces daily XP cap before awarding
  Future<int> awardFirstLoginBonus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final lastActiveDate = (userData['lastActiveDate'] as Timestamp?)
          ?.toDate();

      if (lastActiveDate == null) {
        // First time logging in - initialize lastActiveDate
        await _firestore.collection('users').doc(userId).update({
          'totalXP': FieldValue.increment(FIRST_LOGIN_BONUS),
          'lastActiveDate': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        return FIRST_LOGIN_BONUS;
      }

      final now = DateTime.now();
      final lastActiveDay = DateTime(
        lastActiveDate.year,
        lastActiveDate.month,
        lastActiveDate.day,
      );
      final today = DateTime(now.year, now.month, now.day);

      // Check if it's a new day
      if (today.isAfter(lastActiveDay)) {
        // Enforce daily XP cap before awarding
        final xpCapResult = await calculateAwardedXP(
          userId: userId,
          earnedXP: FIRST_LOGIN_BONUS,
        );
        final xpToAward = (xpCapResult['xpToAward'] as int?) ?? 0;

        if (xpToAward > 0) {
          // Award bonus but DON'T update lastActiveDate (let actual activities do that)
          await _firestore.collection('users').doc(userId).update({
            'totalXP': FieldValue.increment(xpToAward),
            'updatedAt': Timestamp.now(),
          });
          return xpToAward;
        }
        return 0; // Cap reached
      }

      return 0; // Already logged in today
    } catch (e) {
      print('❌ Error awarding first login bonus: $e');
      return 0;
    }
  }

  /// Award 7-day streak milestone bonus
  /// Returns XP awarded (100 if user has 7+ day streak, 0 otherwise)
  Future<int> awardStreakMilestoneBonus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

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
          // Enforce daily XP cap before awarding
          final xpCapResult = await calculateAwardedXP(
            userId: userId,
            earnedXP: SEVEN_DAY_STREAK_BONUS,
          );
          final xpToAward = (xpCapResult['xpToAward'] as int?) ?? 0;

          if (xpToAward > 0) {
            await _firestore.collection('users').doc(userId).update({
              'totalXP': FieldValue.increment(xpToAward),
              'lastStreakBonusAt': Timestamp.now(),
            });
            return xpToAward;
          }
          return 0; // Cap reached
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
  /// Note: Streaks are already updated by completeLevel, but we check badges here
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
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data()!;
      final progressSummary =
          userData['progressSummary'] as Map<String, dynamic>? ?? {};
      final realmProgress =
          progressSummary[realmId] as Map<String, dynamic>? ?? {};

      final completionBonusAwarded =
          realmProgress['completionBonusAwarded'] as bool? ?? false;

      if (!completionBonusAwarded) {
        // Enforce daily XP cap before awarding
        final xpCapResult = await calculateAwardedXP(
          userId: userId,
          earnedXP: REALM_COMPLETION_BONUS,
        );
        final xpToAward = (xpCapResult['xpToAward'] as int?) ?? 0;

        if (xpToAward > 0) {
          await _firestore.collection('users').doc(userId).update({
            'totalXP': FieldValue.increment(xpToAward),
            'progressSummary.$realmId.completionBonusAwarded': true,
            'updatedAt': Timestamp.now(),
          });

          print('✅ Awarded $xpToAward XP realm completion bonus for $realmId');
          return xpToAward;
        }
        // Still mark as awarded even if cap reached, to prevent retry
        await _firestore.collection('users').doc(userId).update({
          'progressSummary.$realmId.completionBonusAwarded': true,
          'updatedAt': Timestamp.now(),
        });
        return 0; // Cap reached
      }

      return 0;
    } catch (e) {
      print('❌ Error awarding realm completion bonus: $e');
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
        'message':
            'You\'re close to your daily XP cap! You earned $remainingXP XP (${earnedXP - remainingXP} XP capped).',
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
  /// Also updates streaks and checks for badges
  Future<void> awardXPAndCheckRank({
    required String userId,
    required int xpAmount,
  }) async {
    try {
      // Award the XP (DON'T update lastActiveDate - let StreakService handle it)
      await _firestore.collection('users').doc(userId).update({
        'totalXP': FieldValue.increment(xpAmount),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Awarded $xpAmount XP to user $userId');

      // Update streak BEFORE checking badges
      await _streakService.updateStreakOnActivity(userId);

      // Check for new badges
      final newBadges = await _badgeService.checkAndAwardBadges(userId);
      if (newBadges.isNotEmpty) {
        print('✅ New badges unlocked: $newBadges');
      }

      // Check for rank changes and send notifications if needed
      // Run this asynchronously to not block the XP award
      _leaderboardService.monitorUserRankChanges(userId: userId).catchError((
        e,
      ) {
        print('⚠️ Error monitoring rank changes: $e');
      });
    } catch (e) {
      print('❌ Error awarding XP and checking rank: $e');
    }
  }
}
