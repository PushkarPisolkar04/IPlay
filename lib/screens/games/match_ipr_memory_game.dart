import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../services/sound_service.dart';
import '../../services/game_content_service.dart';
import '../../services/game_integration_service.dart';
import '../../models/trademark_match_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/confetti_widget.dart';

/// Trademark Match - Memory Card Flip Game
class MatchIPRMemoryGame extends StatefulWidget {
  const MatchIPRMemoryGame({super.key});

  @override
  State<MatchIPRMemoryGame> createState() => _MatchIPRMemoryGameState();
}

class _MatchIPRMemoryGameState extends State<MatchIPRMemoryGame> with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final GameContentService _gameService = GameContentService();
  
  TrademarkMatchGame? _gameData;
  bool _loading = true;
  String? _error;
  
  // Game state
  List<MemoryCard> _cards = [];
  List<int> _flippedIndices = [];
  Set<int> _matchedIndices = {};
  bool _canFlip = true;
  int _score = 0;
  int _moves = 0;
  int _timeElapsed = 0;
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _loadGameContent();
  }

  Future<void> _loadGameContent() async {
    try {
      final game = await _gameService.loadTrademarkMatch();
      setState(() {
        _gameData = game;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    if (_gameData == null) return;
    
    // Select random pairs
    final selectedPairs = _gameData!.selectRandomPairs();
    
    // Create cards (2 cards per pair - logo and company name)
    final cards = <MemoryCard>[];
    for (var pair in selectedPairs) {
      // Logo card
      cards.add(MemoryCard(
        id: pair.id,
        type: CardType.logo,
        content: pair.trademark,
        imageUrl: pair.imageUrl,
        pairId: pair.id,
      ));
      
      // Company name card
      cards.add(MemoryCard(
        id: '${pair.id}_company',
        type: CardType.company,
        content: pair.company,
        imageUrl: '',
        pairId: pair.id,
      ));
    }
    
    // Shuffle cards
    cards.shuffle(Random());
    
    setState(() {
      _cards = cards;
      _flippedIndices.clear();
      _matchedIndices.clear();
      _score = 0;
      _moves = 0;
    });
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _timeElapsed = 0;
      _showConfetti = false;
    });
    _initializeGame();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeElapsed++;
        });
      }
    });
  }

  void _onCardTapped(int index) {
    if (!_canFlip || _matchedIndices.contains(index) || _flippedIndices.contains(index)) {
      return;
    }

    setState(() {
      _flippedIndices.add(index);
    });

    HapticFeedbackUtil.lightImpact();

    if (_flippedIndices.length == 2) {
      _moves++;
      _canFlip = false;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final index1 = _flippedIndices[0];
    final index2 = _flippedIndices[1];
    final card1 = _cards[index1];
    final card2 = _cards[index2];

    if (card1.pairId == card2.pairId) {
      // Match found!
      setState(() {
        _matchedIndices.add(index1);
        _matchedIndices.add(index2);
        _score += 10;
      });

      HapticFeedbackUtil.correctAnswer();
      SoundService.playCorrectAnswer();

      // Check if game is complete
      if (_matchedIndices.length == _cards.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _endGame();
        });
      }

      // Reset for next turn
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _flippedIndices.clear();
          _canFlip = true;
        });
      });
    } else {
      // No match
      HapticFeedbackUtil.incorrectAnswer();
      SoundService.playIncorrectAnswer();

      // Flip cards back after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _flippedIndices.clear();
          _canFlip = true;
        });
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    
    setState(() {
      _showConfetti = true;
      _gameEnded = true;
    });
    
    HapticFeedbackUtil.xpGain();
    SoundService.playXPGain();
    
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _gameData != null) {
      try {
        final gameIntegrationService = GameIntegrationService();
        
        final isFirstCompletion = await gameIntegrationService.isFirstCompletion(_gameData!.id);
        final isPerfectScore = _moves == (_cards.length ~/ 2); // Perfect = minimum moves
        
        await gameIntegrationService.awardGameXP(
          gameId: _gameData!.id,
          baseXP: _gameData!.xpReward,
          score: _score,
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );
        
        await gameIntegrationService.saveGameProgress(
          gameId: _gameData!.id,
          score: _score,
          timeSpentSeconds: _timeElapsed,
          completed: true,
        );
        
        await gameIntegrationService.submitToLeaderboards(
          gameId: _gameData!.id,
          score: _score,
          scopes: _gameData!.leaderboard.scope,
        );
        
        await gameIntegrationService.logGameComplete(
          gameId: _gameData!.id,
          score: _score,
          timeSpentSeconds: _timeElapsed,
          isPerfectScore: isPerfectScore,
        );
      } catch (e) {
        // Error handling
      }
    }
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _showConfetti = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (!_gameStarted) {
      return _buildStartScreen();
    }

    if (_gameEnded) {
      return _buildResultScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Loading Game...'),
        backgroundColor: AppDesignSystem.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: AppDesignSystem.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Failed to load game content', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(_error ?? 'Unknown error', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Retry',
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadGameContent();
                },
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(_gameData?.name ?? 'Trademark Match'),
        backgroundColor: AppDesignSystem.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_4x4, size: 60, color: AppDesignSystem.primaryPink),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(_gameData?.name ?? 'Trademark Match', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.md),
              Text(
                _gameData?.description ?? 'Match trademarks with their companies!',
                style: AppTextStyles.bodyLarge.copyWith(color: AppDesignSystem.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to Play:', style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleItem('🃏', 'Tap cards to flip them over'),
                    _buildRuleItem('🎯', 'Match logos with company names'),
                    _buildRuleItem('🧠', 'Remember card positions'),
                    _buildRuleItem('⚡', 'Match all pairs to win'),
                    _buildRuleItem('⭐', 'Fewer moves = higher score'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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

  Widget _buildGameScreen() {
    final gridSize = _cards.length <= 12 ? 3 : 4;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withValues(alpha: 0.1),
              AppDesignSystem.primaryPink.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildScoreBoard(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (context, index) {
                          return _buildMemoryCard(index);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_showConfetti)
                Positioned.fill(child: ConfettiWidget(show: _showConfetti)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer, '${_timeElapsed}s'),
          _buildStatItem(Icons.touch_app, '$_moves moves'),
          _buildStatItem(Icons.star, '$_score pts'),
          _buildStatItem(Icons.check_circle, '${_matchedIndices.length ~/ 2}/${_cards.length ~/ 2}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppDesignSystem.primaryPink),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMemoryCard(int index) {
    final card = _cards[index];
    final isFlipped = _flippedIndices.contains(index) || _matchedIndices.contains(index);
    final isMatched = _matchedIndices.contains(index);

    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isMatched
              ? AppDesignSystem.success.withValues(alpha: 0.2)
              : isFlipped
                  ? Colors.white
                  : AppDesignSystem.primaryPink,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isMatched ? AppDesignSystem.success : AppDesignSystem.primaryPink,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isFlipped
            ? _buildCardFront(card)
            : _buildCardBack(),
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card) {
    if (card.type == CardType.logo) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                card.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 32);
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.content,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Text(
            card.content,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildCardBack() {
    return Center(
      child: Icon(
        Icons.copyright,
        size: 48,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildResultScreen() {
    final perfectMoves = _cards.length ~/ 2;
    final isPerfect = _moves == perfectMoves;
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Complete'),
        backgroundColor: AppDesignSystem.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppDesignSystem.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 60, color: AppDesignSystem.success),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(isPerfect ? 'Perfect Match!' : 'Well Done!', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You matched all trademarks!',
                style: AppTextStyles.bodyLarge.copyWith(color: AppDesignSystem.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Time', '${_timeElapsed}s'),
                    const Divider(height: 24),
                    _buildStatRow('Moves', '$_moves'),
                    const Divider(height: 24),
                    _buildStatRow('Score', '$_score pts'),
                    if (isPerfect) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text('Perfect Game!', style: AppTextStyles.cardTitle.copyWith(color: Colors.amber)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Play Again',
                onPressed: _restartGame,
                fullWidth: true,
                icon: Icons.refresh,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Text('Back to Games', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(value, style: AppTextStyles.h3.copyWith(fontSize: 16)),
      ],
    );
  }
}

// Memory card model
class MemoryCard {
  final String id;
  final CardType type;
  final String content;
  final String imageUrl;
  final String pairId;

  MemoryCard({
    required this.id,
    required this.type,
    required this.content,
    required this.imageUrl,
    required this.pairId,
  });
}

enum CardType { logo, company }
