  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:confetti/confetti.dart';
  import 'dart:async';
  import 'dart:math';
  import '../../core/design/app_design_system.dart';
  import '../../core/constants/app_spacing.dart';
  import '../../core/constants/app_text_styles.dart';
  import '../../services/game_integration_service.dart';
  import '../../widgets/primary_button.dart';

  /// IPR Quiz Master - Rapid-fire 10 question quiz game
  class IPRQuizMasterGame extends StatefulWidget {
    const IPRQuizMasterGame({super.key});

    @override
    State<IPRQuizMasterGame> createState() => _IPRQuizMasterGameState();
  }

  class _IPRQuizMasterGameState extends State<IPRQuizMasterGame> {
    final GameIntegrationService _gameService = GameIntegrationService();
    final ConfettiController _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    int _currentQuestionIndex = 0;
    int _score = 0;
    int _timeLeft = 60; // 60 seconds total
    Timer? _timer;
    bool _gameStarted = false;
    bool _gameEnded = false;
    List<QuizQuestion> _questions = [];
    int? _selectedAnswer;
    bool _answerLocked = false;

    @override
    void initState() {
      super.initState();
      _loadQuestions();
    }

    @override
    void dispose() {
      _timer?.cancel();
      _confettiController.dispose();
      super.dispose();
    }

    void _loadQuestions() {
      // Load 10 random IPR questions
      _questions = _getRandomQuestions(10);
    }

    void _startGame() {
      setState(() {
        _gameStarted = true;
        _currentQuestionIndex = 0;
        _score = 0;
        _timeLeft = 60;
      });
      _startTimer();
    }

    void _startTimer() {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
          });
        } else {
          _endGame();
        }
      });
    }

    void _selectAnswer(int index) {
      if (_answerLocked || _gameEnded) return;
      
      setState(() {
        _selectedAnswer = index;
        _answerLocked = true;
      });

      // Check if correct
      if (index == _questions[_currentQuestionIndex].correctIndex) {
        setState(() {
          _score++;
        });

      } else {

      }

      // Move to next question after brief delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_currentQuestionIndex < _questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _selectedAnswer = null;
            _answerLocked = false;
          });
        } else {
          _endGame();
        }
      });
    }

    void _endGame() {
      _timer?.cancel();
      
      setState(() {
        _gameEnded = true;
      });
      
      // Trigger confetti if passed
      final percentage = (_score / _questions.length * 100).round();
      if (percentage >= 60) {
        _confettiController.play();
      }
      
      _saveScore();
    }

    Future<void> _saveScore() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          const gameId = 'quiz_master';
          const baseXP = 100; // 10 XP per question * 10 questions
          
          final isFirstCompletion = await _gameService.isFirstCompletion(gameId);
          final isPerfectScore = _score == 10;
          
          // Award XP with automatic bonuses
          await _gameService.awardGameXP(
            gameId: gameId,
            baseXP: baseXP,
            score: (_score / 10 * 100).round(),
            isPerfectScore: isPerfectScore,
            isFirstCompletion: isFirstCompletion,
          );
          
          // Save progress
          await _gameService.saveGameProgress(
            gameId: gameId,
            score: _score,
            timeSpentSeconds: 60 - _timeLeft,
            completed: true,
          );
          
          print('✅ Game score saved: $_score');
        } catch (e) {
          print('❌ Error saving game score: $e');
        }
      }
    }

    void _restartGame() {
      setState(() {
        _gameEnded = false;
        _gameStarted = false;
        _currentQuestionIndex = 0;
        _score = 0;
        _timeLeft = 60;
        _selectedAnswer = null;
        _answerLocked = false;
      });
      _loadQuestions();
    }

    @override
    Widget build(BuildContext context) {
      if (!_gameStarted) {
        return _buildStartScreen();
      }

      if (_gameEnded) {
        return _buildResultScreen();
      }

      return _buildGameScreen();
    }

    Widget _buildStartScreen() {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('IPR Quiz Master', style: TextStyle(color: Colors.white)),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game logo
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/logos/IPR_quiz_master.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.speed,
                        size: 60,
                        color: AppDesignSystem.primaryIndigo,
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  'IPR Quiz Master',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  'Test your IPR knowledge in a rapid-fire quiz!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Game rules
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Rules:',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRuleItem('⚡', '10 rapid-fire questions'),
                      _buildRuleItem('⏱️', '60 seconds total time'),
                      _buildRuleItem('🎯', 'Answer as many as you can'),
                      _buildRuleItem('⭐', 'Score based on correct answers'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Start button
                PrimaryButton(
                  text: 'Start Game',
                  onPressed: _startGame,
                  fullWidth: true,
                  icon: Icons.play_arrow,
                  color: AppDesignSystem.primaryIndigo,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildGameScreen() {
      final question = _questions[_currentQuestionIndex];
      
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
                // Top Stats Bar (matching Trademark Match style)
                _buildTopBar(),
                
                // Progress bar
                Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppDesignSystem.primaryIndigo,
                      ),
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
                                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
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
                          final isCorrect = index == question.correctIndex;
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
      final timeColor = _timeLeft <= 10 ? Colors.red : AppDesignSystem.primaryIndigo;
      
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
            
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [timeColor, timeColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: timeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${_timeLeft}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                    '$_score/${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
      final percentage = (_score / _questions.length * 100).round();
      final passed = percentage >= 60;
      final isPerfect = percentage == 100;
      final xpEarned = _score * 10;

      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('Game Over', style: TextStyle(color: Colors.white)),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    
                    // Animated Result icon with gradient
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

                    // Animated Title
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Column(
                              children: [
                                Text(
                                  passed 
                                      ? (isPerfect ? 'Perfect Score!' : 'Great Job!') 
                                      : 'Good Try!',
                                  style: AppTextStyles.h1.copyWith(
                                    color: passed ? AppDesignSystem.success : Colors.orange,
                                    fontSize: 28,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    '$_score/${_questions.length} correct',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppDesignSystem.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Animated Stats Card
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                                    AppDesignSystem.primaryPink.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildFancyStatRow(
                                      Icons.check_circle,
                                      'Score',
                                      '$_score/${_questions.length}',
                                      AppDesignSystem.success,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFancyStatRow(
                                      Icons.speed,
                                      'Accuracy',
                                      '$percentage%',
                                      AppDesignSystem.primaryIndigo,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFancyStatRow(
                                      Icons.military_tech,
                                      'XP Earned',
                                      '+$xpEarned XP',
                                      AppDesignSystem.primaryPink,
                                      isHighlight: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // Animated Buttons
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Column(
                            children: [
                              PrimaryButton(
                                text: 'Play Again',
                                onPressed: _restartGame,
                                fullWidth: true,
                                icon: Icons.refresh,
                                color: AppDesignSystem.primaryIndigo,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppDesignSystem.primaryIndigo, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Back to Games',
                                    style: TextStyle(color: AppDesignSystem.primaryIndigo),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            
            // Confetti overlay
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
          ],
        ),
      );
    }

    Widget _buildFancyStatRow(IconData icon, String label, String value, Color color, {bool isHighlight = false}) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: isHighlight ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? color : AppDesignSystem.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget _buildRuleItem(String emoji, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(text, style: AppTextStyles.bodyMedium),
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppDesignSystem.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppDesignSystem.primaryIndigo : AppDesignSystem.textPrimary,
            ),
          ),
        ],
      );
    }

    // Sample questions for the game
    List<QuizQuestion> _getRandomQuestions(int count) {
      final allQuestions = [
        QuizQuestion(
          question: 'What does IPR stand for?',
          options: ['Intellectual Property Rights', 'Internal Process Review', 'International Patent Registry', 'Innovative Product Research'],
          correctIndex: 0,
        ),
        QuizQuestion(
          question: 'How long does copyright protection typically last?',
          options: ['20 years', '50 years', 'Lifetime + 60 years', '10 years'],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'Which IPR protects brand names and logos?',
          options: ['Patent', 'Copyright', 'Trademark', 'Trade Secret'],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'What is a patent used for?',
          options: ['Protecting inventions', 'Protecting books', 'Protecting songs', 'Protecting brand names'],
          correctIndex: 0,
        ),
        QuizQuestion(
          question: 'Fair use allows limited use of copyrighted material for:',
          options: ['Commercial sale', 'Education & research', 'Unlimited copying', 'Business profit'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'Design rights protect:',
          options: ['Inventions', 'Visual appearance', 'Trade secrets', 'Processes'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'GI stands for:',
          options: ['General Information', 'Geographical Indication', 'Global Innovation', 'Government Intellectual'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'What is copyright infringement?',
          options: ['Unauthorized use', 'Fair use', 'Public domain', 'Licensed use'],
          correctIndex: 0,
        ),
        QuizQuestion(
          question: 'Trade secrets must be:',
          options: ['Publicly disclosed', 'Registered', 'Kept confidential', 'Expired'],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'Patent protection typically lasts:',
          options: ['10 years', '20 years', '50 years', 'Lifetime'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'Which is protected by copyright?',
          options: ['Inventions', 'Logos', 'Books & music', 'Recipes'],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'Trademark symbols include:',
          options: ['©', '™ and ®', '℗', 'All of these'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'What does prior art mean?',
          options: ['Ancient artwork', 'Existing knowledge', 'New invention', 'Copyright'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'Industrial design protects:',
          options: ['Functional features', 'Aesthetic features', 'Chemical formulas', 'Software code'],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'Public domain means:',
          options: ['Still protected', 'No longer protected', 'Secret', 'Trademarked'],
          correctIndex: 1,
        ),
      ];

      // Shuffle and return requested count
      allQuestions.shuffle(Random());
      return allQuestions.take(count).toList();
    }
  }

  class QuizQuestion {
    final String question;
    final List<String> options;
    final int correctIndex;

    QuizQuestion({
      required this.question,
      required this.options,
      required this.correctIndex,
    });
  }

