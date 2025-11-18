import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../../services/streak_service.dart';
import 'badge_service.dart';
import 'content_service.dart';
import '../utils/debouncer.dart';
import '../utils/firebase_batch_helper.dart';

/// Service to manage user progress across realms and levels
class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeService _badgeService = BadgeService();
  final FirebaseBatchHelper _batchHelper = FirebaseBatchHelper();
  final StreakService _streakService = StreakService();
  final ContentService _contentService = ContentService();
  
  // Debouncer for progress updates (save every 30 seconds)
  final _progressDebouncer = Debouncer(delay: const Duration(seconds: 30));
  
  // Pending progress updates
  final Map<String, Map<String, dynamic>> _pendingUpdates = {};

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
      // print('Error getting user progress: $e');
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
      // print('Error getting realm progress: $e');
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
      // print('Error checking level unlock: $e');
      return levelNumber == 1; // Default to first level only
    }
  }

  /// Mark a level as completed and update progress
  /// Returns list of newly unlocked badge IDs
  Future<List<String>> completeLevel({
    required String userId,
    required String realmId,
    required int levelNumber,
    required int xpEarned,
    required int quizScore,
    required int totalQuestions,
    String? newBadge,
  }) async {
    // Calculate star rating based on quiz performance
    // Each correct answer = 1 star (5 questions = 5 stars max)
    int stars = quizScore.clamp(0, 5);
    
    try{
      // Firebase will queue writes when offline and sync when online
      final batch = _firestore.batch();

      // Update realm progress using per-realm document
      // Format: userId__realmId
      final progressDocId = '${userId}__$realmId';
      final progressRef = _firestore
          .collection('progress')
          .doc(progressDocId);

      final progressDoc = await progressRef.get();
      
      // Track completed levels count for later use
      int finalCompletedLevelsCount = 0;
      
      // Track if this is a new completion (for XP awarding)
      bool isNewCompletion = false;
      
      if (progressDoc.exists) {
        // Update existing progress
        final currentData = progressDoc.data()!;
        
        // Safely parse completedLevels - handle both List and int types
        List<int> completedLevels = [];
        if (currentData.containsKey('completedLevels')) {
          final levelsData = currentData['completedLevels'];
          if (levelsData is List) {
            completedLevels = List<int>.from(levelsData);
          } else if (levelsData is int) {
            // Old format: just a count, not a list - we'll rebuild it
            print('⚠️ WARNING: completedLevels is int ($levelsData), converting to list format');
            // We can't recover the exact levels, so we'll just add the current one
            completedLevels = [];
          }
        }
        
        // Safely parse levelStars map
        final Map<String, int> levelStars = {};
        if (currentData.containsKey('levelStars') && currentData['levelStars'] is Map) {
          final starsData = currentData['levelStars'] as Map;
          starsData.forEach((key, value) {
            if (value is int) {
              levelStars[key.toString()] = value;
            }
          });
        }
        
        // Check if this is a new completion
        isNewCompletion = !completedLevels.contains(levelNumber);
        
        // Add level to completed list if not already there
        if (isNewCompletion) {
          completedLevels.add(levelNumber);
        }
        
        // Store star rating for this level (update if better)
        final levelKey = 'level_$levelNumber';
        final existingStars = levelStars[levelKey] ?? 0;
        if (stars > existingStars) {
          levelStars[levelKey] = stars;
        }
        
        // Sort completed levels
        completedLevels.sort();
        
        // Current level is the next uncompleted level
        final currentLevel = completedLevels.length + 1;
        
        // Store count for later use
        finalCompletedLevelsCount = completedLevels.length;
        
        // Only increment XP if this is a new completion
        final updateMap = {
          'completedLevels': completedLevels,
          'levelStars': levelStars,
          'currentLevelNumber': currentLevel,
          'lastAccessedAt': Timestamp.now(),
        };
        
        if (isNewCompletion) {
          updateMap['xpEarned'] = FieldValue.increment(xpEarned);
        }
        
        batch.update(progressRef, updateMap);
      } else {
        // Create new progress document
        final newProgress = {
          'userId': userId,
          'realmId': realmId,
          'completedLevels': [levelNumber],
          'levelStars': {'level_$levelNumber': stars},
          'currentLevelNumber': levelNumber + 1,
          'xpEarned': xpEarned,
          'lastAccessedAt': Timestamp.now(),
        };
        
        // Store count for later use
        finalCompletedLevelsCount = 1;
        isNewCompletion = true; // First time completing any level in this realm
        
        batch.set(progressRef, newProgress);
      }

      // Update user's total XP and progressSummary
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      Map<String, dynamic> updateData = {
        'lastActiveDate': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      // Only increment XP if this is a new completion
      if (isNewCompletion) {
        updateData['totalXP'] = FieldValue.increment(xpEarned);
        print('✅ Awarding $xpEarned XP for first-time completion of level $levelNumber');
      } else {
        print('ℹ️ Level $levelNumber already completed - no XP awarded');
      }

      // Update progressSummary in user document for quick access
      if (userDoc.exists) {
        final userData = userDoc.data();
        final progressSummary = userData?['progressSummary'] ?? {};
        
        // Use realmId as-is (e.g., 'realm_copyright')
        final summaryKey = realmId;
        final realmProgress = progressSummary[summaryKey] ?? {};
        
        // Use the count we calculated earlier
        int levelsCompletedCount = finalCompletedLevelsCount;
        
        // Get total levels from realm data (always use the correct value from content)
        final realm = _contentService.getRealmById(realmId);
        final totalLevels = realm?.totalLevels ?? 10; // Default to 10 if realm not found
        
        // Only add XP if this is a new completion
        final xpEarnedSoFar = (realmProgress['xpEarned'] ?? 0) + (isNewCompletion ? xpEarned : 0);
        final isCompleted = levelsCompletedCount >= totalLevels;
        
        updateData['progressSummary.$summaryKey'] = {
          'completed': isCompleted,
          'levelsCompleted': levelsCompletedCount,
          'totalLevels': totalLevels,
          'xpEarned': xpEarnedSoFar,
          'lastAccessedAt': Timestamp.now(),
        };
      }

      // Add badge if unlocked
      if (newBadge != null) {
        updateData['badges'] = FieldValue.arrayUnion([newBadge]);
      }

      // Single batch update with all data
      batch.update(userRef, updateData);
      
      // Commit all updates
      await batch.commit();
      
      // Update streak after awarding XP (only if XP was awarded)
      if (isNewCompletion) {
        await _streakService.updateStreakOnActivity(userId);
      }


      
      // Check for new badges only if this was a new completion (to avoid duplicate checks)
      List<String> newBadges = [];
      if (isNewCompletion) {
        // Note: checkAndAwardBadges now handles notification creation internally
        newBadges = await _badgeService.checkAndAwardBadges(userId);
        if (newBadges.isNotEmpty) {
          print('✅ New badges unlocked: $newBadges');
          
          // Create badge_unlock entries for recent activity (don't wait)
          Future.delayed(Duration.zero, () async {
            for (final badgeId in newBadges) {
              try {
                final badge = await _badgeService.getBadge(badgeId);
                if (badge != null) {
                  // Create badge_unlock entry for recent activity
                  await _firestore
                      .collection('users')
                      .doc(userId)
                      .collection('badge_unlocks')
                      .add({
                    'badgeId': badge.id,
                    'badgeName': badge.name,
                    'badgeRarity': badge.rarity,
                    'unlockedAt': Timestamp.now(),
                  });
                }
              } catch (e) {
                print('Error creating badge activity: $e');
              }
            }
          });
        }
      } else {
        print('ℹ️ Level already completed - skipping badge check');
      }
      
      return newBadges;
    } catch (e) {
      print('Error completing level: $e');
      return []; // Return empty list on error
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
      // print('Error getting progress summary: $e');
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
      // Delete the progress document for this user and realm
      final docId = '${userId}__$realmId';
      await _firestore.collection('progress').doc(docId).delete();
      
      // Also clear from user's progressSummary
      await _firestore.collection('users').doc(userId).update({
        'progressSummary.$realmId': FieldValue.delete(),
      });
    } catch (e) {
      // print('Error resetting progress: $e');
      rethrow;
    }
  }
  /// Save progress with debouncing (batches updates every 30 seconds)
  /// This reduces Firebase write operations significantly
  void saveProgressDebounced({
    required String userId,
    required String realmId,
    required Map<String, dynamic> updates,
  }) {
    final docId = '${userId}__$realmId';
    
    // Merge with existing pending updates
    if (_pendingUpdates.containsKey(docId)) {
      _pendingUpdates[docId]!.addAll(updates);
    } else {
      _pendingUpdates[docId] = updates;
    }
    
    // Debounce the actual save
    _progressDebouncer.call(() async {
      if (_pendingUpdates.isEmpty) return;
      
      try {
        // Batch all pending updates
        final operations = _pendingUpdates.entries.map((entry) {
          return BatchOperation.update(
            _firestore.collection('progress').doc(entry.key),
            entry.value,
          );
        }).toList();
        
        await _batchHelper.executeBatch(operations);
        
        // print('✅ Saved ${_pendingUpdates.length} debounced progress updates');
        _pendingUpdates.clear();
      } catch (e) {
        // print('❌ Error saving debounced progress: $e');
      }
    });
  }
  
  /// Force save all pending progress updates immediately
  /// Call this when user navigates away or app goes to background
  Future<void> flushPendingUpdates() async {
    _progressDebouncer.cancel();
    
    if (_pendingUpdates.isEmpty) return;
    
    try {
      final operations = _pendingUpdates.entries.map((entry) {
        return BatchOperation.update(
          _firestore.collection('progress').doc(entry.key),
          entry.value,
        );
      }).toList();
      
      await _batchHelper.executeBatch(operations);
      
      // print('✅ Flushed ${_pendingUpdates.length} pending progress updates');
      _pendingUpdates.clear();
    } catch (e) {
      // print('❌ Error flushing pending updates: $e');
    }
  }
  
  /// Dispose the service and flush pending updates
  Future<void> dispose() async {
    await flushPendingUpdates();
    _progressDebouncer.dispose();
  }

}
