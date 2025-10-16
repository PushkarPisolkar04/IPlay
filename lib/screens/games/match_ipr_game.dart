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

/// Match the IPR - Memory card matching game
class MatchIPRGame extends StatefulWidget {
  const MatchIPRGame({Key? key}) : super(key: key);

  @override
  State<MatchIPRGame> createState() => _MatchIPRGameState();
}

class _MatchIPRGameState extends State<MatchIPRGame> {
  final ProgressService _progressService = ProgressService();
  
  List<CardItem> _cards = [];
  List<int> _flippedIndices = [];
  int? _firstFlippedIndex;
  int _matchesFound = 0;
  int _moves = 0;
  int _timeElapsed = 0;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeCards() {
    // Create pairs of IPR concepts
    final pairs = [
      CardPair('Copyright', '©'),
      CardPair('Trademark', '™'),
      CardPair('Patent', '⚙️'),
      CardPair('Design', '🎨'),
      CardPair('GI', '🌍'),
      CardPair('Trade Secret', '🔒'),
    ];

    _cards = [];
    for (var pair in pairs) {
      _cards.add(CardItem(id: pair.id, content: pair.text, type: CardType.text));
      _cards.add(CardItem(id: pair.id, content: pair.symbol, type: CardType.symbol));
    }

    _cards.shuffle(Random());
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _matchesFound = 0;
      _moves = 0;
      _timeElapsed = 0;
      _flippedIndices = [];
      _firstFlippedIndex = null;
    });
    _initializeCards();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _flipCard(int index) {
    if (_isChecking || _flippedIndices.contains(index) || _gameEnded) return;

    setState(() {
      _flippedIndices.add(index);
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _moves++;
      _isChecking = true;
      
      final firstCard = _cards[_firstFlippedIndex!];
      final secondCard = _cards[index];

      if (firstCard.id == secondCard.id) {
        // Match found!
        setState(() {
          _matchesFound++;
        });

        if (_matchesFound == 6) {
          _endGame();
        }

        _firstFlippedIndex = null;
        _isChecking = false;
      } else {
        // No match - flip back after delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _flippedIndices.remove(_firstFlippedIndex);
              _flippedIndices.remove(index);
              _firstFlippedIndex = null;
              _isChecking = false;
            });
          }
        });
      }
    }
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
        // Calculate XP and score
        int xpEarned = 60;
        if (_timeElapsed < 60) xpEarned += 20;
        if (_moves <= 15) xpEarned += 20;
        
        // Calculate score (lower time + fewer moves = higher score)
        final score = (1000 - (_timeElapsed * 5) - (_moves * 10)).clamp(0, 1000);
        
        // Save to progress (XP + summary)
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_match_ipr',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: 100,
          totalQuestions: 1,
        );
        
        // Save detailed game history
        final docRef = FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_match_ipr');
        
        final existingDoc = await docRef.get();
        final currentHighScore = existingDoc.data()?['highScore'] ?? 0;
        
        await docRef.set({
          'userId': user.uid,
          'contentId': 'game_match_ipr',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': score > currentHighScore ? score : currentHighScore,
          'lastScore': score,
          'lastTime': _timeElapsed,
          'lastMoves': _moves,
          'attemptsCount': FieldValue.increment(1),
          'timeSpentSeconds': _timeElapsed,
          'lastAttemptAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, SetOptions(merge: true) as SetOptions);
      } catch (e) {
        print('Error saving game score: $e');
      }
    }
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _matchesFound = 0;
      _moves = 0;
      _timeElapsed = 0;
      _flippedIndices = [];
      _firstFlippedIndex = null;
      _isChecking = false;
    });
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
        title: const Text('Match the IPR'),
        backgroundColor: AppColors.secondary,
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
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_4x4,
                  size: 60,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Match the IPR',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Test your memory by matching IPR concepts!',
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
                      'How to Play:',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleItem('🃏', 'Flip cards to find pairs'),
                    _buildRuleItem('🎯', 'Match concepts with symbols'),
                    _buildRuleItem('⏱️', 'Complete as fast as you can'),
                    _buildRuleItem('⭐', 'Earn bonus XP for speed'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match the IPR'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.backgroundGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.timer, '$_timeElapsed s'),
                  _buildStatItem(Icons.touch_app, '$_moves moves'),
                  _buildStatItem(Icons.check_circle, '$_matchesFound/6 matches'),
                ],
              ),
            ),

            // Card grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    final isFlipped = _flippedIndices.contains(index);
                    
                    return GestureDetector(
                      onTap: () => _flipCard(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFlipped ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(
                            color: isFlipped ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isFlipped
                              ? card.type == CardType.symbol
                                  ? Text(
                                      card.content,
                                      style: const TextStyle(fontSize: 32),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        card.content,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                              : const Icon(
                                  Icons.question_mark,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Quit button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Quit Game?'),
                      content: const Text('Your progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Quit'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Quit Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    int xpEarned = 60;
    
    if (_timeElapsed < 60) {
      xpEarned += 20;
    }
    
    if (_moves <= 15) {
      xpEarned += 20;
    }

    final String rating = _moves <= 12 ? 'Perfect!' : _moves <= 18 ? 'Great!' : 'Good!';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Game Complete'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                rating,
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You matched all pairs!',
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
                    _buildStatRow('Time', '${_timeElapsed}s'),
                    const Divider(height: 24),
                    _buildStatRow('Moves', '$_moves'),
                    const Divider(height: 24),
                    _buildStatRow('Matches', '6/6'),
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

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
}

class CardPair {
  final String id;
  final String text;
  final String symbol;

  CardPair(this.text, this.symbol) : id = text;
}

class CardItem {
  final String id;
  final String content;
  final CardType type;

  CardItem({
    required this.id,
    required this.content,
    required this.type,
  });
}

enum CardType { text, symbol }

