import 'package:cloud_firestore/cloud_firestore.dart';

class LevelModel {
  final String id;
  final String realmId;
  final String title;
  final String difficulty; // Easy, Medium, Hard, Expert
  final int levelNumber;
  final String content; // Markdown content
  final List<Map<String, dynamic>> quiz; // Quiz questions as maps
  final int xp; // XP reward
  final bool isActive;

  LevelModel({
    required this.id,
    required this.realmId,
    required this.title,
    required this.difficulty,
    required this.levelNumber,
    required this.content,
    required this.quiz,
    required this.xp,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realmId': realmId,
      'title': title,
      'difficulty': difficulty,
      'levelNumber': levelNumber,
      'content': content,
      'quiz': quiz,
      'xp': xp,
      'isActive': isActive,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    return LevelModel(
      id: map['id'] ?? '',
      realmId: map['realmId'] ?? '',
      title: map['title'] ?? '',
      difficulty: map['difficulty'] ?? 'Easy',
      levelNumber: map['levelNumber'] ?? 0,
      content: map['content'] ?? '',
      quiz: List<Map<String, dynamic>>.from(map['quiz'] ?? []),
      xp: map['xp'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
  
  // Helper getters for compatibility
  String get description => difficulty;
  String get lessonContent => content;
  int get xpReward => xp;
  int get estimatedMinutes => (content.length / 100).ceil().clamp(5, 30);
  DateTime get createdAt => DateTime.now();
  DateTime get updatedAt => DateTime.now();
  List<QuizQuestion> get quizQuestions => quiz.map((q) => QuizQuestion.fromMap(q)).toList();
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer; // Index of correct answer
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
  
  // Compatibility getter
  int get correctAnswerIndex => correctAnswer;
  int get timeLimit => 30;
}

