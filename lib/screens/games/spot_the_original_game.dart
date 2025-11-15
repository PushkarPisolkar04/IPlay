import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../services/app_rating_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/primary_button.dart';

/// Spot the Original - Identify the original work among copies
class SpotTheOriginalGame extends StatefulWidget {
  const SpotTheOriginalGame({super.key});

  @override
  State<SpotTheOriginalGame> createState() => _SpotTheOriginalGameState();
}

class _SpotTheOriginalGameState extends State<SpotTheOriginalGame> {
  final ProgressService _progressService = ProgressService();
  
  int _currentRound = 0;
  int _score = 0;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _answerLocked = false;
  int? _selectedAnswer;
  List<GameRound> _rounds = [];

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  Future<void> _loadRounds() async {
    // Load from JSON file
    try {
      final String jsonString = await rootBundle.loadString('content/games/spot_the_original.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> productSets = jsonData['productSets'] ?? [];
      
      // Shuffle and select 5 random products
      productSets.shuffle(Random());
      final selectedProducts = productSets.take(5).toList();
      
      setState(() {
        _rounds = selectedProducts.map((product) {
          final images = product['images'] as List<dynamic>;
          return GameRound(
            type: product['productName'] as String,
            question: 'Which is the original ${product['productName']}?',
            options: images.map((img) => ImageOption(
              icon: Icons.image,
              label: img['label'] as String,
              imagePath: img['url'] as String,
            )).toList(),
            correctIndex: images.indexWhere((img) => img['isOriginal'] == true),
            explanation: product['educationalInfo']['identificationTips'][0] as String,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading game data: $e');
      // Fallback to empty rounds
      setState(() {
        _rounds = [];
      });
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentRound = 0;
      _score = 0;
    });
  }

  void _selectAnswer(int index) {
    if (_answerLocked || _gameEnded) return;
    
    setState(() {
      _selectedAnswer = index;
      _answerLocked = true;
    });

    // Check if correct
    if (index == _rounds[_currentRound].correctIndex) {
      setState(() {
        _score++;
      });
      // Haptic feedback for correct answer
      HapticFeedbackUtil.correctAnswer();
    } else {
      // Haptic feedback for incorrect answer
      HapticFeedbackUtil.incorrectAnswer();
    }

    // Move to next round after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentRound < _rounds.length - 1) {
        setState(() {
          _currentRound++;
          _selectedAnswer = null;
          _answerLocked = false;
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    setState(() {
      _gameEnded = true;
    });
    // Haptic feedback for XP gain
    HapticFeedbackUtil.xpGain();
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final xpEarned = _score * 15;
        
        // Save to progress
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_spot_original',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: _score,
          totalQuestions: _rounds.length,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_spot_original')
            .set({
          'userId': user.uid,
          'contentId': 'game_spot_original',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': _score,
          'accuracy': (_score / _rounds.length * 100).round(),
          'attemptsCount': FieldValue.increment(1),
          'lastAttemptAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        
        // Update user's gameProgress
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final currentGameProgress = userDoc.data()?['gameProgress'] as Map<String, dynamic>? ?? {};
        final currentScores = currentGameProgress['scores'] as Map<String, dynamic>? ?? {};
        final currentBestScore = currentScores['spot_original'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'spot_original': _score > currentBestScore ? _score : currentBestScore,
            },
            'lastPlayedAt': Timestamp.now(),
          },
        }, SetOptions(merge: true));
        
        // print('✅ Game score saved: $_score, XP earned: $xpEarned');
        
        // Track game completion for app rating
        await AppRatingService.incrementGamesPlayed();
      } catch (e) {
        // print('❌ Error saving game score: $e');
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _currentRound = 0;
      _score = 0;
      _selectedAnswer = null;
      _answerLocked = false;
    });
    _loadRounds();
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
        title: const Text('Spot the Original'),
        backgroundColor: AppDesignSystem.primaryPink,
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
                  color: AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  size: 60,
                  color: AppDesignSystem.primaryPink,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Spot the Original',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Can you identify the original work among copies and fakes?',
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
                    _buildRuleItem('🎨', '5 rounds with different brands'),
                    _buildRuleItem('🖼️', '2 images per round (1 original, 1 fake)'),
                    _buildRuleItem('🎯', 'Identify the original product'),
                    _buildRuleItem('⭐', '15 XP per correct answer (max 75 XP)'),
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
    final round = _rounds[_currentRound];
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('Round ${_currentRound + 1}/5'),
        backgroundColor: AppDesignSystem.primaryPink,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentRound + 1) / _rounds.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryPink),
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
                        color: AppDesignSystem.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppDesignSystem.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Score: $_score',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppDesignSystem.success,
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
                            AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                            AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                      child: Column(
                        children: [
                          Text(
                            round.question,
                            style: AppTextStyles.h3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Type: ${round.type}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Image options in 1 row with 2 columns
                    Row(
                      children: List.generate(round.options.length, (index) {
                        final isSelected = _selectedAnswer == index;
                        final isCorrect = index == round.correctIndex;
                        
                        Color borderColor = AppDesignSystem.backgroundGrey;
                        double borderWidth = 2;
                        
                        if (_answerLocked) {
                          if (isCorrect) {
                            borderColor = AppDesignSystem.success;
                            borderWidth = 4;
                          } else if (isSelected && !isCorrect) {
                            borderColor = Colors.red;
                            borderWidth = 4;
                          }
                        } else if (isSelected) {
                          borderColor = AppDesignSystem.primaryPink;
                          borderWidth = 3;
                        }

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : AppSpacing.sm,
                              right: index == round.options.length - 1 ? 0 : AppSpacing.sm,
                            ),
                            child: GestureDetector(
                              onTap: () => _selectAnswer(index),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: borderColor,
                                    width: borderWidth,
                                  ),
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                ),
                                child: Stack(
                                  children: [
                                    // Image - Full size
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 2),
                                      child: Image.asset(
                                        round.options[index].imagePath,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading image: ${round.options[index].imagePath}');
                                          return Container(
                                            color: AppDesignSystem.backgroundGrey,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_not_supported,
                                                  size: 64,
                                                  color: AppDesignSystem.textSecondary,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Image not found',
                                                  style: AppTextStyles.bodySmall,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Result indicator
                                    if (_answerLocked && (isCorrect || (isSelected && !isCorrect)))
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isCorrect ? AppDesignSystem.success : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCorrect ? Icons.check : Icons.close,
                                            color: Colors.white,
                                            size: 24,
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
                    ),

                    if (_answerLocked) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _selectedAnswer == round.correctIndex
                              ? AppDesignSystem.success.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Text(
                          round.explanation,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
    final percentage = (_score / _rounds.length * 100).round();
    final passed = percentage >= 60;
    final xpEarned = _score * 15;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over'),
        backgroundColor: AppDesignSystem.primaryPink,
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
                  color: passed ? AppDesignSystem.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.emoji_events : Icons.refresh,
                  size: 60,
                  color: passed ? AppDesignSystem.success : Colors.orange,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                passed ? 'Great Job!' : 'Good Try!',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You identified $_score out of ${_rounds.length} originals correctly',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Score', '$_score/${_rounds.length}'),
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
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
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
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: isHighlight ? AppDesignSystem.primaryPink : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }

}

class GameRound {
  final String type;
  final String question;
  final List<ImageOption> options;
  final int correctIndex;
  final String explanation;

  GameRound({
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class ImageOption {
  final IconData icon;
  final String label;
  final String imagePath;

  ImageOption({
    required this.icon,
    required this.label,
    required this.imagePath,
  });
}
