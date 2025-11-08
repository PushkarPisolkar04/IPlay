import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'xp_service.dart';

/// Service to manage daily login rewards
class DailyRewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final XPService _xpService = XPService();

  /// Check and award daily login reward
  /// Returns reward info if awarded, null if already claimed today
  Future<DailyReward?> checkAndAwardDailyReward() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final lastActiveDate = (userData['lastActiveDate'] as Timestamp?)?.toDate();
      final currentStreak = userData['currentStreak'] as int? ?? 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already claimed today
      if (lastActiveDate != null) {
        final lastActiveDay = DateTime(
          lastActiveDate.year,
          lastActiveDate.month,
          lastActiveDate.day,
        );

        if (lastActiveDay == today) {
          // Already claimed today
          return null;
        }
      }

      // Calculate new streak
      int newStreak = currentStreak;
      bool streakBroken = false;

      if (lastActiveDate != null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final lastActiveDay = DateTime(
          lastActiveDate.year,
          lastActiveDate.month,
          lastActiveDate.day,
        );

        if (lastActiveDay == yesterday) {
          // Consecutive day - increment streak
          newStreak = currentStreak + 1;
        } else {
          // Streak broken - reset to 1
          newStreak = 1;
          streakBroken = true;
        }
      } else {
        // First login
        newStreak = 1;
      }

      // Award daily XP
      const dailyXP = 10;
      await _xpService.awardXPAndCheckRank(
        userId: user.uid,
        xpAmount: dailyXP,
      );

      // Check for 7-day streak bonus
      int bonusXP = 0;
      bool isStreakMilestone = false;
      if (newStreak % 7 == 0) {
        bonusXP = 100;
        isStreakMilestone = true;
        await _xpService.awardXPAndCheckRank(
          userId: user.uid,
          xpAmount: bonusXP,
        );
      }

      // Update user data
      await _firestore.collection('users').doc(user.uid).update({
        'lastActiveDate': FieldValue.serverTimestamp(),
        'currentStreak': newStreak,
        'maxStreak': newStreak > (userData['maxStreak'] as int? ?? 0)
            ? newStreak
            : userData['maxStreak'],
      });

      return DailyReward(
        dailyXP: dailyXP,
        bonusXP: bonusXP,
        currentStreak: newStreak,
        isStreakMilestone: isStreakMilestone,
        streakBroken: streakBroken,
      );
    } catch (e) {
      // print('Error checking daily reward: $e');
      return null;
    }
  }

  /// Show daily reward dialog
  static void showDailyRewardDialog(
    BuildContext context,
    DailyReward reward,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardDialog(reward: reward),
    );
  }
}

class DailyReward {
  final int dailyXP;
  final int bonusXP;
  final int currentStreak;
  final bool isStreakMilestone;
  final bool streakBroken;

  DailyReward({
    required this.dailyXP,
    required this.bonusXP,
    required this.currentStreak,
    required this.isStreakMilestone,
    required this.streakBroken,
  });

  int get totalXP => dailyXP + bonusXP;
}

/// Daily reward dialog widget
class DailyRewardDialog extends StatefulWidget {
  final DailyReward reward;

  const DailyRewardDialog({
    super.key,
    required this.reward,
  });

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getMessage() {
    if (widget.reward.streakBroken) {
      return "Don't worry! Start a new streak today!";
    } else if (widget.reward.isStreakMilestone) {
      return "Amazing! ${widget.reward.currentStreak} days in a row!";
    } else if (widget.reward.currentStreak == 1) {
      return "Welcome back! Keep the streak going!";
    } else {
      return "Great! ${widget.reward.currentStreak} days in a row!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flame icon with animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.3),
                          Colors.orange.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🔥',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Daily Reward!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Streak info
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.reward.currentStreak} Day Streak',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getMessage(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // XP rewards
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Daily XP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.reward.dailyXP} XP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '(Daily Login)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      // Bonus XP
                      if (widget.reward.bonusXP > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.celebration, color: Colors.purple),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.reward.bonusXP} XP',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '(Streak Bonus!)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Total: +${widget.reward.totalXP} XP',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Continue button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
