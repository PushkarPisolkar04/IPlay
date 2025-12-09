import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_model.dart';

/// Service to manage user streak tracking
/// Tracks consecutive days of user activity and XP gains
class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update streak when user performs an activity that earns XP
  /// This should be called whenever a user gains XP from any activity
  Future<void> updateStreakOnActivity(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('⚠️ User document not found for streak update: $userId');
        return;
      }

      final userData = userDoc.data()!;
      final now = DateTime.now();
      
      // Get lastActiveDate - handle both Timestamp and DateTime
      DateTime lastActive;
      final lastActiveField = userData['lastActiveDate'];
      if (lastActiveField is Timestamp) {
        lastActive = lastActiveField.toDate();
      } else if (lastActiveField is DateTime) {
        lastActive = lastActiveField;
      } else {
        // If no lastActiveDate, this is first activity
        print('🆕 First activity for user - initializing streak');
        lastActive = DateTime.now().subtract(const Duration(days: 2)); // Force new streak
      }
      
      final currentStreak = userData['currentStreak'] ?? 0;
      final currentLongestStreak = userData['longestStreak'] ?? 0;

      print('📊 Streak Check:');
      print('   Last Active: ${lastActive.toString().split('.')[0]}');
      print('   Now: ${now.toString().split('.')[0]}');
      print('   Current Streak: $currentStreak days');
      print('   Same Day: ${_isSameDay(lastActive, now)}');
      print('   Hours Diff: ${now.difference(lastActive).inHours}h');

      // Check if we should reset or increment the streak
      final newStreak = _calculateNewStreak(lastActive, now, currentStreak);

      // Only update if the streak has changed or it's a new day
      if (newStreak != currentStreak || !_isSameDay(lastActive, now)) {
        final updateData = {
          'currentStreak': newStreak,
          'lastActiveDate': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        
        // Update longestStreak if current streak is higher
        if (newStreak > currentLongestStreak) {
          updateData['longestStreak'] = newStreak;
          print('🏆 New longest streak: $newStreak days!');
        }
        
        await _firestore.collection('users').doc(userId).update(updateData);
        print('✅ Streak updated: $currentStreak → $newStreak days');
      } else {
        print('ℹ️ Streak unchanged: $currentStreak days (same day activity)');
      }
    } catch (e) {
      // Log error but don't throw - streak updates shouldn't block main functionality
      print('❌ Error updating streak: $e');
    }
  }

  /// Check if streak should be reset based on last activity date
  /// Returns true if the streak should be reset (user missed more than grace period)
  bool shouldResetStreak(DateTime lastActivity) {
    final now = DateTime.now();
    final hoursDiff = now.difference(lastActivity).inHours;

    // 48-hour grace period (2 days)
    // This allows users to miss one day without losing their streak
    return hoursDiff > 48;
  }

  /// Get current streak count for a user
  Future<int> getCurrentStreak(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return 0;

      final user = UserModel.fromMap(userDoc.data()!);
      
      // Check if streak should be reset
      if (shouldResetStreak(user.lastActiveDate)) {
        return 0;
      }

      return user.currentStreak;
    } catch (e) {
      // print('Error getting current streak: $e');
      return 0;
    }
  }

  /// Calculate the new streak value based on last activity and current streak
  int _calculateNewStreak(DateTime lastActive, DateTime now, int currentStreak) {
    final hoursDiff = now.difference(lastActive).inHours;

    // If this is the first activity (currentStreak is 0), start at 1
    if (currentStreak == 0) {
      return 1;
    }

    if (hoursDiff <= 48) {
      // Within 48-hour grace period
      if (!_isSameDay(lastActive, now)) {
        // New day, increment streak
        return currentStreak + 1;
      }
      // Same day, streak unchanged
      return currentStreak;
    } else {
      // Streak broken (> 48 hours), reset to 1
      return 1;
    }
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
