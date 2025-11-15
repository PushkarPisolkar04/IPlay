import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/daily_challenge_service.dart';
import '../../core/models/daily_challenge_model.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final DailyChallengeService _challengeService = DailyChallengeService();
  
  DailyChallengeModel? _challenge;
  ChallengeAttemptModel? _todayAttempt;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  
  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Get today's challenge
      _challenge = await _challengeService.getTodaysChallenge();
      
      if (_challenge == null) {
        setState(() {
          _error = 'No daily challenge available today. Check back tomorrow!';
          _isLoading = false;
        });
        return;
      }

      // Check if already attempted
      final todayChallenge = await _challengeService.getTodaysChallenge();
      if (todayChallenge != null) {
        _todayAttempt = await _challengeService.getUserAttempt(
          userId: userId,
          challengeId: todayChallenge.id,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitChallenge() async {
    if (_selectedAnswers.length != _challenge!.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Calculate score
      int correctCount = 0;
      for (int i = 0; i < _challenge!.questions.length; i++) {
        if (_selectedAnswers[i] == _challenge!.questions[i].correctAnswer) {
          correctCount++;
        }
      }

      // Submit attempt
      final attempt = await _challengeService.submitAttempt(
        userId: userId,
        challengeId: _challenge!.id,
        score: correctCount,
      );

      setState(() {
        _todayAttempt = attempt;
        _isSubmitting = false;
      });

      // Show results dialog
      _showResultsDialog(correctCount, attempt.xpEarned);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting: $e')),
      );
    }
  }

  void _showResultsDialog(int score, int xpEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Challenge Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score/${_challenge!.questions.length}',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'XP Earned: +$xpEarned',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppDesignSystem.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Come back tomorrow for a new challenge!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _todayAttempt != null
                  ? _buildCompletedState()
                  : _buildChallengeState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadChallenge,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: AppDesignSystem.success),
            const SizedBox(height: 24),
            Text(
              'Challenge Complete!',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${_todayAttempt!.score}/5',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 8),
            Text(
              'XP Earned: +${_todayAttempt!.xpEarned}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppDesignSystem.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Come back tomorrow for a new challenge!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeState() {
    final question = _challenge!.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _challenge!.questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppDesignSystem.backgroundWhite,
          valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_challenge!.questions.length}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_challenge!.xpReward} XP',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.primaryIndigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Question
                Text(
                  question.question,
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 32),

                // Options
                ...List.generate(question.options.length, (index) {
                  final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _OptionCard(
                      option: question.options[index],
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedAnswers[_currentQuestionIndex] == null
                      ? null
                      : () {
                          if (_currentQuestionIndex < _challenge!.questions.length - 1) {
                            setState(() => _currentQuestionIndex++);
                          } else {
                            _submitChallenge();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.primaryIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_currentQuestionIndex < _challenge!.questions.length - 1
                          ? 'Next'
                          : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.1) : AppDesignSystem.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppDesignSystem.primaryIndigo : AppDesignSystem.backgroundWhite,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppDesignSystem.primaryIndigo : AppDesignSystem.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppDesignSystem.textPrimary : AppDesignSystem.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

