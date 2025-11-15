import 'package:flutter/material.dart';

/// Base game model for all educational games
class GameModel {
  final String id;
  final String name;
  final String description;
  final String summary;
  final String iconPath;
  final Color color;
  final String difficulty;
  final String gameType;
  final int xpReward;
  final int estimatedMinutes;
  final GameRewards rewards;
  final LeaderboardConfig leaderboard;
  final String version;
  final DateTime updatedAt;
  final bool allowRetry;

  GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.summary,
    required this.iconPath,
    required this.color,
    required this.difficulty,
    required this.gameType,
    required this.xpReward,
    required this.estimatedMinutes,
    required this.rewards,
    required this.leaderboard,
    required this.version,
    required this.updatedAt,
    this.allowRetry = true,
  }) {
    _validate();
  }

  /// Validate required fields
  void _validate() {
    if (id.isEmpty) throw ArgumentError('Game id cannot be empty');
    if (name.isEmpty) throw ArgumentError('Game name cannot be empty');
    if (xpReward < 0) throw ArgumentError('XP reward cannot be negative');
    if (estimatedMinutes < 0) throw ArgumentError('Estimated minutes cannot be negative');
  }

  /// Create from JSON
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      summary: json['summary'] as String? ?? json['description'] as String,
      iconPath: json['iconPath'] as String,
      color: Color(int.parse(json['color'] as String)),
      difficulty: json['difficulty'] as String,
      gameType: json['gameType'] as String,
      xpReward: json['xpReward'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      rewards: GameRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      leaderboard: LeaderboardConfig.fromJson(json['leaderboard'] as Map<String, dynamic>),
      version: json['version'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      allowRetry: json['allowRetry'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'summary': summary,
      'iconPath': iconPath,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      'difficulty': difficulty,
      'gameType': gameType,
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
      'rewards': rewards.toJson(),
      'leaderboard': leaderboard.toJson(),
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
      'allowRetry': allowRetry,
    };
  }
}

/// Game rewards configuration
class GameRewards {
  final int completion;
  final int perfectScore;
  final int firstTime;
  final int highScore;

  GameRewards({
    required this.completion,
    required this.perfectScore,
    required this.firstTime,
    required this.highScore,
  }) {
    _validate();
  }

  /// Validate reward values
  void _validate() {
    if (completion < 0) throw ArgumentError('Completion reward cannot be negative');
    if (perfectScore < 0) throw ArgumentError('Perfect score reward cannot be negative');
    if (firstTime < 0) throw ArgumentError('First time reward cannot be negative');
    if (highScore < 0) throw ArgumentError('High score reward cannot be negative');
  }

  /// Create from JSON
  factory GameRewards.fromJson(Map<String, dynamic> json) {
    return GameRewards(
      completion: json['completion'] as int,
      perfectScore: json['perfectScore'] as int,
      firstTime: json['firstTime'] as int,
      highScore: json['highScore'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'completion': completion,
      'perfectScore': perfectScore,
      'firstTime': firstTime,
      'highScore': highScore,
    };
  }
}

/// Leaderboard configuration
class LeaderboardConfig {
  final bool enabled;
  final List<String> scope;

  LeaderboardConfig({
    required this.enabled,
    required this.scope,
  }) {
    _validate();
  }

  /// Validate leaderboard configuration
  void _validate() {
    if (scope.isEmpty && enabled) {
      throw ArgumentError('Leaderboard scope cannot be empty when enabled');
    }
  }

  /// Create from JSON
  factory LeaderboardConfig.fromJson(Map<String, dynamic> json) {
    return LeaderboardConfig(
      enabled: json['enabled'] as bool,
      scope: List<String>.from(json['scope'] as List),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'scope': scope,
    };
  }
}
