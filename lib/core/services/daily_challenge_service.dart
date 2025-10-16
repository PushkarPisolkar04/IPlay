import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_challenge_model.dart';

/// Service for daily challenges
class DailyChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Get today's daily challenge
  Future<DailyChallengeModel?> getTodaysChallenge() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _firestore
          .collection('daily_challenges')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return DailyChallengeModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get today\'s challenge: $e');
    }
  }

  /// Get challenge by ID
  Future<DailyChallengeModel?> getChallenge(String challengeId) async {
    try {
      final doc = await _firestore
          .collection('daily_challenges')
          .doc(challengeId)
          .get();

      if (!doc.exists) return null;

      return DailyChallengeModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get challenge: $e');
    }
  }

  /// Check if user has attempted today's challenge
  Future<bool> hasAttemptedToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get today's challenge
      final challenge = await getTodaysChallenge();
      if (challenge == null) return false;

      // Check if user has attempted it
      final query = await _firestore
          .collection('daily_challenge_attempts')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challenge.id)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check today\'s attempt: $e');
    }
  }

  /// Submit challenge attempt
  Future<ChallengeAttemptModel> submitAttempt({
    required String userId,
    required String challengeId,
    required int score,
  }) async {
    try {
      // Check if already attempted
      final existing = await _firestore
          .collection('daily_challenge_attempts')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Challenge already attempted today');
      }

      // Get challenge details
      final challenge = await getChallenge(challengeId);
      if (challenge == null) {
        throw Exception('Challenge not found');
      }

      // Check if challenge has expired
      if (DateTime.now().isAfter(challenge.expiresAt)) {
        throw Exception('Challenge has expired');
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

      return attempt;
    } catch (e) {
      throw Exception('Failed to submit attempt: $e');
    }
  }

  /// Get user's attempt for a specific challenge
  Future<ChallengeAttemptModel?> getUserAttempt({
    required String userId,
    required String challengeId,
  }) async {
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
      throw Exception('Failed to get user attempt: $e');
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

