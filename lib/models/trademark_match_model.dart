import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Trademark pair model
class TrademarkPair {
  final String id;
  final String trademark;
  final String company;
  final String imageUrl;
  final String hint;
  final String difficulty;
  final int points;
  final String category;
  final String region;

  TrademarkPair({
    required this.id,
    required this.trademark,
    required this.company,
    required this.imageUrl,
    required this.hint,
    required this.difficulty,
    required this.points,
    required this.category,
    required this.region,
  }) {
    _validate();
  }

  /// Validate trademark pair data
  void _validate() {
    if (id.isEmpty) throw ArgumentError('Trademark pair id cannot be empty');
    if (trademark.isEmpty) throw ArgumentError('Trademark cannot be empty');
    if (company.isEmpty) throw ArgumentError('Company cannot be empty');
    if (imageUrl.isEmpty) throw ArgumentError('Image URL cannot be empty');
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  /// Create from JSON
  factory TrademarkPair.fromJson(Map<String, dynamic> json) {
    return TrademarkPair(
      id: json['id'] as String,
      trademark: json['trademark'] as String,
      company: json['company'] as String,
      imageUrl: json['imageUrl'] as String,
      hint: json['hint'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      category: json['category'] as String,
      region: json['region'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trademark': trademark,
      'company': company,
      'imageUrl': imageUrl,
      'hint': hint,
      'difficulty': difficulty,
      'points': points,
      'category': category,
      'region': region,
    };
  }
}

/// Trademark Match game model
class TrademarkMatchGame extends GameModel {
  final List<TrademarkPair> matchPairs;
  final int pairsPerGame;
  final int? timeLimit;
  final bool randomSelection;
  final bool showHintsAfterWrongAnswer;

  TrademarkMatchGame({
    required super.id,
    required super.name,
    required super.description,
    required super.summary,
    required super.iconPath,
    required super.color,
    required super.difficulty,
    required super.gameType,
    required super.xpReward,
    required super.estimatedMinutes,
    required super.rewards,
    required super.leaderboard,
    required super.version,
    required super.updatedAt,
    super.allowRetry,
    required this.matchPairs,
    required this.pairsPerGame,
    this.timeLimit,
    this.randomSelection = true,
    this.showHintsAfterWrongAnswer = true,
  }) {
    _validate();
  }

  /// Validate trademark match game data
  void _validate() {
    if (matchPairs.isEmpty) {
      throw ArgumentError('Match pairs cannot be empty');
    }
    if (pairsPerGame <= 0) {
      throw ArgumentError('Pairs per game must be positive');
    }
    if (pairsPerGame > matchPairs.length) {
      throw ArgumentError('Pairs per game exceeds available pairs');
    }
  }

  /// Select random pairs for a game session
  List<TrademarkPair> selectRandomPairs() {
    if (!randomSelection) {
      return matchPairs.take(pairsPerGame).toList();
    }

    final random = Random();
    final shuffled = List<TrademarkPair>.from(matchPairs)..shuffle(random);
    return shuffled.take(pairsPerGame).toList();
  }

  /// Shuffle pairs for matching game
  Map<String, List<TrademarkPair>> shufflePairsForGame(List<TrademarkPair> pairs) {
    final random = Random();
    final logos = List<TrademarkPair>.from(pairs)..shuffle(random);
    final companies = List<TrademarkPair>.from(pairs)..shuffle(random);
    
    return {
      'logos': logos,
      'companies': companies,
    };
  }

  /// Get pairs by difficulty
  List<TrademarkPair> getPairsByDifficulty(String difficulty) {
    return matchPairs
        .where((p) => p.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  /// Get pairs by category
  List<TrademarkPair> getPairsByCategory(String category) {
    return matchPairs
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get pairs by region
  List<TrademarkPair> getPairsByRegion(String region) {
    return matchPairs
        .where((p) => p.region.toLowerCase() == region.toLowerCase())
        .toList();
  }

  /// Create from JSON
  factory TrademarkMatchGame.fromJson(Map<String, dynamic> json) {
    return TrademarkMatchGame(
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
      matchPairs: (json['matchPairs'] as List)
          .map((p) => TrademarkPair.fromJson(p as Map<String, dynamic>))
          .toList(),
      pairsPerGame: json['pairsPerGame'] as int,
      timeLimit: json['timeLimit'] as int?,
      randomSelection: json['randomSelection'] as bool? ?? true,
      showHintsAfterWrongAnswer: json['showHintsAfterWrongAnswer'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'matchPairs': matchPairs.map((p) => p.toJson()).toList(),
      'pairsPerGame': pairsPerGame,
      if (timeLimit != null) 'timeLimit': timeLimit,
      'randomSelection': randomSelection,
      'showHintsAfterWrongAnswer': showHintsAfterWrongAnswer,
    };
  }
}
