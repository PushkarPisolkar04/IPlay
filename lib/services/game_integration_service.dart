import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/constants/app_constants.dart';
import '../models/game_progress_model.dart';
import '../core/models/user_model.dart';

/// Service for integrating games with core systems (XP, progress, leaderboards, analytics)
class GameIntegrationService {
  static final GameIntegrationService _instance = GameIntegrationService._internal();
  factory GameIntegrationService() => _instance;
  GameIntegrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Award XP to user after game completion
  /// 
  /// Parameters:
  /// - [gameId]: The game identifier
  /// - [baseXP]: Base XP from game model
  /// - [score]: User's score (0-100)
  /// - [isPerfectScore]: Whether user achieved perfect score
  /// - [isFirstCompletion]: Whether this is first time completing the game
  /// 
  /// Returns total XP awarded
  Future<int> awardGameXP({
    required String gameId,
    required int baseXP,
    required int score,
    bool isPerfectScore = false,
    bool isFirstCompletion = false,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      int totalXP = baseXP;

      // Add perfect score bonus (50% extra)
      if (isPerfectScore) {
        totalXP += (baseXP * 0.5).round();
      }

      // Add first-time completion bonus (100% extra)
      if (isFirstCompletion) {
        totalXP += baseXP;
      }

      // Update user's total XP in Firestore
      final userRef = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUserId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        final currentXP = userDoc.data()?['totalXP'] ?? 0;
        final newTotalXP = currentXP + totalXP;

        transaction.update(userRef, {
          'totalXP': newTotalXP,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return totalXP;
    } catch (e) {
      throw Exception('Failed to award XP: $e');
    }
  }

  /// Get user's current XP
  Future<int> getUserXP() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUserId)
          .get();

      if (!userDoc.exists) {
        return 0;
      }

      return userDoc.data()?['totalXP'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get user XP: $e');
    }
  }

  // ============================================================================
  // PROGRESS TRACKING
  // ============================================================================

  /// Save game progress after completion
  /// 
  /// Parameters:
  /// - [gameId]: The game identifier
  /// - [score]: User's score (0-100)
  /// - [timeSpentSeconds]: Time spent playing in seconds
  /// - [completed]: Whether the game was completed
  Future<void> saveGameProgress({
    required String gameId,
    required int score,
    required int timeSpentSeconds,
    bool completed = true,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final progressRef = _firestore
          .collection(AppConstants.collectionProgress)
          .doc(_currentUserId)
          .collection('games')
          .doc(gameId);

      // Get existing progress
      final existingDoc = await progressRef.get();
      final existingData = existingDoc.data();

      final int gamesPlayed = (existingData?['gamesPlayed'] ?? 0) + 1;
      final int highScore = existingData?['highScore'] ?? 0;
      final int totalTimeSpent = (existingData?['totalTimeSpent'] ?? 0) + timeSpentSeconds;
      final int totalScore = (existingData?['totalScore'] ?? 0) + score;
      final bool wasCompleted = existingData?['completed'] ?? false;

      // Calculate average score
      final double averageScore = totalScore / gamesPlayed;

      await progressRef.set({
        'gameId': gameId,
        'userId': _currentUserId,
        'gamesPlayed': gamesPlayed,
        'highScore': score > highScore ? score : highScore,
        'averageScore': averageScore.round(),
        'totalScore': totalScore,
        'totalTimeSpent': totalTimeSpent,
        'completed': completed || wasCompleted,
        'lastPlayedAt': FieldValue.serverTimestamp(),
        if (!wasCompleted && completed)
          'firstCompletedAt': FieldValue.serverTimestamp()
        else if (wasCompleted && existingData?['firstCompletedAt'] != null)
          'firstCompletedAt': existingData!['firstCompletedAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save game progress: $e');
    }
  }

  /// Get game progress for a specific game
  Future<GameProgress?> getGameProgress(String gameId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final progressDoc = await _firestore
          .collection(AppConstants.collectionProgress)
          .doc(_currentUserId)
          .collection('games')
          .doc(gameId)
          .get();

      if (!progressDoc.exists) {
        return null;
      }

      return GameProgress.fromMap(progressDoc.data()!);
    } catch (e) {
      throw Exception('Failed to get game progress: $e');
    }
  }

  /// Get all game progress for current user
  Future<Map<String, GameProgress>> getAllGameProgress() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final progressSnapshot = await _firestore
          .collection(AppConstants.collectionProgress)
          .doc(_currentUserId)
          .collection('games')
          .get();

      final Map<String, GameProgress> progressMap = {};
      
      for (final doc in progressSnapshot.docs) {
        progressMap[doc.id] = GameProgress.fromMap(doc.data());
      }

      return progressMap;
    } catch (e) {
      throw Exception('Failed to get all game progress: $e');
    }
  }

  /// Check if this is the first time completing a game
  Future<bool> isFirstCompletion(String gameId) async {
    final progress = await getGameProgress(gameId);
    return progress == null || !progress.completed;
  }

  // ============================================================================
  // LEADERBOARD INTEGRATION
  // ============================================================================

  /// Submit score to leaderboards
  /// 
  /// Parameters:
  /// - [gameId]: The game identifier
  /// - [score]: User's score
  /// - [scopes]: Leaderboard scopes to update (class, school, state, national)
  Future<void> submitToLeaderboards({
    required String gameId,
    required int score,
    List<String>? scopes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user data for leaderboard entry
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(_currentUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = UserModel.fromMap(userDoc.data()!);

      // Check if user opted out of public leaderboard
      if (userData.hideFromPublicLeaderboard) {
        return;
      }

      // Default scopes if not provided
      final targetScopes = scopes ?? [
        AppConstants.leaderboardSchool,
        AppConstants.leaderboardState,
        AppConstants.leaderboardNational,
      ];

      // Prepare leaderboard entry data
      final entryData = {
        'userId': _currentUserId,
        'displayName': userData.displayName,
        'avatarUrl': userData.avatarUrl,
        'score': score,
        'schoolTag': userData.schoolTag,
        'state': userData.state,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Submit to each scope
      final batch = _firestore.batch();

      for (final scope in targetScopes) {
        String leaderboardId;

        switch (scope) {
          case AppConstants.leaderboardSchool:
            if (userData.schoolTag == null) continue;
            leaderboardId = '${gameId}_school_${userData.schoolTag}';
            break;
          case AppConstants.leaderboardState:
            leaderboardId = '${gameId}_state_${userData.state}';
            break;
          case AppConstants.leaderboardNational:
            leaderboardId = '${gameId}_national';
            break;
          case AppConstants.leaderboardClass:
            // Class leaderboards require classroom ID
            // Skip for now, can be added when classroom context is available
            continue;
          default:
            continue;
        }

        final leaderboardRef = _firestore
            .collection(AppConstants.collectionLeaderboards)
            .doc(leaderboardId)
            .collection('entries')
            .doc(_currentUserId);

        // Only update if new score is higher
        batch.set(leaderboardRef, entryData, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit to leaderboards: $e');
    }
  }

  /// Get leaderboard entries for a game
  /// 
  /// Parameters:
  /// - [gameId]: The game identifier
  /// - [scope]: Leaderboard scope (class, school, state, national)
  /// - [scopeValue]: Value for the scope (e.g., school tag, state name)
  /// - [limit]: Maximum number of entries to fetch
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gameId,
    required String scope,
    String? scopeValue,
    int limit = 50,
  }) async {
    try {
      String leaderboardId;

      switch (scope) {
        case AppConstants.leaderboardSchool:
          if (scopeValue == null) throw Exception('School tag required');
          leaderboardId = '${gameId}_school_$scopeValue';
          break;
        case AppConstants.leaderboardState:
          if (scopeValue == null) throw Exception('State required');
          leaderboardId = '${gameId}_state_$scopeValue';
          break;
        case AppConstants.leaderboardNational:
          leaderboardId = '${gameId}_national';
          break;
        default:
          throw Exception('Invalid leaderboard scope');
      }

      final snapshot = await _firestore
          .collection(AppConstants.collectionLeaderboards)
          .doc(leaderboardId)
          .collection('entries')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final List<LeaderboardEntry> entries = [];
      int rank = 1;

      for (final doc in snapshot.docs) {
        entries.add(LeaderboardEntry.fromMap(doc.data(), rank));
        rank++;
      }

      return entries;
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  /// Get user's rank in a leaderboard
  Future<int?> getUserRank({
    required String gameId,
    required String scope,
    String? scopeValue,
  }) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      String leaderboardId;

      switch (scope) {
        case AppConstants.leaderboardSchool:
          if (scopeValue == null) return null;
          leaderboardId = '${gameId}_school_$scopeValue';
          break;
        case AppConstants.leaderboardState:
          if (scopeValue == null) return null;
          leaderboardId = '${gameId}_state_$scopeValue';
          break;
        case AppConstants.leaderboardNational:
          leaderboardId = '${gameId}_national';
          break;
        default:
          return null;
      }

      // Get user's score
      final userEntry = await _firestore
          .collection(AppConstants.collectionLeaderboards)
          .doc(leaderboardId)
          .collection('entries')
          .doc(_currentUserId)
          .get();

      if (!userEntry.exists) {
        return null;
      }

      final userScore = userEntry.data()?['score'] ?? 0;

      // Count how many users have higher scores
      final higherScoresCount = await _firestore
          .collection(AppConstants.collectionLeaderboards)
          .doc(leaderboardId)
          .collection('entries')
          .where('score', isGreaterThan: userScore)
          .count()
          .get();

      return higherScoresCount.count! + 1;
    } catch (e) {
      return null;
    }
  }

  /// Get user's percentile in a leaderboard
  Future<double?> getUserPercentile({
    required String gameId,
    required String scope,
    String? scopeValue,
  }) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final rank = await getUserRank(
        gameId: gameId,
        scope: scope,
        scopeValue: scopeValue,
      );

      if (rank == null) {
        return null;
      }

      String leaderboardId;

      switch (scope) {
        case AppConstants.leaderboardSchool:
          if (scopeValue == null) return null;
          leaderboardId = '${gameId}_school_$scopeValue';
          break;
        case AppConstants.leaderboardState:
          if (scopeValue == null) return null;
          leaderboardId = '${gameId}_state_$scopeValue';
          break;
        case AppConstants.leaderboardNational:
          leaderboardId = '${gameId}_national';
          break;
        default:
          return null;
      }

      // Get total count
      final totalCount = await _firestore
          .collection(AppConstants.collectionLeaderboards)
          .doc(leaderboardId)
          .collection('entries')
          .count()
          .get();

      if (totalCount.count == 0) {
        return null;
      }

      // Calculate percentile (higher is better)
      final percentile = ((totalCount.count! - rank + 1) / totalCount.count!) * 100;
      return percentile;
    } catch (e) {
      return null;
    }
  }


  // ============================================================================
  // ANALYTICS
  // ============================================================================

  /// Log game start event
  Future<void> logGameStart(String gameId) async {
    try {
      await _analytics.logEvent(
        name: 'game_start',
        parameters: {
          'game_id': gameId,
          'user_id': _currentUserId ?? 'anonymous',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Analytics errors should not break the app
      print('Analytics error: $e');
    }
  }

  /// Log game completion event
  Future<void> logGameComplete({
    required String gameId,
    required int score,
    required int timeSpentSeconds,
    required bool isPerfectScore,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_complete',
        parameters: {
          'game_id': gameId,
          'score': score,
          'time_spent': timeSpentSeconds,
          'is_perfect': isPerfectScore,
          'user_id': _currentUserId ?? 'anonymous',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  /// Log game retry event
  Future<void> logGameRetry(String gameId) async {
    try {
      await _analytics.logEvent(
        name: 'game_retry',
        parameters: {
          'game_id': gameId,
          'user_id': _currentUserId ?? 'anonymous',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  /// Log game quit event
  Future<void> logGameQuit({
    required String gameId,
    required int timeSpentSeconds,
    String? reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_quit',
        parameters: {
          'game_id': gameId,
          'time_spent': timeSpentSeconds,
          'reason': reason ?? 'user_quit',
          'user_id': _currentUserId ?? 'anonymous',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }

  /// Get game analytics summary (from Firestore aggregations)
  Future<GameAnalytics> getGameAnalytics(String gameId) async {
    try {
      // Get all progress documents for this game
      final progressSnapshot = await _firestore
          .collectionGroup('games')
          .where('gameId', isEqualTo: gameId)
          .get();

      if (progressSnapshot.docs.isEmpty) {
        return GameAnalytics(
          gameId: gameId,
          totalPlays: 0,
          uniquePlayers: 0,
          completionRate: 0,
          averageScore: 0,
          averageTimeSpent: 0,
          retryRate: 0,
        );
      }

      int totalPlays = 0;
      int completedGames = 0;
      int totalScore = 0;
      int totalTimeSpent = 0;
      final Set<String> uniquePlayers = {};

      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        final gamesPlayed = (data['gamesPlayed'] as num?)?.toInt() ?? 0;
        final completed = data['completed'] ?? false;
        final avgScore = (data['averageScore'] as num?)?.toInt() ?? 0;
        final timeSpent = (data['totalTimeSpent'] as num?)?.toInt() ?? 0;
        final userId = data['userId'] ?? '';

        totalPlays += gamesPlayed;
        if (completed) completedGames++;
        totalScore += avgScore * gamesPlayed;
        totalTimeSpent += timeSpent;
        if (userId.isNotEmpty) uniquePlayers.add(userId);
      }

      final completionRate = uniquePlayers.isEmpty 
          ? 0.0 
          : (completedGames / uniquePlayers.length) * 100;

      final averageScore = totalPlays == 0 ? 0.0 : totalScore / totalPlays;
      final averageTimeSpent = totalPlays == 0 ? 0 : totalTimeSpent ~/ totalPlays;
      
      // Retry rate: (total plays - unique players) / unique players
      final retryRate = uniquePlayers.isEmpty 
          ? 0.0 
          : ((totalPlays - uniquePlayers.length) / uniquePlayers.length) * 100;

      return GameAnalytics(
        gameId: gameId,
        totalPlays: totalPlays,
        uniquePlayers: uniquePlayers.length,
        completionRate: completionRate,
        averageScore: averageScore,
        averageTimeSpent: averageTimeSpent,
        retryRate: retryRate,
      );
    } catch (e) {
      throw Exception('Failed to get game analytics: $e');
    }
  }

  /// Get popular games (most played)
  Future<List<String>> getPopularGames({int limit = 10}) async {
    try {
      // Get all game progress documents
      final progressSnapshot = await _firestore
          .collectionGroup('games')
          .get();

      // Aggregate plays by game ID
      final Map<String, int> gamePlays = {};

      for (final doc in progressSnapshot.docs) {
        final gameId = doc.data()['gameId'] as String?;
        final gamesPlayed = doc.data()['gamesPlayed'] as int? ?? 0;

        if (gameId != null) {
          gamePlays[gameId] = (gamePlays[gameId] ?? 0) + gamesPlayed;
        }
      }

      // Sort by plays and return top games
      final sortedGames = gamePlays.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedGames
          .take(limit)
          .map((e) => e.key)
          .toList();
    } catch (e) {
      throw Exception('Failed to get popular games: $e');
    }
  }
}

/// Model for game analytics data
class GameAnalytics {
  final String gameId;
  final int totalPlays;
  final int uniquePlayers;
  final double completionRate;
  final double averageScore;
  final int averageTimeSpent;
  final double retryRate;

  GameAnalytics({
    required this.gameId,
    required this.totalPlays,
    required this.uniquePlayers,
    required this.completionRate,
    required this.averageScore,
    required this.averageTimeSpent,
    required this.retryRate,
  });

  /// Get formatted average time
  String get formattedAverageTime {
    final hours = averageTimeSpent ~/ 3600;
    final minutes = (averageTimeSpent % 3600) ~/ 60;
    final seconds = averageTimeSpent % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
