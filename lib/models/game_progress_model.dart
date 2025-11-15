import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking individual game progress
class GameProgress {
  final String gameId;
  final String userId;
  final int gamesPlayed;
  final int highScore;
  final int averageScore;
  final int totalScore;
  final int totalTimeSpent; // in seconds
  final bool completed;
  final DateTime? lastPlayedAt;
  final DateTime? firstCompletedAt;
  final DateTime updatedAt;

  GameProgress({
    required this.gameId,
    required this.userId,
    required this.gamesPlayed,
    required this.highScore,
    required this.averageScore,
    required this.totalScore,
    required this.totalTimeSpent,
    required this.completed,
    this.lastPlayedAt,
    this.firstCompletedAt,
    required this.updatedAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'userId': userId,
      'gamesPlayed': gamesPlayed,
      'highScore': highScore,
      'averageScore': averageScore,
      'totalScore': totalScore,
      'totalTimeSpent': totalTimeSpent,
      'completed': completed,
      'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
      'firstCompletedAt': firstCompletedAt != null ? Timestamp.fromDate(firstCompletedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore map
  factory GameProgress.fromMap(Map<String, dynamic> map) {
    return GameProgress(
      gameId: map['gameId'] ?? '',
      userId: map['userId'] ?? '',
      gamesPlayed: map['gamesPlayed'] ?? 0,
      highScore: map['highScore'] ?? 0,
      averageScore: map['averageScore'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
      completed: map['completed'] ?? false,
      lastPlayedAt: (map['lastPlayedAt'] as Timestamp?)?.toDate(),
      firstCompletedAt: (map['firstCompletedAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get formatted time spent
  String get formattedTimeSpent {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    final seconds = totalTimeSpent % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Model for leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int rank;
  final String? schoolTag;
  final String? state;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.rank,
    this.schoolTag,
    this.state,
    required this.updatedAt,
  });

  /// Create from Firestore map
  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Anonymous',
      avatarUrl: map['avatarUrl'],
      score: map['score'] ?? 0,
      rank: rank,
      schoolTag: map['schoolTag'],
      state: map['state'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'schoolTag': schoolTag,
      'state': state,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
