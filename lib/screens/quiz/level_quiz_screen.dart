import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/realm_model.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/certificate_service.dart';
import '../../core/services/xp_service.dart';
import '../../core/services/content_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../services/sound_service.dart';
import '../../services/app_rating_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for taking a level quiz
class LevelQuizScreen extends StatefulWidget {
  final LevelModel level;

  const LevelQuizScreen({
    super.key,
    required this.level,
  });

  @override
  State<LevelQuizScreen> createState() => _LevelQuizScreenState();
}

class _LevelQuizScreenState extends State<LevelQuizScreen> {
  final ProgressService _progressService = ProgressService();
  final CertificateService _certificateService = CertificateService();
  final XPService _xpService = XPService();
  final ContentService _contentService = ContentService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  int _currentQuestionIndex = 0;
  int _score = 0;
  List<int?> _selectedAnswers = [];
  bool _showExplanation = false;
  bool _isQuizCompleted = false;
  bool _certificateGenerated = false;
  int _bonusXP = 0;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.level.quiz.length, null);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _selectAnswer(int optionIndex) {
    if (_showExplanation) return; // Don't allow changing answer after submission

    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswers[_currentQuestionIndex] == null) {
      // Show error if no answer selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final question = widget.level.quiz[_currentQuestionIndex];
    final isCorrect =
        _selectedAnswers[_currentQuestionIndex] == question.correctIndex;

    if (isCorrect) {
      _score++;
      // Haptic feedback for correct answer
      HapticFeedbackUtil.correctAnswer();
      // Sound effect for correct answer
      SoundService.playCorrectAnswer();
    } else {
      // Haptic feedback for incorrect answer
      HapticFeedbackUtil.incorrectAnswer();
      // Sound effect for incorrect answer
      SoundService.playIncorrectAnswer();
    }

    setState(() {
      _showExplanation = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.level.quiz.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showExplanation = false;
      });
    } else {
      _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    final percentage = (_score / widget.level.quiz.length) * 100;
    final passed = percentage >= 60; // Pass if 60% or higher

    if (passed) {
      _confettiController.play();
      // Haptic feedback for XP gain
      HapticFeedbackUtil.xpGain();
      // Sound effect for level completion
      SoundService.playLevelComplete();

      // Save progress if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _progressService.completeLevel(
            userId: user.uid,
            realmId: widget.level.realmId,
            levelNumber: widget.level.levelNumber,
            xpEarned: widget.level.xpReward,
            quizScore: _score,
            totalQuestions: widget.level.quiz.length,
          );

          // Check if realm is complete and generate certificate
          await _checkAndGenerateCertificate(user.uid);
        } catch (e) {
          // print('Error saving progress: $e');
        }
      }
    }

    setState(() {
      _isQuizCompleted = true;
    });
  }

  /// Check if realm is complete and generate certificate
  Future<void> _checkAndGenerateCertificate(String userId) async {
    try {
      // Get realm info
      final realm = _contentService.getRealmById(widget.level.realmId);
      if (realm == null) return;

      // Get user's progress for this realm
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final progressSummary = userData['progressSummary'] as Map<String, dynamic>? ?? {};
      final realmProgress = progressSummary[widget.level.realmId] as Map<String, dynamic>? ?? {};

      final levelsCompleted = realmProgress['levelsCompleted'] as int? ?? 0;
      final totalLevels = realm.totalLevels;

      // Check if all levels are completed
      if (levelsCompleted >= totalLevels) {
        // Check if certificate already exists
        final existingCert = await _certificateService.getUserRealmCertificate(
          userId: userId,
          realmId: widget.level.realmId,
        );

        if (existingCert == null) {
          // Generate certificate
          await _certificateService.generateRealmCertificate(
            realmId: widget.level.realmId,
            realmName: realm.name,
          );

          // Award realm completion bonus XP
          final bonusXP = await _xpService.awardRealmCompletionBonus(
            userId: userId,
            realmId: widget.level.realmId,
            levelsCompleted: levelsCompleted,
            totalLevels: totalLevels,
          );

          setState(() {
            _certificateGenerated = true;
            _bonusXP = bonusXP;
          });

          // Haptic feedback for badge/certificate unlock
          HapticFeedbackUtil.badgeUnlock();

          // Track realm completion for app rating
          await AppRatingService.incrementRealmsCompleted();

          // Show certificate celebration dialog
          if (mounted) {
            _showCertificateDialog(null, realm.name);
          }
        }
      }
    } catch (e) {
      // print('Error checking/generating certificate: $e');
    }
  }

  /// Show certificate celebration dialog
  void _showCertificateDialog(dynamic certificate, String realmName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 50,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Realm Completed!',
              style: AppTextStyles.h2.copyWith(
                color: AppDesignSystem.primaryIndigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              'Congratulations! You\'ve completed the $realmName realm.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Certificate preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_membership,
                    size: 40,
                    color: AppDesignSystem.primaryIndigo,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Certificate Earned!',
                    style: AppTextStyles.h4.copyWith(
                      color: AppDesignSystem.primaryIndigo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View it in your profile',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Bonus XP
            if (_bonusXP > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+$_bonusXP Bonus XP!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamed(context, '/certificates'); // Navigate to certificates
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.primaryIndigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Certificate'),
          ),
        ],
      ),
    );
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswers = List.filled(widget.level.quiz.length, null);
      _showExplanation = false;
      _isQuizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizCompleted) {
      return _buildResultScreen();
    }

    final question = widget.level.quiz[_currentQuestionIndex];
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];
    final isAnswered = selectedAnswer != null;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('${widget.level.name} Quiz'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.level.quiz.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.level.quiz.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
            ),

            // Question and Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Text(
                        question.question,
                        style: AppTextStyles.h3,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Options
                    ...List.generate(question.options.length, (index) {
                      final isSelected = selectedAnswer == index;
                      final isCorrect = index == question.correctIndex;
                      
                      Color bgColor = Colors.white;
                      Color borderColor = AppDesignSystem.backgroundGrey;
                      IconData? icon;
                      
                      if (_showExplanation) {
                        if (isCorrect) {
                          bgColor = Colors.green.withValues(alpha: 0.1);
                          borderColor = Colors.green;
                          icon = Icons.check_circle;
                        } else if (isSelected && !isCorrect) {
                          bgColor = Colors.red.withValues(alpha: 0.1);
                          borderColor = Colors.red;
                          icon = Icons.cancel;
                        }
                      } else if (isSelected) {
                        bgColor = AppDesignSystem.primaryIndigo.withValues(alpha: 0.1);
                        borderColor = AppDesignSystem.primaryIndigo;
                      }

                      return GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              if (icon != null)
                                Icon(
                                  icon,
                                  color: borderColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Explanation (shown after answer submission)
                    if (_showExplanation) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: AppTextStyles.h4.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_showExplanation) {
                      _nextQuestion();
                    } else {
                      _submitAnswer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    _showExplanation
                        ? (_currentQuestionIndex < widget.level.quiz.length - 1
                            ? 'Next Question'
                            : 'Finish Quiz')
                        : 'Submit Answer',
                    style: AppTextStyles.buttonLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / widget.level.quiz.length) * 100;
    final passed = percentage >= 60;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Confetti
                    if (passed)
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          particleDrag: 0.05,
                          emissionFrequency: 0.05,
                          numberOfParticles: 50,
                          gravity: 0.1,
                        ),
                      ),

                    // Result Icon
                    Icon(
                      passed ? Icons.celebration : Icons.replay,
                      size: 100,
                      color: passed ? Colors.green : Colors.orange,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Result Title
                    Text(
                      passed ? 'Congratulations!' : 'Keep Trying!',
                      style: AppTextStyles.h1.copyWith(
                        color: passed ? Colors.green : Colors.orange,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Score
                    Text(
                      'You scored $_score/${widget.level.quiz.length}',
                      style: AppTextStyles.h2,
                    ),

                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.h1.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontSize: 48,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // XP Earned
                    if (passed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.level.xpReward}${_bonusXP > 0 ? ' + $_bonusXP' : ''} XP Earned!',
                              style: AppTextStyles.h3.copyWith(
                                color: AppDesignSystem.primaryIndigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Certificate notification
                    if (_certificateGenerated) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Certificate Earned!',
                                    style: AppTextStyles.h4.copyWith(
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                  Text(
                                    'Realm completed! Check your profile.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Message
                    Text(
                      passed
                          ? 'Level completed! You\'ve unlocked the next level.'
                          : 'You need 60% to pass. Review the content and try again!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Action Buttons
                    if (passed) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Back to level
                            Navigator.pop(context); // Back to realm
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignSystem.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Continue to Next Level'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppDesignSystem.primaryIndigo,
                            side: const BorderSide(color: AppDesignSystem.primaryIndigo),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Review Level'),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retakeQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignSystem.primaryIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Retake Quiz'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppDesignSystem.primaryIndigo,
                            side: const BorderSide(color: AppDesignSystem.primaryIndigo),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Review Content'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

