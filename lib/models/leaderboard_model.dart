import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXP;
  final int rank;
  final String scope; // class, school, state, national
  final String? scopeId; // classroom id, school id, etc.
  final String period; // weekly, monthly, allTime
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXP,
    required this.rank,
    required this.scope,
    this.scopeId,
    required this.period,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalXP': totalXP,
      'rank': rank,
      'scope': scope,
      'scopeId': scopeId,
      'period': period,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'],
      totalXP: map['totalXP'] ?? 0,
      rank: map['rank'] ?? 0,
      scope: map['scope'] ?? 'national',
      scopeId: map['scopeId'],
      period: map['period'] ?? 'allTime',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

