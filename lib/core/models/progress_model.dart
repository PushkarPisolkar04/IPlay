import 'package:cloud_firestore/cloud_firestore.dart';

/// Progress model to track user's learning progress in a realm
class ProgressModel {
  final String userId;
  final String realmId;
  final List<int> completedLevels; // List of completed level numbers
  final int currentLevelNumber; // Next level to be completed
  final int xpEarned; // Total XP earned in this realm
  final DateTime? lastAccessedAt;

  ProgressModel({
    required this.userId,
    required this.realmId,
    required this.completedLevels,
    required this.currentLevelNumber,
    required this.xpEarned,
    this.lastAccessedAt,
  });

  /// Calculate progress percentage
  double getProgressPercentage(int totalLevels) {
    if (totalLevels == 0) return 0.0;
    return (completedLevels.length / totalLevels) * 100;
  }

  /// Check if a specific level is completed
  bool isLevelCompleted(int levelNumber) {
    return completedLevels.contains(levelNumber);
  }

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      userId: map['userId'] ?? '',
      realmId: map['realmId'] ?? '',
      completedLevels: List<int>.from(map['completedLevels'] ?? []),
      currentLevelNumber: map['currentLevelNumber'] ?? 1,
      xpEarned: map['xpEarned'] ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null 
          ? (map['lastAccessedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'realmId': realmId,
      'completedLevels': completedLevels,
      'currentLevelNumber': currentLevelNumber,
      'xpEarned': xpEarned,
      'lastAccessedAt': lastAccessedAt != null 
          ? Timestamp.fromDate(lastAccessedAt!)
          : null,
    };
  }

  ProgressModel copyWith({
    String? userId,
    String? realmId,
    List<int>? completedLevels,
    int? currentLevelNumber,
    int? xpEarned,
    DateTime? lastAccessedAt,
  }) {
    return ProgressModel(
      userId: userId ?? this.userId,
      realmId: realmId ?? this.realmId,
      completedLevels: completedLevels ?? this.completedLevels,
      currentLevelNumber: currentLevelNumber ?? this.currentLevelNumber,
      xpEarned: xpEarned ?? this.xpEarned,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

