import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily challenge question model
class ChallengeQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer; // Index of correct option (0-3)
  final String explanation;

  ChallengeQuestion({
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

  factory ChallengeQuestion.fromMap(Map<String, dynamic> map) {
    return ChallengeQuestion(
      question: map['question'] as String,
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'] as int,
      explanation: map['explanation'] as String,
    );
  }
}

/// Daily challenge model
/// Collection: /daily_challenges
class DailyChallengeModel {
  final String id;
  final DateTime date;
  final List<ChallengeQuestion> questions;
  final int xpReward;
  final DateTime expiresAt;

  DailyChallengeModel({
    required this.id,
    required this.date,
    required this.questions,
    required this.xpReward,
    required this.expiresAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'questions': questions.map((q) => q.toMap()).toList(),
      'xpReward': xpReward,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Create from Firestore document
  factory DailyChallengeModel.fromFirestore(Map<String, dynamic> data) {
    return DailyChallengeModel(
      id: data['id'] as String,
      date: (data['date'] as Timestamp).toDate(),
      questions: (data['questions'] as List)
          .map((q) => ChallengeQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      xpReward: data['xpReward'] as int,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }
}

/// Daily challenge attempt model
/// Collection: /daily_challenge_attempts
class ChallengeAttemptModel {
  final String id;
  final String userId;
  final String challengeId;
  final int score; // Number of correct answers (out of 5)
  final int xpEarned;
  final DateTime attemptedAt;

  ChallengeAttemptModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.score,
    required this.xpEarned,
    required this.attemptedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'challengeId': challengeId,
      'score': score,
      'xpEarned': xpEarned,
      'attemptedAt': Timestamp.fromDate(attemptedAt),
    };
  }

  /// Create from Firestore document
  factory ChallengeAttemptModel.fromFirestore(Map<String, dynamic> data) {
    return ChallengeAttemptModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      challengeId: data['challengeId'] as String,
      score: data['score'] as int,
      xpEarned: data['xpEarned'] as int,
      attemptedAt: (data['attemptedAt'] as Timestamp).toDate(),
    );
  }
}

