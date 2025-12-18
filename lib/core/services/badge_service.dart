import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/badge_model.dart';
import 'badge_animation_queue.dart';
import '../utils/rank_monitor.dart';
import 'xp_service.dart';

/// Service to manage badge unlocking and tracking
/// Reads badge definitions from Firestore /badges collection
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeAnimationQueue _animationQueue = BadgeAnimationQueue();

  // Cache for badge definitions
  List<BadgeModel>? _badgeCache;

  /// Get all badge definitions from local JSON file
  Future<List<BadgeModel>> getAllBadges() async {
    // Return cached badges if available
    if (_badgeCache != null) return _badgeCache!;

    try {
      // Load from local JSON file
      final String jsonString = await rootBundle.loadString(
        'content/badges.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> badgesJson = jsonData['badges'] ?? [];

      _badgeCache = badgesJson
          .map((badgeData) {
            try {
              // Convert JSON structure to match BadgeModel
              final unlockCondition =
                  badgeData['unlockCondition'] as Map<String, dynamic>?;
              return BadgeModel(
                id: badgeData['id'] as String,
                name: badgeData['name'] as String,
                description: badgeData['description'] as String,
                iconPath: badgeData['iconPath'] as String,
                category: badgeData['category'] as String,
                xpBonus: badgeData['xpBonus'] as int? ?? 0,
                rarity: badgeData['rarity'] as String,
                criteriaType: unlockCondition?['type'] as String? ?? 'manual',
                criteriaValue:
                    unlockCondition?['value'] ??
                    unlockCondition?['count'] ??
                    unlockCondition?['realmId'],
                displayOrder: badgeData['displayOrder'] as int? ?? 0,
                isActive: badgeData['isActive'] as bool? ?? true,
              );
            } catch (e) {
              print('Error parsing badge: $e');
              return null;
            }
          })
          .whereType<BadgeModel>()
          .toList();

      // Sort by display order
      _badgeCache!.sort((a, b) => a.order.compareTo(b.order));

      print('Loaded ${_badgeCache!.length} badges from local JSON');
      return _badgeCache!;
    } catch (e) {
      print('Error loading badges from JSON: $e');
      return [];
    }
  }

  /// Get badge by ID
  Future<BadgeModel?> getBadge(String badgeId) async {
    try {
      // Get from local JSON cache
      final allBadges = await getAllBadges();
      return allBadges.firstWhere(
        (badge) => badge.id == badgeId,
        orElse: () => throw Exception('Badge not found'),
      );
    } catch (e) {
      print('Error getting badge $badgeId: $e');
      return null;
    }
  }

  /// Get badges by category
  Future<List<BadgeModel>> getBadgesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('badges')
          .where('category', isEqualTo: category)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => BadgeModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      // print('Error getting badges by category: $e');
      return [];
    }
  }

  /// Check and award badges based on user progress
  /// Returns list of newly unlocked badge IDs
  /// If context is provided, queues badge animations
  Future<List<String>> checkAndAwardBadges(
    String userId, {
    BuildContext? context,
  }) async {
    final List<String> newBadges = [];
    final List<BadgeModel> newBadgeModels = [];

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return newBadges;

      final userData = userDoc.data()!;
      final currentBadges = List<String>.from(userData['badges'] ?? []);
      final totalXP = userData['totalXP'] ?? 0;
      final streak = userData['currentStreak'] ?? 0;
      final classroomIds = List<String>.from(userData['classroomIds'] ?? []);
      final progressSummary = Map<String, dynamic>.from(
        userData['progressSummary'] ?? {},
      );

      // Get all badge definitions
      final allBadges = await getAllBadges();

      // Check each badge condition
      for (final badge in allBadges) {
        if (!currentBadges.contains(badge.id)) {
          if (await _checkBadgeCondition(
            badge,
            userId,
            totalXP,
            streak,
            classroomIds,
            progressSummary,
          )) {
            newBadges.add(badge.id);
            newBadgeModels.add(badge);

            // Award XP bonus for badge unlock (enforce daily cap)
            if (badge.xpBonus > 0) {
              final xpService = XPService();
              final xpCapResult = await xpService.calculateAwardedXP(
                userId: userId,
                earnedXP: badge.xpBonus,
              );
              final xpToAward = (xpCapResult['xpToAward'] as int?) ?? 0;

              if (xpToAward > 0) {
                await _firestore.collection('users').doc(userId).update({
                  'totalXP': FieldValue.increment(xpToAward),
                });

                // Check for rank changes after XP update
                RankMonitor.checkRankChanges(userId);
              }
            }
          }
        }
      }

      // Award new badges
      if (newBadges.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'badges': FieldValue.arrayUnion(newBadges),
        });

        // Create notifications for newly earned badges (check for duplicates first)
        final batch = _firestore.batch();
        for (final badge in newBadgeModels) {
          // Check if notification already exists for this badge
          final existingNotif = await _firestore
              .collection('notifications')
              .where('toUserId', isEqualTo: userId)
              .where('data.badgeId', isEqualTo: badge.id)
              .limit(1)
              .get();

          // Only create notification if it doesn't exist
          if (existingNotif.docs.isEmpty) {
            final docRef = _firestore.collection('notifications').doc();
            batch.set(docRef, {
              'toUserId': userId,
              'fromUserId': null,
              'title': '🏆 Badge Earned!',
              'body': 'You earned: ${badge.name}',
              'data': {
                'type': 'badge',
                'badgeId': badge.id,
                'badgeName': badge.name,
                'badgeRarity': badge.rarity,
              },
              'read': false,
              'sentAt': Timestamp.now(),
            });
          }
        }
        await batch.commit();

        // Queue badge animations if context provided
        if (context != null && newBadgeModels.isNotEmpty) {
          _animationQueue.queueBadges(newBadgeModels);
          // Show first animation
          _animationQueue.showNext(context);
        }
      }
    } catch (e) {
      // print('Error checking badges: $e');
    }

    return newBadges;
  }

  /// Manually trigger badge animation (for testing or special cases)
  void showBadgeAnimation(BuildContext context, BadgeModel badge) {
    _animationQueue.queueBadge(badge);
    _animationQueue.showNext(context);
  }

  /// Check if badge condition is met
  Future<bool> _checkBadgeCondition(
    BadgeModel badge,
    String userId,
    int totalXP,
    int streak,
    List<String> classroomIds,
    Map<String, dynamic> progressSummary,
  ) async {
    final type = badge.criteriaType;
    final value = badge.criteriaValue;

    switch (type) {
      // XP-based badges
      case 'xp_threshold':
      case 'xp_total':
        final requiredXP = value as int? ?? 0;
        return totalXP >= requiredXP;

      // Streak-based badges
      case 'streak':
      case 'streak_days':
        final requiredStreak = value as int? ?? 0;
        return streak >= requiredStreak;

      // Realm completion badges
      case 'realm_complete':
        final realmId = badge.criteriaValue as String?;
        if (realmId == null) return false;
        return _isRealmCompleted(progressSummary, realmId);

      case 'all_realms_complete':
        final requiredCount = badge.criteriaValue as int? ?? 6;
        return _countCompletedRealms(progressSummary) >= requiredCount;

      // Level completion badges
      case 'levels_completed':
      case 'levels_complete':
        final requiredLevels = value as int? ?? 0;
        return _getTotalLevelsCompleted(progressSummary) >= requiredLevels;

      // Quiz badges
      case 'quiz_complete':
        final requiredCount = badge.criteriaValue as int? ?? 1;
        return _getTotalLevelsCompleted(progressSummary) >=
            requiredCount; // Any level completion counts as quiz

      case 'perfect_quiz':
        final requiredCount = badge.criteriaValue as int? ?? 1;
        return await _countPerfectQuizzes(userId) >= requiredCount;

      // Social badges
      case 'classroom_join':
        return classroomIds.isNotEmpty;

      case 'assignment_complete':
        final requiredCount = badge.criteriaValue as int? ?? 1;
        return await _countCompletedAssignments(userId) >= requiredCount;

      // Daily challenge badges
      case 'daily_challenge_complete':
        final requiredCount = badge.criteriaValue as int? ?? 1;
        return await _countCompletedDailyChallenges(userId) >= requiredCount;

      case 'daily_challenge_streak':
        // TODO: Implement daily challenge streak tracking
        return false;

      // Leaderboard badges
      case 'leaderboard_rank':
        final maxRank = badge.criteriaValue as int? ?? 1;
        return await _checkLeaderboardRank(userId, 'classroom', maxRank);

      // Game badges
      case 'games_played':
      case 'unique_games_played':
      case 'all_games_played':
      case 'game_high_score':
      case 'game_perfect_score':
      case 'specific_game_perfect':
      case 'total_game_plays':
        // TODO: Implement game tracking
        return false;

      // Special badges
      case 'early_adopter':
        // Check if user joined within first month of app launch
        final userCreatedAt =
            (await _firestore.collection('users').doc(userId).get())
                    .data()?['createdAt']
                as Timestamp?;
        if (userCreatedAt == null) return false;
        // This would need actual launch date - using placeholder
        return true; // TODO: Implement proper check with launch date

      case 'speedrunner':
        // Check if user completed a level in under 5 minutes
        // This would require tracking time spent per level
        return false; // TODO: Implement when time tracking is added

      case 'night_owl':
        // Check if user completed levels between 10 PM - 6 AM
        final requiredCount = badge.criteriaValue as int? ?? 5;
        return await _countNightOwlCompletions(userId) >= requiredCount;

      case 'weekend_warrior':
        // Check if user has 10+ completions on weekends
        return await _countWeekendCompletions(userId) >= 10;

      default:
        print('⚠️ Unknown badge type: $type for badge ${badge.id}');
        return false;
    }
  }

  // Helper methods for badge condition checks

  bool _isRealmCompleted(Map<String, dynamic> progressSummary, String realmId) {
    // Try with realm_ prefix first (new format), then without (old format)
    var realmProgress = progressSummary[realmId] as Map<String, dynamic>?;
    if (realmProgress == null && !realmId.startsWith('realm_')) {
      // Try with realm_ prefix
      realmProgress =
          progressSummary['realm_$realmId'] as Map<String, dynamic>?;
    }
    return realmProgress?['completed'] == true;
  }

  int _countCompletedRealms(Map<String, dynamic> progressSummary) {
    int count = 0;
    for (final entry in progressSummary.values) {
      if (entry is Map<String, dynamic> && entry['completed'] == true) {
        count++;
      }
    }
    return count;
  }

  int _getTotalLevelsCompleted(Map<String, dynamic> progressSummary) {
    int total = 0;
    for (final entry in progressSummary.values) {
      if (entry is Map<String, dynamic>) {
        total += (entry['levelsCompleted'] as int?) ?? 0;
      }
    }
    return total;
  }

  Future<int> _countPerfectQuizzes(String userId) async {
    final snapshot = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: userId)
        .where('accuracy', isEqualTo: 100)
        .get();

    return snapshot.docs.length;
  }

  Future<int> _countCompletedAssignments(String userId) async {
    final snapshot = await _firestore
        .collection('assignment_submissions')
        .where('studentId', isEqualTo: userId)
        .where('score', isGreaterThan: 0)
        .get();

    return snapshot.docs.length;
  }

  Future<int> _countCompletedDailyChallenges(String userId) async {
    final snapshot = await _firestore
        .collection('daily_challenge_attempts')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  Future<bool> _checkLeaderboardRank(
    String userId,
    String scope,
    int maxRank,
  ) async {
    // This would need to query leaderboard_cache
    // Simplified implementation
    try {
      final leaderboards = await _firestore
          .collection('leaderboard_cache')
          .where('scope', isEqualTo: scope)
          .limit(1)
          .get();

      if (leaderboards.docs.isEmpty) return false;

      final entries = leaderboards.docs.first.data()['entries'] as List?;
      if (entries == null) return false;

      for (var i = 0; i < entries.length && i < maxRank; i++) {
        if (entries[i]['userId'] == userId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<int> _countNightOwlCompletions(String userId) async {
    final snapshot = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: userId)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final completedAt = (doc.data()['completedAt'] as Timestamp?)?.toDate();
      if (completedAt != null) {
        final hour = completedAt.hour;
        if (hour >= 22 || hour < 6) {
          count++;
        }
      }
    }
    return count;
  }

  Future<int> _countWeekendCompletions(String userId) async {
    final snapshot = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    int weekendCount = 0;
    for (final doc in snapshot.docs) {
      final completedAt = (doc.data()['completedAt'] as Timestamp?)?.toDate();
      if (completedAt != null) {
        // 6 = Saturday, 7 = Sunday
        if (completedAt.weekday >= 6) {
          weekendCount++;
        }
      }
    }
    return weekendCount;
  }

  /// Get user's unlocked badges with details
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final badgeIds = List<String>.from(userDoc.data()?['badges'] ?? []);
      if (badgeIds.isEmpty) return [];

      final badges = await getAllBadges();
      return badges.where((badge) => badgeIds.contains(badge.id)).toList();
    } catch (e) {
      // print('Error getting user badges: $e');
      return [];
    }
  }

  /// Clear badge cache (call when badges are updated)
  void clearCache() {
    _badgeCache = null;
  }

  /// Create notifications for all existing earned badges (one-time migration)
  Future<void> createNotificationsForEarnedBadges(String userId) async {
    try {
      // Get user's earned badges
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final earnedBadgeIds = List<String>.from(userDoc.data()?['badges'] ?? []);
      if (earnedBadgeIds.isEmpty) return;

      // Get all badge definitions
      final allBadges = await getAllBadges();

      // Check which badges already have notifications
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('data.type', isEqualTo: 'badge')
          .get();

      final notifiedBadgeIds = existingNotifications.docs
          .map((doc) => doc.data()['data']?['badgeId'] as String?)
          .whereType<String>()
          .toSet();

      // Create notifications for badges that don't have them yet
      final batch = _firestore.batch();
      int count = 0;

      for (final badgeId in earnedBadgeIds) {
        if (!notifiedBadgeIds.contains(badgeId)) {
          final badge = allBadges.firstWhere(
            (b) => b.id == badgeId,
            orElse: () => BadgeModel(
              id: badgeId,
              name: 'Badge',
              description: '',
              iconPath: '',
              category: 'milestone',
              xpBonus: 0,
              rarity: 'common',
              criteriaType: 'manual',
              criteriaValue: null,
            ),
          );

          final docRef = _firestore.collection('notifications').doc();
          batch.set(docRef, {
            'toUserId': userId,
            'fromUserId': null,
            'title': '🏆 Badge Earned!',
            'body': 'You earned: ${badge.name}',
            'data': {
              'type': 'badge',
              'badgeId': badge.id,
              'badgeName': badge.name,
              'badgeRarity': badge.rarity,
            },
            'read': false,
            'sentAt': Timestamp.now(),
          });

          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        print('Created $count badge notifications for user $userId');
      }
    } catch (e) {
      print('Error creating badge notifications: $e');
    }
  }
}
