import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_cache_model.dart';

/// Service for leaderboard operations using cached data
/// Note: Leaderboard cache is updated daily by Cloud Functions
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get leaderboard with specified scope and filters
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
      // Generate document ID based on parameters
      final docId = LeaderboardCacheModel.generateId(
        scope: scope,
        type: type,
        period: period,
        identifier: identifier,
      );

      final doc = await _firestore
          .collection('leaderboard_cache')
          .doc(docId)
          .get();

      if (!doc.exists) return null;

      return LeaderboardCacheModel.fromFirestore(doc.data()!);
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
}

