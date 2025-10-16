import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';
import '../widgets/clean_card.dart';

/// Daily Challenge Card Widget - Shows challenge status and CTA
class DailyChallengeCard extends StatefulWidget {
  final VoidCallback? onTap;

  const DailyChallengeCard({Key? key, this.onTap}) : super(key: key);

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  bool _isLoading = true;
  String _status = 'loading'; // loading, available, completed, locked
  int _score = 0;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadChallengeStatus();
  }

  Future<void> _loadChallengeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _status = 'locked';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get today's challenge
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final challengeQuery = await FirebaseFirestore.instance
          .collection('daily_challenges')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .limit(1)
          .get();

      if (challengeQuery.docs.isEmpty) {
        // No challenge today (will be auto-generated at 12:01 AM)
        setState(() {
          _status = 'locked';
          _isLoading = false;
        });
        return;
      }

      final challengeId = challengeQuery.docs.first.id;

      // Check if user has attempted
      final attemptQuery = await FirebaseFirestore.instance
          .collection('daily_challenge_attempts')
          .where('userId', isEqualTo: user.uid)
          .where('challengeId', isEqualTo: challengeId)
          .limit(1)
          .get();

      if (attemptQuery.docs.isEmpty) {
        // Challenge available
        setState(() {
          _status = 'available';
          _isLoading = false;
        });
      } else {
        // Challenge completed
        final attemptData = attemptQuery.docs.first.data();
        setState(() {
          _status = 'completed';
          _score = attemptData['score'] ?? 0;
          _xpEarned = attemptData['xpEarned'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading challenge status: $e');
      setState(() {
        _status = 'locked';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CleanCard(
        child: Container(
          height: 120,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GestureDetector(
      onTap: _status == 'available' ? widget.onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getMainColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '⚡ Daily Challenge',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_status == 'completed')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✓ Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (_status == 'completed') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$_score/5',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '+$_xpEarned XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow (if available)
              if (_status == 'available')
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (_status) {
      case 'available':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'completed':
        return const LinearGradient(
          colors: [Color(0xFF56ab2f), Color(0xFF a8e063)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'locked':
      default:
        return const LinearGradient(
          colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getMainColor() {
    switch (_status) {
      case 'available':
        return const Color(0xFF667eea);
      case 'completed':
        return const Color(0xFF56ab2f);
      case 'locked':
      default:
        return const Color(0xFF757F9A);
    }
  }

  IconData _getIcon() {
    switch (_status) {
      case 'available':
        return Icons.flash_on;
      case 'completed':
        return Icons.check_circle;
      case 'locked':
      default:
        return Icons.lock;
    }
  }

  String _getSubtitle() {
    switch (_status) {
      case 'available':
        return 'Answer 5 questions • Earn 50 XP';
      case 'completed':
        return 'Come back tomorrow for a new challenge!';
      case 'locked':
      default:
        return 'New challenges daily at 12:01 AM';
    }
  }
}

