import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_cache_model.dart';

/// Service for leaderboard operations with LIVE data
/// No more cached data - always shows current rankings
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get leaderboard with LIVE data (reactive to all XP changes)
  /// 
  /// Scopes: 'national', 'state', 'school', 'classroom'
  /// Types: 'all' (all learners), 'solo' (learners not in any classroom)
  /// Periods: 'week', 'month', 'allTime'
  Future<LeaderboardCacheModel?> getLeaderboard({
    required String scope,
    required String type,
    required String period,
    String? identifier, // stateCode, schoolId, or classroomId
  }) async {
    try {
      // Build query based on scope
      Query query = _firestore.collection('users');
      
      // Apply filters
      if (scope == 'state' && identifier != null) {
        query = query.where('state', isEqualTo: identifier);
      } else if (scope == 'school' && identifier != null) {
        query = query.where('schoolId', isEqualTo: identifier);
      } else if (scope == 'classroom' && identifier != null) {
        query = query.where('classroomIds', arrayContains: identifier);
      }
      
      // Solo learners filter
      if (type == 'solo') {
        query = query.where('classroomIds', isEqualTo: []);
      }
      
      // Period filter (for future - currently allTime only)
      // TODO: Add weekly/monthly filtering based on lastActiveDate
      
      // Order by XP and get top 100
      query = query.orderBy('totalXP', descending: true).limit(100);
      
      final snapshot = await query.get();
      
      // Build entries
      final entries = snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data() as Map<String, dynamic>;
        return {
          'userId': entry.value.id,
          'displayName': data['displayName'] ?? 'Anonymous',
          'avatarUrl': data['avatarUrl'],
          'totalXP': data['totalXP'] ?? 0,
          'rank': entry.key + 1,
        };
      }).toList();
      
      return LeaderboardCacheModel.fromFirestore({
        'id': '${scope}_${type}_$period${identifier != null ? "_$identifier" : ""}',
        'scope': scope,
        'type': type,
        'period': period,
        'identifier': identifier,
        'entries': entries,
        'lastUpdatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to get leaderboard: $e');
    }
  }

  /// Get national leaderboard (all users)
  Future<LeaderboardCacheModel?> getNationalLeaderboard({
    String type = 'all',
    String period = 'allTime',
  }) async {
    return getLeaderboard(
      scope: 'national',
      type: type,
      period: period,
    );
  }

  /// Get state leaderboard
  Future<LeaderboardCacheModel?> getStateLeaderboard({
    required String state,
    String type = 'all',
    String period = 'allTime',
  }) async {
    return getLeaderboard(
      scope: 'state',
      type: type,
      period: period,
      identifier: state,
    );
  }

  /// Get school leaderboard
  Future<LeaderboardCacheModel?> getSchoolLeaderboard({
    required String schoolId,
    String type = 'all',
    String period = 'allTime',
  }) async {
    return getLeaderboard(
      scope: 'school',
      type: type,
      period: period,
      identifier: schoolId,
    );
  }

  /// Get classroom leaderboard
  Future<LeaderboardCacheModel?> getClassroomLeaderboard({
    required String classroomId,
    String period = 'allTime',
  }) async {
    return getLeaderboard(
      scope: 'classroom',
      type: 'all', // Classrooms always show all members
      period: period,
      identifier: classroomId,
    );
  }

  /// Get user's rank in a specific leaderboard
  Future<Map<String, dynamic>?> getUserRank({
    required String userId,
    required String scope,
    required String type,
    required String period,
    String? identifier,
  }) async {
    try {
      final leaderboard = await getLeaderboard(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      if (leaderboard == null) return null;

      // Find user in entries
      final userEntry = leaderboard.entries.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => LeaderboardEntry(
          userId: '',
          displayName: '',
          totalXP: 0,
          rank: -1,
        ),
      );

      if (userEntry.rank == -1) return null;

      return {
        'rank': userEntry.rank,
        'totalXP': userEntry.totalXP,
        'displayName': userEntry.displayName,
        'avatarUrl': userEntry.avatarUrl,
        'totalEntries': leaderboard.entries.length,
      };
    } catch (e) {
      throw Exception('Failed to get user rank: $e');
    }
  }

  /// Get top N users from leaderboard
  Future<List<LeaderboardEntry>> getTopUsers({
    required String scope,
    required String type,
    required String period,
    String? identifier,
    int limit = 100,
  }) async {
    try {
      final leaderboard = await getLeaderboard(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      if (leaderboard == null) return [];

      return leaderboard.entries.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get top users: $e');
    }
  }

  /// Get available leaderboard scopes for a user
  /// Returns list of available scopes based on user's affiliations
  Future<List<String>> getAvailableScopes(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return ['national'];

      final userData = userDoc.data()!;
      final classroomIds = List<String>.from(userData['classroomIds'] ?? []);
      final schoolTag = userData['schoolTag'] as String?;
      final state = userData['state'] as String?;

      final scopes = <String>['national'];

      if (state != null) {
        scopes.add('state');
      }

      if (schoolTag != null) {
        scopes.add('school');
      }

      if (classroomIds.isNotEmpty) {
        scopes.add('classroom');
      }

      return scopes;
    } catch (e) {
      throw Exception('Failed to get available scopes: $e');
    }
  }

  /// Get user's position relative to surrounding users
  /// Returns users ranked above and below the target user
  Future<Map<String, dynamic>> getUserContext({
    required String userId,
    required String scope,
    required String type,
    required String period,
    String? identifier,
    int contextSize = 5, // Number of users above and below
  }) async {
    try {
      final leaderboard = await getLeaderboard(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      if (leaderboard == null) {
        return {
          'userRank': null,
          'above': <LeaderboardEntry>[],
          'below': <LeaderboardEntry>[],
        };
      }

      // Find user's index
      final userIndex = leaderboard.entries.indexWhere(
        (entry) => entry.userId == userId,
      );

      if (userIndex == -1) {
        return {
          'userRank': null,
          'above': <LeaderboardEntry>[],
          'below': <LeaderboardEntry>[],
        };
      }

      // Get users above
      final startIndex = (userIndex - contextSize).clamp(0, leaderboard.entries.length);
      final above = leaderboard.entries.sublist(startIndex, userIndex);

      // Get users below
      final endIndex = (userIndex + contextSize + 1).clamp(0, leaderboard.entries.length);
      final below = leaderboard.entries.sublist(userIndex + 1, endIndex);

      return {
        'userRank': leaderboard.entries[userIndex],
        'above': above,
        'below': below,
        'totalUsers': leaderboard.entries.length,
      };
    } catch (e) {
      throw Exception('Failed to get user context: $e');
    }
  }

  /// Check when leaderboard was last updated
  Future<DateTime?> getLastUpdateTime({
    required String scope,
    required String type,
    required String period,
    String? identifier,
  }) async {
    try {
      final leaderboard = await getLeaderboard(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      return leaderboard?.lastUpdatedAt;
    } catch (e) {
      throw Exception('Failed to get last update time: $e');
    }
  }

  /// Get leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats({
    required String scope,
    required String type,
    required String period,
    String? identifier,
  }) async {
    try {
      final leaderboard = await getLeaderboard(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      if (leaderboard == null) {
        return {
          'totalUsers': 0,
          'averageXP': 0,
          'topUserXP': 0,
          'lastUpdated': null,
        };
      }

      final totalUsers = leaderboard.entries.length;
      final totalXP = leaderboard.entries.fold<int>(
        0,
        (sum, entry) => sum + entry.totalXP,
      );
      final averageXP = totalUsers > 0 ? (totalXP / totalUsers).round() : 0;
      final topUserXP = leaderboard.entries.isNotEmpty
          ? leaderboard.entries.first.totalXP
          : 0;

      return {
        'totalUsers': totalUsers,
        'averageXP': averageXP,
        'topUserXP': topUserXP,
        'lastUpdated': leaderboard.lastUpdatedAt,
      };
    } catch (e) {
      throw Exception('Failed to get leaderboard stats: $e');
    }
  }

  /// Listen to leaderboard updates (real-time)
  Stream<LeaderboardCacheModel?> watchLeaderboard({
    required String scope,
    required String type,
    required String period,
    String? identifier,
  }) {
    final docId = LeaderboardCacheModel.generateId(
      scope: scope,
      type: type,
      period: period,
      identifier: identifier,
    );

    return _firestore
        .collection('leaderboard_cache')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return LeaderboardCacheModel.fromFirestore(snapshot.data()!);
    });
  }

  /// Check for rank changes and send notifications
  /// Call this method after XP updates to notify users of significant rank changes
  Future<void> checkAndNotifyRankChanges({
    required String userId,
    required String scope,
    required String type,
    required String period,
    String? identifier,
    required int oldRank,
  }) async {
    try {
      // Get current rank
      final currentRankData = await getUserRank(
        userId: userId,
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      if (currentRankData == null) return;

      final newRank = currentRankData['rank'] as int;
      final rankChange = oldRank - newRank; // Positive means moved up

      // Only notify if rank changed by 5 or more positions
      if (rankChange.abs() >= 5) {
        String title;
        String body;
        
        if (rankChange > 0) {
          // Moved up
          title = '🎉 You climbed the leaderboard!';
          body = 'You moved up $rankChange positions to rank #$newRank in ${_getScopeName(scope)}!';
        } else {
          // Moved down
          title = '📉 Leaderboard update';
          body = 'You moved down ${rankChange.abs()} positions to rank #$newRank in ${_getScopeName(scope)}. Keep learning to climb back up!';
        }

        // Save notification to Firestore
        await _firestore.collection('notifications').add({
          'toUserId': userId,
          'fromUserId': null, // System notification
          'title': title,
          'body': body,
          'data': {
            'type': 'rank_change',
            'scope': scope,
            'oldRank': oldRank,
            'newRank': newRank,
            'rankChange': rankChange,
          },
          'read': false,
          'sentAt': Timestamp.now(),
        });
      }
    } catch (e) {
      // print('Error checking rank changes: $e');
    }
  }

  /// Get user-friendly scope name
  String _getScopeName(String scope) {
    switch (scope) {
      case 'classroom':
        return 'your classroom';
      case 'school':
        return 'your school';
      case 'state':
        return 'your state';
      case 'national':
        return 'the country';
      default:
        return 'the leaderboard';
    }
  }

  /// Monitor user's rank and send notifications for significant changes
  /// This should be called periodically or after XP updates
  Future<void> monitorUserRankChanges({
    required String userId,
  }) async {
    try {
      // Get user's current affiliations
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final classroomIds = List<String>.from(userData['classroomIds'] ?? []);
      final schoolId = userData['schoolId'] as String?;
      final state = userData['state'] as String?;

      // Get stored previous ranks
      final previousRanks = userData['previousRanks'] as Map<String, dynamic>?;

      // Check classroom rank
      if (classroomIds.isNotEmpty) {
        final classroomId = classroomIds.first;
        final oldRank = previousRanks?['classroom_$classroomId'] as int? ?? 999;
        await checkAndNotifyRankChanges(
          userId: userId,
          scope: 'classroom',
          type: 'all',
          period: 'allTime',
          identifier: classroomId,
          oldRank: oldRank,
        );
      }

      // Check school rank
      if (schoolId != null) {
        final oldRank = previousRanks?['school_$schoolId'] as int? ?? 999;
        await checkAndNotifyRankChanges(
          userId: userId,
          scope: 'school',
          type: 'all',
          period: 'allTime',
          identifier: schoolId,
          oldRank: oldRank,
        );
      }

      // Check state rank
      if (state != null) {
        final oldRank = previousRanks?['state_$state'] as int? ?? 999;
        await checkAndNotifyRankChanges(
          userId: userId,
          scope: 'state',
          type: 'all',
          period: 'allTime',
          identifier: state,
          oldRank: oldRank,
        );
      }

      // Check national rank
      final oldRank = previousRanks?['national'] as int? ?? 999;
      await checkAndNotifyRankChanges(
        userId: userId,
        scope: 'national',
        type: 'all',
        period: 'allTime',
        oldRank: oldRank,
      );

      // Update stored ranks for next comparison
      await _updateStoredRanks(userId);
    } catch (e) {
      // print('Error monitoring rank changes: $e');
    }
  }

  /// Update stored ranks in user document for future comparison
  Future<void> _updateStoredRanks(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final classroomIds = List<String>.from(userData['classroomIds'] ?? []);
      final schoolId = userData['schoolId'] as String?;
      final state = userData['state'] as String?;

      final newRanks = <String, int>{};

      // Get classroom rank
      if (classroomIds.isNotEmpty) {
        final classroomId = classroomIds.first;
        final rankData = await getUserRank(
          userId: userId,
          scope: 'classroom',
          type: 'all',
          period: 'allTime',
          identifier: classroomId,
        );
        if (rankData != null) {
          newRanks['classroom_$classroomId'] = rankData['rank'] as int;
        }
      }

      // Get school rank
      if (schoolId != null) {
        final rankData = await getUserRank(
          userId: userId,
          scope: 'school',
          type: 'all',
          period: 'allTime',
          identifier: schoolId,
        );
        if (rankData != null) {
          newRanks['school_$schoolId'] = rankData['rank'] as int;
        }
      }

      // Get state rank
      if (state != null) {
        final rankData = await getUserRank(
          userId: userId,
          scope: 'state',
          type: 'all',
          period: 'allTime',
          identifier: state,
        );
        if (rankData != null) {
          newRanks['state_$state'] = rankData['rank'] as int;
        }
      }

      // Get national rank
      final nationalRankData = await getUserRank(
        userId: userId,
        scope: 'national',
        type: 'all',
        period: 'allTime',
      );
      if (nationalRankData != null) {
        newRanks['national'] = nationalRankData['rank'] as int;
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'previousRanks': newRanks,
      });
    } catch (e) {
      // print('Error updating stored ranks: $e');
    }
  }
}

