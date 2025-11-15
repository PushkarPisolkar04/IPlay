import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_challenge_model.dart';

/// Service for daily challenges (loads from local JSON)
class DailyChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  
  List<Map<String, dynamic>>? _cachedChallenges;

  /// Load all challenges from local JSON
  Future<List<Map<String, dynamic>>> _loadChallenges() async {
    if (_cachedChallenges != null) return _cachedChallenges!;
    
    try {
      print('📅 Loading daily challenges from JSON...');
      final jsonString = await rootBundle.loadString('content/daily_challenges.json');
      print('✅ Daily challenges JSON loaded');
      
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ JSON parsed. Keys: ${jsonData.keys.join(", ")}');
      
      final challengesList = jsonData['challenges'];
      if (challengesList == null) {
        print('❌ Error: challenges field is null in JSON');
        return [];
      }
      
      _cachedChallenges = List<Map<String, dynamic>>.from(challengesList as List);
      print('✅ Loaded ${_cachedChallenges!.length} daily challenges');
      return _cachedChallenges!;
    } catch (e, stackTrace) {
      print('❌ Error loading daily challenges: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get today's daily challenge (rotates through available challenges)
  Future<DailyChallengeModel?> getTodaysChallenge() async {
    try {
      final challenges = await _loadChallenges();
      if (challenges.isEmpty) return null;

      // Use day of year to rotate through challenges
      final today = DateTime.now();
      final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
      final challengeIndex = dayOfYear % challenges.length;
      
      final challengeData = challenges[challengeIndex];
      
      // Convert to DailyChallengeModel
      final questions = (challengeData['questions'] as List).map((q) {
        return ChallengeQuestion(
          question: q['question'] as String,
          options: List<String>.from(q['options'] as List),
          correctAnswer: q['correctAnswer'] as int,
          explanation: q['explanation'] as String,
        );
      }).toList();

      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return DailyChallengeModel(
        id: '${challengeData['id']}_${today.year}_${today.month}_${today.day}',
        questions: questions,
        xpReward: challengeData['xpReward'] as int,
        date: startOfDay,
        expiresAt: endOfDay,
      );
    } catch (e) {
      print('Error getting today\'s challenge: $e');
      return null;
    }
  }

  /// Check if user has attempted today's challenge
  Future<bool> hasAttemptedToday(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'challenge_${today.year}_${today.month}_${today.day}';
      return prefs.containsKey(todayKey);
    } catch (e) {
      print('Error checking today\'s attempt: $e');
      return false;
    }
  }

  /// Submit challenge attempt (stores locally and in Firestore)
  Future<ChallengeAttemptModel> submitAttempt({
    required String userId,
    required String challengeId,
    required int score,
  }) async {
    try {
      // Check if already attempted today using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'challenge_${today.year}_${today.month}_${today.day}';
      final attemptedToday = prefs.getString(todayKey);
      
      if (attemptedToday != null) {
        throw Exception('Challenge already attempted today');
      }

      // Get today's challenge to calculate XP
      final challenge = await getTodaysChallenge();
      if (challenge == null) {
        throw Exception('Challenge not found');
      }

      // Calculate XP based on score (5 questions, 10 XP each = 50 XP max)
      final xpEarned = (score / 5 * challenge.xpReward).round();

      final attempt = ChallengeAttemptModel(
        id: _uuid.v4(),
        userId: userId,
        challengeId: challengeId,
        score: score,
        xpEarned: xpEarned,
        attemptedAt: DateTime.now(),
      );

      // Save attempt locally
      await prefs.setString(todayKey, json.encode({
        'id': attempt.id,
        'score': attempt.score,
        'xpEarned': attempt.xpEarned,
        'attemptedAt': attempt.attemptedAt.toIso8601String(),
      }));

      // Also save to Firestore for persistence and leaderboard
      try {
        final batch = _firestore.batch();

        // Save attempt
        batch.set(
          _firestore.collection('daily_challenge_attempts').doc(attempt.id),
          attempt.toFirestore(),
        );

        // Award XP to user
        batch.update(
          _firestore.collection('users').doc(userId),
          {
            'totalXP': FieldValue.increment(xpEarned),
          },
        );

        await batch.commit();
      } catch (e) {
        print('Error saving to Firestore: $e');
        // Continue even if Firestore fails - local save is enough
      }

      return attempt;
    } catch (e) {
      throw Exception('Failed to submit attempt: $e');
    }
  }

  /// Get user's attempt for a specific challenge (checks local storage first)
  Future<ChallengeAttemptModel?> getUserAttempt({
    required String userId,
    required String challengeId,
  }) async {
    try {
      // Check local storage first
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'challenge_${today.year}_${today.month}_${today.day}';
      final attemptData = prefs.getString(todayKey);
      
      if (attemptData != null) {
        final data = json.decode(attemptData) as Map<String, dynamic>;
        return ChallengeAttemptModel(
          id: data['id'] as String,
          userId: userId,
          challengeId: challengeId,
          score: data['score'] as int,
          xpEarned: data['xpEarned'] as int,
          attemptedAt: DateTime.parse(data['attemptedAt'] as String),
        );
      }

      // Fallback to Firestore
      try {
        final query = await _firestore
            .collection('daily_challenge_attempts')
            .where('userId', isEqualTo: userId)
            .where('challengeId', isEqualTo: challengeId)
            .limit(1)
            .get();

        if (query.docs.isEmpty) return null;

        return ChallengeAttemptModel.fromFirestore(query.docs.first.data());
      } catch (e) {
        print('Error fetching from Firestore: $e');
        return null;
      }
    } catch (e) {
      print('Error getting user attempt: $e');
      return null;
    }
  }

  /// Get user's challenge history
  Future<List<ChallengeAttemptModel>> getUserHistory(String userId, {int limit = 30}) async {
    try {
      final query = await _firestore
          .collection('daily_challenge_attempts')
          .where('userId', isEqualTo: userId)
          .orderBy('attemptedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => ChallengeAttemptModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user history: $e');
    }
  }

  /// Get user's challenge stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final history = await getUserHistory(userId);

      final totalAttempts = history.length;
      final totalXP = history.fold<int>(0, (sum, attempt) => sum + attempt.xpEarned);
      final perfectScores = history.where((a) => a.score == 5).length;
      
      double averageScore = 0;
      if (totalAttempts > 0) {
        final totalScore = history.fold<int>(0, (sum, attempt) => sum + attempt.score);
        averageScore = totalScore / totalAttempts;
      }

      // Calculate streak (consecutive days)
      int currentStreak = 0;
      if (history.isNotEmpty) {
        DateTime? lastDate;
        for (final attempt in history) {
          final attemptDate = DateTime(
            attempt.attemptedAt.year,
            attempt.attemptedAt.month,
            attempt.attemptedAt.day,
          );
          
          if (lastDate == null) {
            currentStreak = 1;
            lastDate = attemptDate;
          } else {
            final diff = lastDate.difference(attemptDate).inDays;
            if (diff == 1) {
              currentStreak++;
              lastDate = attemptDate;
            } else {
              break; // Streak broken
            }
          }
        }
      }

      return {
        'totalAttempts': totalAttempts,
        'totalXP': totalXP,
        'perfectScores': perfectScores,
        'averageScore': averageScore,
        'currentStreak': currentStreak,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  /// Get challenge leaderboard (today)
  Future<List<Map<String, dynamic>>> getTodayLeaderboard({int limit = 100}) async {
    try {
      final challenge = await getTodaysChallenge();
      if (challenge == null) return [];

      final query = await _firestore
          .collection('daily_challenge_attempts')
          .where('challengeId', isEqualTo: challenge.id)
          .orderBy('score', descending: true)
          .orderBy('attemptedAt', descending: false) // Earlier time breaks ties
          .limit(limit)
          .get();

      final attempts = query.docs
          .map((doc) => ChallengeAttemptModel.fromFirestore(doc.data()))
          .toList();

      // Fetch user details for each attempt
      final leaderboard = <Map<String, dynamic>>[];
      for (var i = 0; i < attempts.length; i++) {
        final attempt = attempts[i];
        
        // Get user details
        final userDoc = await _firestore
            .collection('users')
            .doc(attempt.userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          leaderboard.add({
            'rank': i + 1,
            'userId': attempt.userId,
            'displayName': userData['displayName'] ?? 'Unknown',
            'avatarUrl': userData['avatarUrl'],
            'score': attempt.score,
            'xpEarned': attempt.xpEarned,
            'attemptedAt': attempt.attemptedAt,
          });
        }
      }

      return leaderboard;
    } catch (e) {
      throw Exception('Failed to get today\'s leaderboard: $e');
    }
  }
}

