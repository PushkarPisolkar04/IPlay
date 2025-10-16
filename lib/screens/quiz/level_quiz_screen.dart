import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/realm_model.dart';
import '../../core/services/progress_service.dart';
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
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  int _currentQuestionIndex = 0;
  int _score = 0;
  List<int?> _selectedAnswers = [];
  bool _showExplanation = false;
  bool _isQuizCompleted = false;

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
        } catch (e) {
          print('Error saving progress: $e');
        }
      }
    }

    setState(() {
      _isQuizCompleted = true;
    });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.level.name} Quiz'),
        backgroundColor: AppColors.primary,
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                        color: AppColors.primary.withOpacity(0.1),
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
                      Color borderColor = AppColors.border;
                      IconData? icon;
                      
                      if (_showExplanation) {
                        if (isCorrect) {
                          bgColor = Colors.green.withOpacity(0.1);
                          borderColor = Colors.green;
                          icon = Icons.check_circle;
                        } else if (isSelected && !isCorrect) {
                          bgColor = Colors.red.withOpacity(0.1);
                          borderColor = Colors.red;
                          icon = Icons.cancel;
                        }
                      } else if (isSelected) {
                        bgColor = AppColors.primary.withOpacity(0.1);
                        borderColor = AppColors.primary;
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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                    backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.background,
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
                        color: AppColors.primary,
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.level.xpReward} XP Earned!',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
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
                        color: AppColors.textSecondary,
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
                            backgroundColor: AppColors.primary,
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
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
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
                            backgroundColor: AppColors.primary,
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
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
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

