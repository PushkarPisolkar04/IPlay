import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import 'badge_service.dart';

/// Service to manage user progress across realms and levels
class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeService _badgeService = BadgeService();

  /// Get user's progress for all realms
  Future<List<ProgressModel>> getUserProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => ProgressModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user progress: $e');
      return [];
    }
  }

  /// Get user's progress for a specific realm
  Future<ProgressModel?> getRealmProgress(
      String userId, String realmId) async {
    try {
      // Use composite ID format: userId__realmId
      final docId = '${userId}__$realmId';
      final doc = await _firestore
          .collection('progress')
          .doc(docId)
          .get();

      if (!doc.exists) return null;
      return ProgressModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting realm progress: $e');
      return null;
    }
  }

  /// Check if a level is unlocked for the user
  Future<bool> isLevelUnlocked(
      String userId, String realmId, int levelNumber) async {
    try {
      final progress = await getRealmProgress(userId, realmId);
      if (progress == null) {
        // No progress yet, only first level is unlocked
        return levelNumber == 1;
      }

      // Current level and all previous levels are unlocked
      return levelNumber <= progress.currentLevelNumber;
    } catch (e) {
      print('Error checking level unlock: $e');
      return levelNumber == 1; // Default to first level only
    }
  }

  /// Mark a level as completed and update progress
  Future<void> completeLevel({
    required String userId,
    required String realmId,
    required int levelNumber,
    required int xpEarned,
    required int quizScore,
    required int totalQuestions,
    String? newBadge,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update realm progress using top-level collection with composite ID
      // Format: userId__realmId__levelNumber
      final progressDocId = '${userId}__${realmId}_level_$levelNumber';
      final progressRef = _firestore
          .collection('progress')
          .doc(progressDocId);

      final progressDoc = await progressRef.get();
      
      if (progressDoc.exists) {
        // Update existing progress
        batch.update(progressRef, {
          'xpEarned': FieldValue.increment(xpEarned),
          'attemptsCount': FieldValue.increment(1),
          'lastAttemptAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
          'status': 'completed',
        });
      } else {
        // Create new progress document
        final newProgress = {
          'userId': userId,
          'contentId': '${realmId}_level_$levelNumber',
          'contentType': 'level',
          'contentVersion': '1.0.0',
          'status': 'completed',
          'completionPercentage': 100,
          'xpEarned': xpEarned,
          'attemptsCount': 1,
          'accuracy': (quizScore / totalQuestions * 100).round(),
          'timeSpentSeconds': 0, // TODO: Track time spent
          'startedAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
          'lastAttemptAt': Timestamp.now(),
        };
        batch.set(progressRef, newProgress);
      }

      // Update user's total XP and progressSummary
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      Map<String, dynamic> updateData = {
        'totalXP': FieldValue.increment(xpEarned),
        'lastActiveDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // Update progressSummary in user document for quick access
      if (userDoc.exists) {
        final userData = userDoc.data();
        final progressSummary = userData?['progressSummary'] ?? {};
        final realmProgress = progressSummary[realmId] ?? {};
        
        final levelsCompleted = List<int>.from(realmProgress['levelsCompleted'] ?? []);
        if (!levelsCompleted.contains(levelNumber)) {
          levelsCompleted.add(levelNumber);
        }
        
        // Get total levels for this realm (you may want to pass this as parameter)
        final totalLevels = realmProgress['totalLevels'] ?? 8; // Default to 8
        final xpEarnedSoFar = (realmProgress['xpEarned'] ?? 0) + xpEarned;
        final isCompleted = levelsCompleted.length >= totalLevels;
        
        updateData['progressSummary.$realmId'] = {
          'completed': isCompleted,
          'levelsCompleted': levelsCompleted.length,
          'totalLevels': totalLevels,
          'xpEarned': xpEarnedSoFar,
          'lastAccessedAt': Timestamp.now(),
        };
      }

      batch.update(userRef, updateData);

      // If badge unlocked, add to user's badges
      if (newBadge != null) {
        batch.update(userRef, {
          'badges': FieldValue.arrayUnion([newBadge]),
        });
      }

      // Commit all updates
      await batch.commit();

      // Update streak
      await _updateStreak(userId);
      
      // Check for new badges (don't wait for this)
      _badgeService.checkAndAwardBadges(userId).then((newBadges) {
        if (newBadges.isNotEmpty) {
          print('New badges unlocked: $newBadges');
          // Badge notification will be handled by the UI
        }
      });
    } catch (e) {
      print('Error completing level: $e');
      rethrow;
    }
  }

  /// Update user's learning streak
  Future<void> _updateStreak(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return;

      final user = UserModel.fromMap(userDoc.data()!);
      final now = DateTime.now();
      final lastActive = user.lastActiveDate;

      final hoursDiff = now.difference(lastActive).inHours;

      int newStreak = user.currentStreak;

      if (hoursDiff <= 48) {
        // Within 48-hour grace period
        if (now.day != lastActive.day) {
          // New day, increment streak
          newStreak = user.currentStreak + 1;
        }
        // Else: Same day, streak unchanged
      } else {
        // Streak broken (> 48 hours), reset to 1
        newStreak = 1;
      }

      await _firestore.collection('users').doc(userId).update({
        'currentStreak': newStreak,
        'lastActiveDate': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// Get overall progress summary
  Future<Map<String, dynamic>> getProgressSummary(String userId) async {
    try {
      final allProgress = await getUserProgress(userId);
      
      int totalLevelsCompleted = 0;
      int totalXPEarned = 0;
      int realmsInProgress = 0;
      int realmsCompleted = 0;

      for (final progress in allProgress) {
        totalLevelsCompleted += progress.completedLevels.length;
        totalXPEarned += progress.xpEarned;
        
        if (progress.completedLevels.isNotEmpty) {
          realmsInProgress++;
        }
        
        // TODO: Check if realm fully completed (need total levels count)
      }

      return {
        'totalLevelsCompleted': totalLevelsCompleted,
        'totalXPEarned': totalXPEarned,
        'realmsInProgress': realmsInProgress,
        'realmsCompleted': realmsCompleted,
      };
    } catch (e) {
      print('Error getting progress summary: $e');
      return {
        'totalLevelsCompleted': 0,
        'totalXPEarned': 0,
        'realmsInProgress': 0,
        'realmsCompleted': 0,
      };
    }
  }

  /// Reset progress for a realm (for testing/admin purposes)
  Future<void> resetRealmProgress(String userId, String realmId) async {
    try {
      // Delete all progress documents for this user and realm
      final snapshot = await _firestore
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .where('contentId', isGreaterThanOrEqualTo: '${realmId}_')
          .where('contentId', isLessThan: '${realmId}_\uf8ff')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error resetting progress: $e');
      rethrow;
    }
  }
}

