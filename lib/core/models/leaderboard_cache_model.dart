import 'package:cloud_firestore/cloud_firestore.dart';

/// Leaderboard entry for cached leaderboard
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXP;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXP,
    required this.rank,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalXP': totalXP,
      'rank': rank,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      totalXP: map['totalXP'] as int,
      rank: map['rank'] as int,
    );
  }
}

/// Leaderboard cache model for daily aggregated leaderboards
/// Collection: /leaderboard_cache
/// Document ID format: {scope}_{type}_{period}_{identifier}
/// Examples:
///   - national_all_week
///   - state_solo_month_Delhi
///   - classroom_all_week_classroom123
class LeaderboardCacheModel {
  final String id;
  final String scope; // 'national' | 'state' | 'school' | 'classroom'
  final String type; // 'all' | 'solo' (solo learners = not in any classroom)
  final String period; // 'week' | 'month' | 'allTime'
  final String? identifier; // stateCode, schoolId, or classroomId (null for national)
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdatedAt;

  LeaderboardCacheModel({
    required this.id,
    required this.scope,
    required this.type,
    required this.period,
    this.identifier,
    required this.entries,
    required this.lastUpdatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'scope': scope,
      'type': type,
      'period': period,
      'identifier': identifier,
      'entries': entries.map((e) => e.toMap()).toList(),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  /// Create from Firestore document
  factory LeaderboardCacheModel.fromFirestore(Map<String, dynamic> data) {
    return LeaderboardCacheModel(
      id: data['id'] as String,
      scope: data['scope'] as String,
      type: data['type'] as String,
      period: data['period'] as String,
      identifier: data['identifier'] as String?,
      entries: (data['entries'] as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }

  /// Generate document ID for leaderboard cache
  static String generateId({
    required String scope,
    required String type,
    required String period,
    String? identifier,
  }) {
    final parts = [scope, type, period];
    if (identifier != null) {
      parts.add(identifier);
    }
    return parts.join('_');
  }
}

