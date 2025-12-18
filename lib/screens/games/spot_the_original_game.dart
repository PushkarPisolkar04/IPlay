import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/app_rating_service.dart';
import '../../services/game_integration_service.dart';
import '../../widgets/primary_button.dart';

/// Spot the Original - Identify the original work among copies
class SpotTheOriginalGame extends StatefulWidget {
  const SpotTheOriginalGame({super.key});

  @override
  State<SpotTheOriginalGame> createState() => _SpotTheOriginalGameState();
}

class _SpotTheOriginalGameState extends State<SpotTheOriginalGame>
    with TickerProviderStateMixin {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  final GameIntegrationService _gameService = GameIntegrationService();

  int _currentRound = 0;
  int _score = 0;
  int _timeRemaining = 120; // 2 minutes
  int _earnedXP = 0;
  Timer? _timer;
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

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRounds() async {
    // Load from JSON file
    try {
      final String jsonString = await rootBundle.loadString(
        'content/games/spot_the_original.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> productSets = jsonData['productSets'] ?? [];

      // Shuffle and select 10 random products
      productSets.shuffle(Random());
      final selectedProducts = productSets.take(10).toList();

      setState(() {
        _rounds = selectedProducts.map((product) {
          final images = product['images'] as List<dynamic>;
          final imageOptions = images
              .map(
                (img) => ImageOption(
                  icon: Icons.image,
                  label: img['label'] as String,
                  imagePath: img['url'] as String,
                ),
              )
              .toList();

          // Find correct index before shuffling
          final correctIndex = images.indexWhere(
            (img) => img['isOriginal'] == true,
          );

          // Shuffle the options to randomize position
          final shuffledOptions = List<ImageOption>.from(imageOptions);
          shuffledOptions.shuffle(Random());

          // Find new correct index after shuffle
          final newCorrectIndex = shuffledOptions.indexWhere(
            (option) =>
                option.imagePath == imageOptions[correctIndex].imagePath,
          );

          return GameRound(
            type: product['productName'] as String,
            question: 'Which is the original ${product['productName']}?',
            options: shuffledOptions,
            correctIndex: newCorrectIndex,
            explanation:
                product['educationalInfo']['identificationTips'][0] as String,
          );
        }).toList();
      });
    } catch (e) {
      // Error loading game data
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
      _timeRemaining = 120;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
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
    if (index == _rounds[_currentRound].correctIndex) {
      setState(() {
        _score++;
      });
    } else {}

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
    _timer?.cancel();

    setState(() {
      _gameEnded = true;
    });

    // Trigger confetti if passed
    final percentage = (_score / _rounds.length * 100).round();
    if (percentage >= 60) {
      _confettiController.play();
    }

    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        const gameId = 'spot_original';
        const baseXP = 150; // 15 XP per round * 10 rounds

        final isFirstCompletion = await _gameService.isFirstCompletion(gameId);
        final isPerfectScore = _score == 10;

        // Award XP with automatic bonuses and check for badges
        final result = await _gameService.awardGameXP(
          gameId: gameId,
          baseXP: baseXP,
          score: (_score / 10 * 100).round(),
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );

        final xpEarned = result['xp'] as int;
        final newBadges = result['newBadges'] as List<String>;

        // Show badge animations if any badges were unlocked
        if (newBadges.isNotEmpty && mounted) {
          await _gameService.showBadgeAnimations(context, newBadges);
        }

        // Store XP for result screen
        setState(() {
          _earnedXP = xpEarned;
        });

        // Save progress
        await _gameService.saveGameProgress(
          gameId: gameId,
          score: _score,
          timeSpentSeconds: 120 - _timeRemaining,
          completed: true,
        );

        // Track game completion for app rating
        await AppRatingService.incrementGamesPlayed();
      } catch (e) {
        // Error saving game score
      }
    }
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _currentRound = 0;
      _score = 0;
      _timeRemaining = 120;
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
        title: const Text(
          'Spot the Original',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF59E0B),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/logos/spot_the_original.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.search,
                      size: 60,
                      color: AppDesignSystem.primaryPink,
                    );
                  },
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
                    Text('Game Rules:', style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleItem('🎯', '10 rounds with different brands'),
                    _buildRuleItem('⏱️', '2 minutes to complete'),
                    _buildRuleItem(
                      '🖼️',
                      '2 images per round (1 original, 1 fake)',
                    ),
                    _buildRuleItem('⭐', '15 XP per correct answer'),
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
                color: const Color(0xFFF59E0B),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.05),
              const Color(0xFFFBBF24).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Stats Bar (matching Quiz Master style)
              _buildTopBar(),

              // Progress bar
              Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (_currentRound + 1) / _rounds.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF59E0B),
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
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Round ${_currentRound + 1} of ${_rounds.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              round.question,
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

                      // ONLY THIS PART WAS FIXED (syntax only)
                      Row(
                        children: List.generate(round.options.length, (index) {
                          final isSelected = _selectedAnswer == index;
                          final isCorrect = index == round.correctIndex;
                          final showResult = _answerLocked;

                          Color? gradientStart;
                          Color? gradientEnd;
                          Color borderColor = Colors.grey[300]!;
                          double borderWidth = 2;

                          if (showResult) {
                            if (isCorrect) {
                              gradientStart = AppDesignSystem.success;
                              gradientEnd = AppDesignSystem.success.withValues(
                                alpha: 0.8,
                              );
                              borderColor = AppDesignSystem.success;
                              borderWidth = 4;
                            } else if (isSelected) {
                              gradientStart = AppDesignSystem.error;
                              gradientEnd = AppDesignSystem.error.withValues(
                                alpha: 0.8,
                              );
                              borderColor = AppDesignSystem.error;
                              borderWidth = 4;
                            }
                          } else if (isSelected) {
                            borderColor = const Color(0xFFF59E0B);
                            borderWidth = 3;
                          }

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 0 : 6,
                                right: index == round.options.length - 1
                                    ? 0
                                    : 6,
                              ),
                              child: GestureDetector(
                                onTap: _answerLocked
                                    ? null
                                    : () => _selectAnswer(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 300,
                                  decoration: BoxDecoration(
                                    gradient: gradientStart != null
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              gradientStart,
                                              gradientEnd!,
                                            ],
                                          )
                                        : null,
                                    border: Border.all(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      if (isSelected && !showResult)
                                        BoxShadow(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      if (showResult && isCorrect)
                                        BoxShadow(
                                          color: AppDesignSystem.success
                                              .withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Image with white background
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              round.options[index].imagePath,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 48,
                                                            color: Colors
                                                                .grey[400],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Image not found',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Gradient overlay for result
                                      if (showResult && gradientStart != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  gradientStart.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  gradientEnd!.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Result indicator with animation
                                      if (showResult &&
                                          (isCorrect || isSelected))
                                        Center(
                                          child: TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            curve: Curves.elasticOut,
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    isCorrect
                                                        ? Icons.check
                                                        : Icons.close,
                                                    color: isCorrect
                                                        ? AppDesignSystem
                                                              .success
                                                        : AppDesignSystem.error,
                                                    size: 48,
                                                  ),
                                                ),
                                              );
                                            },
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
      ),
    );
  }

  // ... rest of the file (TopBar, ResultScreen, etc.) is 100% unchanged ...
  // (kept exactly as you originally posted – including every single line, emoji, comment, etc.)

  Widget _buildTopBar() {
    final timeColor = _timeRemaining <= 20
        ? Colors.red
        : const Color(0xFFF59E0B);

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
            color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
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
                  const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  const Color(0xFFFBBF24).withValues(alpha: 0.1),
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
                  '${_timeRemaining}s',
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
                  '$_score/${_rounds.length}',
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
    final percentage = (_score / _rounds.length * 100).round();
    final passed = percentage >= 60;
    final isPerfect = percentage == 100;
    final xpEarned = _earnedXP;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFF59E0B),
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
                                      AppDesignSystem.success.withValues(
                                        alpha: 0.7,
                                      ),
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
                                    ? AppDesignSystem.success.withValues(
                                        alpha: 0.4,
                                      )
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
                                    ? (isPerfect
                                          ? 'Perfect Score!'
                                          : 'Great Job!')
                                    : 'Good Try!',
                                style: AppTextStyles.h1.copyWith(
                                  color: passed
                                      ? AppDesignSystem.success
                                      : Colors.orange,
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  '$_score/${_rounds.length} correct',
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
                                  const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.2),
                                  const Color(
                                    0xFFEC4899,
                                  ).withValues(alpha: 0.2),
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
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.1),
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
                                    '$_score/${_rounds.length}',
                                    AppDesignSystem.success,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.speed,
                                    'Accuracy',
                                    '$percentage%',
                                    const Color(0xFFF59E0B),
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
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFF59E0B),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Back to Games',
                                  style: TextStyle(color: Color(0xFFF59E0B)),
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

  Widget _buildFancyStatRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isHighlight = false,
  }) {
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
