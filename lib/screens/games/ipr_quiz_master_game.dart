import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../widgets/primary_button.dart';

/// IPR Quiz Master - Rapid-fire 10 question quiz game
class IPRQuizMasterGame extends StatefulWidget {
  const IPRQuizMasterGame({Key? key}) : super(key: key);

  @override
  State<IPRQuizMasterGame> createState() => _IPRQuizMasterGameState();
}

class _IPRQuizMasterGameState extends State<IPRQuizMasterGame> {
  final ProgressService _progressService = ProgressService();
  
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
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final xpEarned = _score * 10;
        
        // Save to progress (XP + summary)
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_quiz_master',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: _score,
          totalQuestions: _questions.length,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_quiz_master')
            .set({
          'userId': user.uid,
          'contentId': 'game_quiz_master',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': _score,
          'accuracy': (_score / _questions.length * 100).round(),
          'attemptsCount': FieldValue.increment(1),
          'lastAttemptAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        
        // Update user's gameProgress field
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final currentGameProgress = userDoc.data()?['gameProgress'] as Map<String, dynamic>? ?? {};
        final currentScores = currentGameProgress['scores'] as Map<String, dynamic>? ?? {};
        final currentBestScore = currentScores['quiz_master'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'quiz_master': _score > currentBestScore ? _score : currentBestScore,
            },
            'lastPlayedAt': Timestamp.now(),
          },
        }, SetOptions(merge: true));
        
        print('✅ Game score saved: $_score, XP earned: $xpEarned');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('IPR Quiz Master'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.speed,
                  size: 60,
                  color: AppColors.primary,
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
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Game rules
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
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
                    _buildRuleItem('⏱️', '60 seconds to complete'),
                    _buildRuleItem('🎯', 'Answer as many as you can'),
                    _buildRuleItem('⭐', '10 XP per correct answer'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/10'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Timer
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _timeLeft <= 10 ? Colors.red : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _timeLeft <= 10 ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeLeft}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // Score display
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score: $_score',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Question
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.secondary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                      child: Text(
                        question.question,
                        style: AppTextStyles.h3,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Answer options
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedAnswer == index;
                      final isCorrect = index == question.correctIndex;
                      
                      Color bgColor = Colors.white;
                      Color borderColor = AppColors.border;
                      
                      if (_answerLocked) {
                        if (isCorrect) {
                          bgColor = AppColors.success.withOpacity(0.1);
                          borderColor = AppColors.success;
                        } else if (isSelected && !isCorrect) {
                          bgColor = Colors.red.withOpacity(0.1);
                          borderColor = Colors.red;
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
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: borderColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index), // A, B, C, D
                                    style: TextStyle(
                                      color: borderColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              if (_answerLocked && (isCorrect || (isSelected && !isCorrect)))
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: borderColor,
                                ),
                            ],
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
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _questions.length * 100).round();
    final passed = percentage >= 60;
    final xpEarned = _score * 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Game Over'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: passed ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.emoji_events : Icons.refresh,
                  size: 60,
                  color: passed ? AppColors.success : Colors.orange,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                passed ? 'Great Job!' : 'Good Try!',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You answered $_score out of ${_questions.length} questions correctly',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Score', '$_score/${_questions.length}'),
                    const Divider(height: 24),
                    _buildStatRow('Accuracy', '$percentage%'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Buttons
              PrimaryButton(
                text: 'Play Again',
                onPressed: _restartGame,
                fullWidth: true,
                icon: Icons.refresh,
              ),

              const SizedBox(height: AppSpacing.md),

              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Back to Games',
                    style: AppTextStyles.button,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
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

