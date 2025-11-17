import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
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
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  
  DailyChallengeModel? _challenge;
  ChallengeAttemptModel? _todayAttempt;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  bool _showResults = false;
  
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  int? _selectedAnswer;
  bool _answerLocked = false;
  int _correctCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

  void _selectAnswer(int index) {
    if (_answerLocked) return;
    
    setState(() {
      _selectedAnswer = index;
      _answerLocked = true;
    });

    // Check if correct
    if (index == _challenge!.questions[_currentQuestionIndex].correctAnswer) {
      _correctCount++;
    }

    // Move to next question after delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (_currentQuestionIndex < _challenge!.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswer = null;
          _answerLocked = false;
        });
      } else {
        _submitChallenge();
      }
    });
  }

  Future<void> _submitChallenge() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Submit attempt
      final attempt = await _challengeService.submitAttempt(
        userId: userId,
        challengeId: _challenge!.id,
        score: _correctCount,
      );

      setState(() {
        _todayAttempt = attempt;
        _isSubmitting = false;
        _showResults = true;
      });

      // Trigger confetti if passed
      final percentage = (_correctCount / _challenge!.questions.length * 100).round();
      if (percentage >= 60) {
        _confettiController.play();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('Daily Challenge', style: TextStyle(color: Colors.white)),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (_todayAttempt != null && !_showResults) {
      return _buildCompletedScreen();
    }

    if (_showResults) {
      return _buildResultScreen();
    }

    return _buildChallengeScreen();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Daily Challenge', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.primaryIndigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Daily Challenge', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesignSystem.success,
                      AppDesignSystem.success.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppDesignSystem.success.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle, size: 50, color: Colors.white),
              ),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeScreen() {
    final question = _challenge!.questions[_currentQuestionIndex];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDesignSystem.primaryIndigo.withValues(alpha: 0.05),
              AppDesignSystem.primaryPink.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(),
              
              // Progress bar
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _challenge!.questions.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Question Card with Gradient
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppDesignSystem.primaryIndigo,
                              AppDesignSystem.primaryPink,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Question ${_currentQuestionIndex + 1} of ${_challenge!.questions.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question.question,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Answer options with gradient
                      ...List.generate(question.options.length, (index) {
                        final isSelected = _selectedAnswer == index;
                        final isCorrect = index == question.correctAnswer;
                        final showResult = _answerLocked;
                        
                        Color? gradientStart;
                        Color? gradientEnd;
                        Color borderColor = Colors.grey[300]!;
                        Color textColor = const Color(0xFF1F2937);
                        
                        if (showResult) {
                          if (isCorrect) {
                            gradientStart = AppDesignSystem.success;
                            gradientEnd = AppDesignSystem.success.withValues(alpha: 0.8);
                            borderColor = AppDesignSystem.success;
                            textColor = Colors.white;
                          } else if (isSelected) {
                            gradientStart = AppDesignSystem.error;
                            gradientEnd = AppDesignSystem.error.withValues(alpha: 0.8);
                            borderColor = AppDesignSystem.error;
                            textColor = Colors.white;
                          }
                        } else if (isSelected) {
                          gradientStart = AppDesignSystem.primaryIndigo.withValues(alpha: 0.2);
                          gradientEnd = AppDesignSystem.primaryPink.withValues(alpha: 0.2);
                          borderColor = AppDesignSystem.primaryIndigo;
                        }

                        return GestureDetector(
                          onTap: _answerLocked ? null : () => _selectAnswer(index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: gradientStart != null
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [gradientStart, gradientEnd!],
                                    )
                                  : null,
                              color: gradientStart == null ? Colors.white : null,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (isSelected && !showResult)
                                  BoxShadow(
                                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                if (showResult && isCorrect)
                                  BoxShadow(
                                    color: AppDesignSystem.success.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: showResult && (isCorrect || isSelected)
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : borderColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (showResult && (isCorrect || isSelected))
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          
          // Title
          Text(
            'Daily Challenge',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppDesignSystem.textPrimary,
            ),
          ),
          
          // XP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${_challenge!.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_correctCount / _challenge!.questions.length * 100).round();
    final passed = percentage >= 60;
    final isPerfect = percentage == 100;
    final xpEarned = _todayAttempt!.xpEarned;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Challenge Complete', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF6366F1),
                Color(0xFFEC4899),
                Color(0xFFFBBF24),
                Color(0xFF10B981),
              ],
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  
                  // Animated Result icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: passed
                                  ? [
                                      AppDesignSystem.success,
                                      AppDesignSystem.success.withValues(alpha: 0.7),
                                    ]
                                  : [
                                      Colors.orange,
                                      Colors.orange.withValues(alpha: 0.7),
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: passed 
                                    ? AppDesignSystem.success.withValues(alpha: 0.4)
                                    : Colors.orange.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            passed ? Icons.emoji_events : Icons.refresh,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    passed 
                        ? (isPerfect ? 'Perfect Score!' : 'Great Job!') 
                        : 'Good Try!',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppDesignSystem.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    passed
                        ? 'You completed today\'s challenge!'
                        : 'Come back tomorrow for another chance!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Stats Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('Score', '$_correctCount/${_challenge!.questions.length}'),
                        const Divider(height: 24),
                        _buildStatRow('Accuracy', '$percentage%'),
                        const Divider(height: 24),
                        _buildStatRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.primaryIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppDesignSystem.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppDesignSystem.primaryIndigo : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }
}