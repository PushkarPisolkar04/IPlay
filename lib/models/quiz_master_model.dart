import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Quiz question model
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;
  final String realm;
  final int points;
  final String? hint;
  final String? imageUrl;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.realm,
    required this.points,
    this.hint,
    this.imageUrl,
  }) {
    _validate();
  }

  /// Validate question data
  void _validate() {
    if (id.isEmpty) throw ArgumentError('Question id cannot be empty');
    if (question.isEmpty) throw ArgumentError('Question cannot be empty');
    if (options.length < 2) throw ArgumentError('Must have at least 2 options');
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw ArgumentError('Correct index out of range');
    }
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  /// Create from JSON
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as String,
      realm: json['realm'] as String,
      points: json['points'] as int,
      hint: json['hint'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty,
      'realm': realm,
      'points': points,
      if (hint != null) 'hint': hint,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

/// Quiz Master game model
class QuizMasterGame extends GameModel {
  final List<QuizQuestion> questionPool;
  final int questionsPerGame;
  final int passingScore;
  final int? timeLimit;
  final bool randomSelection;
  final bool showHintsAfterWrongAnswer;

  QuizMasterGame({
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
    required this.questionPool,
    required this.questionsPerGame,
    required this.passingScore,
    this.timeLimit,
    this.randomSelection = true,
    this.showHintsAfterWrongAnswer = true,
  }) {
    _validate();
  }

  /// Validate quiz game data
  void _validate() {
    if (questionPool.isEmpty) {
      throw ArgumentError('Question pool cannot be empty');
    }
    if (questionsPerGame <= 0) {
      throw ArgumentError('Questions per game must be positive');
    }
    if (questionsPerGame > questionPool.length) {
      throw ArgumentError('Questions per game exceeds pool size');
    }
    if (passingScore < 0 || passingScore > 100) {
      throw ArgumentError('Passing score must be between 0 and 100');
    }
  }

  /// Select random questions from pool
  List<QuizQuestion> selectRandomQuestions() {
    if (!randomSelection) {
      return questionPool.take(questionsPerGame).toList();
    }

    final random = Random();
    final shuffled = List<QuizQuestion>.from(questionPool)..shuffle(random);
    return shuffled.take(questionsPerGame).toList();
  }

  /// Get questions by difficulty
  List<QuizQuestion> getQuestionsByDifficulty(String difficulty) {
    return questionPool
        .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  /// Get questions by realm
  List<QuizQuestion> getQuestionsByRealm(String realm) {
    return questionPool
        .where((q) => q.realm.toLowerCase() == realm.toLowerCase())
        .toList();
  }

  /// Create from JSON
  factory QuizMasterGame.fromJson(Map<String, dynamic> json) {
    return QuizMasterGame(
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
      questionPool: (json['questionPool'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      questionsPerGame: json['questionsPerGame'] as int,
      passingScore: json['passingScore'] as int,
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
      'questionPool': questionPool.map((q) => q.toJson()).toList(),
      'questionsPerGame': questionsPerGame,
      'passingScore': passingScore,
      if (timeLimit != null) 'timeLimit': timeLimit,
      'randomSelection': randomSelection,
      'showHintsAfterWrongAnswer': showHintsAfterWrongAnswer,
    };
  }
}
