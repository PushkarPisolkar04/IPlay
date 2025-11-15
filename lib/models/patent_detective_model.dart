import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Patent information model
class PatentInfo {
  final String patentNumber;
  final String inventor;
  final int year;
  final String title;
  final String innovation;

  PatentInfo({
    required this.patentNumber,
    required this.inventor,
    required this.year,
    required this.title,
    required this.innovation,
  });

  factory PatentInfo.fromJson(Map<String, dynamic> json) {
    return PatentInfo(
      patentNumber: json['patentNumber'] as String,
      inventor: json['inventor'] as String,
      year: json['year'] as int,
      title: json['title'] as String,
      innovation: json['innovation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patentNumber': patentNumber,
      'inventor': inventor,
      'year': year,
      'title': title,
      'innovation': innovation,
    };
  }
}

/// Detective case model
class DetectiveCase {
  final String id;
  final String caseNumber;
  final String category;
  final String difficulty;
  final int points;
  final List<String> clues;
  final List<String> suspects;
  final int correctIndex;
  final PatentInfo patentInfo;
  final String explanation;

  DetectiveCase({
    required this.id,
    required this.caseNumber,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.clues,
    required this.suspects,
    required this.correctIndex,
    required this.patentInfo,
    required this.explanation,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) throw ArgumentError('Case id cannot be empty');
    if (caseNumber.isEmpty) throw ArgumentError('Case number cannot be empty');
    if (clues.isEmpty) throw ArgumentError('Clues cannot be empty');
    if (suspects.length < 2) throw ArgumentError('Must have at least 2 suspects');
    if (correctIndex < 0 || correctIndex >= suspects.length) {
      throw ArgumentError('Correct index out of range');
    }
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  /// Calculate points based on clues revealed
  int calculatePoints(int cluesRevealed) {
    if (cluesRevealed <= 0) return points;
    
    // Bonus for solving with fewer clues
    final bonusMultiplier = (clues.length - cluesRevealed + 1) / clues.length;
    return (points * bonusMultiplier).round().clamp(points ~/ 2, points);
  }

  factory DetectiveCase.fromJson(Map<String, dynamic> json) {
    return DetectiveCase(
      id: json['id'] as String,
      caseNumber: json['caseNumber'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      clues: List<String>.from(json['clues'] as List),
      suspects: List<String>.from(json['suspects'] as List),
      correctIndex: json['correctIndex'] as int,
      patentInfo: PatentInfo.fromJson(json['patentInfo'] as Map<String, dynamic>),
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseNumber': caseNumber,
      'category': category,
      'difficulty': difficulty,
      'points': points,
      'clues': clues,
      'suspects': suspects,
      'correctIndex': correctIndex,
      'patentInfo': patentInfo.toJson(),
      'explanation': explanation,
    };
  }
}

/// Patent Detective game model
class PatentDetectiveGame extends GameModel {
  final List<DetectiveCase> cases;
  final int casesPerGame;
  final bool randomSelection;
  final bool allowRetry;

  PatentDetectiveGame({
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
    required this.cases,
    required this.casesPerGame,
    this.randomSelection = true,
    this.allowRetry = true,
  }) : super(allowRetry: allowRetry) {
    _validate();
  }

  void _validate() {
    if (cases.isEmpty) {
      throw ArgumentError('Cases cannot be empty');
    }
    if (casesPerGame <= 0) {
      throw ArgumentError('Cases per game must be positive');
    }
    if (casesPerGame > cases.length) {
      throw ArgumentError('Cases per game exceeds available cases');
    }
  }

  /// Select random cases for a game session
  List<DetectiveCase> selectRandomCases() {
    if (!randomSelection) {
      return cases.take(casesPerGame).toList();
    }

    final random = Random();
    final shuffled = List<DetectiveCase>.from(cases)..shuffle(random);
    return shuffled.take(casesPerGame).toList();
  }

  /// Get cases by category
  List<DetectiveCase> getCasesByCategory(String category) {
    return cases
        .where((c) => c.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get cases by difficulty
  List<DetectiveCase> getCasesByDifficulty(String difficulty) {
    return cases
        .where((c) => c.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  factory PatentDetectiveGame.fromJson(Map<String, dynamic> json) {
    return PatentDetectiveGame(
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
      cases: (json['cases'] as List)
          .map((c) => DetectiveCase.fromJson(c as Map<String, dynamic>))
          .toList(),
      casesPerGame: json['casesPerGame'] as int,
      randomSelection: json['randomSelection'] as bool? ?? true,
      allowRetry: json['allowRetry'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'cases': cases.map((c) => c.toJson()).toList(),
      'casesPerGame': casesPerGame,
      'randomSelection': randomSelection,
    };
  }
}
