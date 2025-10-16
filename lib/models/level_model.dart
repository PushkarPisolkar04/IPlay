import 'package:cloud_firestore/cloud_firestore.dart';

class LevelModel {
  final String id;
  final String realmId;
  final String title;
  final String description;
  final int levelNumber;
  final String lessonContent; // JSON string or markdown
  final List<QuizQuestion> quizQuestions;
  final int xpReward;
  final int estimatedMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LevelModel({
    required this.id,
    required this.realmId,
    required this.title,
    required this.description,
    required this.levelNumber,
    required this.lessonContent,
    required this.quizQuestions,
    required this.xpReward,
    required this.estimatedMinutes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realmId': realmId,
      'title': title,
      'description': description,
      'levelNumber': levelNumber,
      'lessonContent': lessonContent,
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    return LevelModel(
      id: map['id'] ?? '',
      realmId: map['realmId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      levelNumber: map['levelNumber'] ?? 0,
      lessonContent: map['lessonContent'] ?? '',
      quizQuestions: (map['quizQuestions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      xpReward: map['xpReward'] ?? 0,
      estimatedMinutes: map['estimatedMinutes'] ?? 5,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final int timeLimit; // in seconds

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.timeLimit = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'timeLimit': timeLimit,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      timeLimit: map['timeLimit'] ?? 30,
    );
  }
}

