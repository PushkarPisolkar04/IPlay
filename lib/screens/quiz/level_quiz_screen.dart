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

    // Play selection sound
    SoundService.playButtonClick();
    
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
      // Play celebration sound
      SoundService.playSuccess();

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
      body: SafeArea(
        child: Column(
          children: [
            // Gradient App Bar
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1), // Indigo
                    Color(0xFF8B5CF6), // Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.level.name} Quiz',
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentQuestionIndex + 1}/${widget.level.quiz.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            // Progress bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.level.quiz.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
              minHeight: 4,
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
                      Color borderColor = Colors.grey.shade300;
                      IconData? icon;
                      Color? iconColor;
                      
                      if (_showExplanation) {
                        if (isCorrect) {
                          bgColor = AppDesignSystem.success.withValues(alpha: 0.15);
                          borderColor = AppDesignSystem.success;
                          icon = Icons.check_circle_rounded;
                          iconColor = AppDesignSystem.success;
                        } else if (isSelected && !isCorrect) {
                          bgColor = AppDesignSystem.error.withValues(alpha: 0.15);
                          borderColor = AppDesignSystem.error;
                          icon = Icons.cancel_rounded;
                          iconColor = AppDesignSystem.error;
                        }
                      } else if (isSelected) {
                        bgColor = AppDesignSystem.primaryIndigo.withValues(alpha: 0.15);
                        borderColor = AppDesignSystem.primaryIndigo;
                        icon = Icons.radio_button_checked;
                        iconColor = AppDesignSystem.primaryIndigo;
                      } else {
                        icon = Icons.radio_button_unchecked;
                        iconColor = Colors.grey.shade400;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectAnswer(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected && !_showExplanation ? [
                                  BoxShadow(
                                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: Row(
                                children: [
                                  if (icon != null)
                                    Icon(
                                      icon,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
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

                    // XP Earned with animation
                    if (passed) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3 * value),
                                    blurRadius: 20 * value,
                                    spreadRadius: 5 * value,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    builder: (context, rotateValue, child) {
                                      return Transform.rotate(
                                        angle: rotateValue * 2 * 3.14159,
                                        child: const Icon(Icons.star, color: Colors.amber, size: 28),
                                      );
                                    },
                                  ),
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
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Certificate notification with animation
                    if (_certificateGenerated) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.bounceOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3 * value),
                                    blurRadius: 15 * value,
                                    spreadRadius: 3 * value,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    builder: (context, pulseValue, child) {
                                      return Transform.scale(
                                        scale: 1.0 + (0.2 * pulseValue),
                                        child: const Icon(
                                          Icons.workspace_premium,
                                          color: Colors.amber,
                                          size: 32,
                                        ),
                                      );
                                    },
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
                          );
                        },
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
                            Navigator.pop(context, true); // Back to level with result
                            Navigator.pop(context, true); // Back to realm with result
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
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppDesignSystem.primaryIndigo, width: 2),
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
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppDesignSystem.primaryIndigo, width: 2),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Review Content'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
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

