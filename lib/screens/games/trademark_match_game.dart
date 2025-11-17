import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../services/game_content_service.dart';
import '../../services/game_integration_service.dart';
import '../../models/trademark_match_model.dart';
import '../../widgets/primary_button.dart';

/// Trademark Match - Beautiful Memory Card Flip Game
class TrademarkMatchScreen extends StatefulWidget {
  const TrademarkMatchScreen({super.key});

  @override
  State<TrademarkMatchScreen> createState() => _TrademarkMatchScreenState();
}

class _TrademarkMatchScreenState extends State<TrademarkMatchScreen> 
    with TickerProviderStateMixin {
  final GameContentService _gameService = GameContentService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  
  TrademarkMatchGame? _gameData;
  bool _loading = true;
  String? _error;
  
  // Game state
  List<MemoryCard> _cards = [];
  List<int> _flippedIndices = [];
  Set<int> _matchedIndices = {};
  bool _canFlip = true;
  int _score = 0;
  int _matches = 0;
  int _totalFlips = 0;
  int _timeRemaining = 120; // 2 minutes
  Timer? _timer;
  bool _gameStarted = false;
  bool _gameEnded = false;
  
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
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    if (_gameData == null) return;
    
    final selectedPairs = _gameData!.selectRandomPairs();
    final cards = <MemoryCard>[];
    
    for (var pair in selectedPairs) {
      cards.add(MemoryCard(
        id: pair.id,
        type: CardType.logo,
        content: pair.company,
        imageUrl: pair.imageUrl,
        pairId: pair.id,
        points: pair.points,
      ));
      
      cards.add(MemoryCard(
        id: '${pair.id}_name',
        type: CardType.name,
        content: pair.company,
        imageUrl: '',
        pairId: pair.id,
        points: pair.points,
      ));
    }
    
    cards.shuffle(Random());
    
    setState(() {
      _cards = cards;
      _flippedIndices.clear();
      _matchedIndices.clear();
      _score = 0;
      _matches = 0;
      _totalFlips = 0;
      _timeRemaining = _gameData!.timeLimit ?? 120;
    });
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
    _initializeGame();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        
        if (_timeRemaining == 0) {
          _endGame(timeUp: true);
        }
      }
    });
  }

  void _onCardTapped(int index) {
    if (!_canFlip || _matchedIndices.contains(index) || 
        _flippedIndices.contains(index)) {
      return;
    }

    setState(() {
      _flippedIndices.add(index);
      _totalFlips++;
    });

    if (_flippedIndices.length == 2) {
      _canFlip = false;
      Future.delayed(const Duration(milliseconds: 600), () {
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    final index1 = _flippedIndices[0];
    final index2 = _flippedIndices[1];
    final card1 = _cards[index1];
    final card2 = _cards[index2];

    if (card1.pairId == card2.pairId) {
      // Calculate bonus points based on performance
      int matchPoints = card1.points;
      
      // Time bonus: +5 points if more than 2 minutes remaining
      if (_timeRemaining > 120) {
        matchPoints += 5;
      } else if (_timeRemaining > 60) {
        matchPoints += 3;
      }
      
      // Efficiency bonus: fewer flips = more points
      final perfectFlips = (_matches + 1) * 2; // Minimum flips needed
      if (_totalFlips <= perfectFlips + 2) {
        matchPoints += 5; // Nearly perfect memory
      } else if (_totalFlips <= perfectFlips + 4) {
        matchPoints += 3; // Good memory
      }
      
      setState(() {
        _matchedIndices.add(index1);
        _matchedIndices.add(index2);
        _score += matchPoints;
        _matches++;
      });

      if (_matchedIndices.length == _cards.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _endGame();
        });
      }
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _flippedIndices.clear();
          _canFlip = true;
        });
      }
    });
  }

  void _endGame({bool timeUp = false}) {
    _timer?.cancel();
    
    setState(() {
      _gameEnded = true;
    });
    
    if (!timeUp) {
      _confettiController.play();
    }
    
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _gameData != null) {
      try {
        final gameIntegrationService = GameIntegrationService();
        
        final isFirstCompletion = await gameIntegrationService
            .isFirstCompletion(_gameData!.id);
        final isPerfectScore = _matches == (_cards.length ~/ 2) && 
            _timeRemaining > 60;
        
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
          timeSpentSeconds: (_gameData!.timeLimit ?? 120) - _timeRemaining,
          completed: _matches == (_cards.length ~/ 2),
        );
        
        await gameIntegrationService.submitToLeaderboards(
          gameId: _gameData!.id,
          score: _score,
          scopes: _gameData!.leaderboard.scope,
        );
      } catch (e) {
        print('Error saving score: $e');
      }
    }
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen();
    if (!_gameStarted) return _buildStartScreen();
    if (_gameEnded) return _buildResultScreen();
    return _buildGameScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Trademark Match', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading game...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF2196F3), const Color(0xFFEC4899)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadGameContent();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Trademark Match', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
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
                      color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/logos/trademark_match.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.grid_4x4,
                      size: 60,
                      color: Color(0xFF2196F3),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Trademark Match',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Match famous trademarks with their companies!',
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
                    _buildRuleItem('🃏', '12 cards - 6 brand pairs'),
                    _buildRuleItem('⏱️', '2 minutes to complete'),
                    _buildRuleItem('🎯', 'Match logos with names'),
                    _buildRuleItem('⭐', 'Score based on speed & memory'),
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
                color: const Color(0xFF2196F3),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2196F3).withValues(alpha: 0.1),
              const Color(0xFFEC4899).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) => _buildCard(index),
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
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    final timeColor = _timeRemaining < 30 ? Colors.red : const Color(0xFF2196F3);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
              onPressed: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Stats badges
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Matches
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_matches/${_cards.length ~/ 2}',
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
                        '$_score',
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
          ),
        ],
      ),
    );
  }


  Widget _buildCard(int index) {
    final card = _cards[index];
    final isFlipped = _flippedIndices.contains(index) || 
        _matchedIndices.contains(index);
    final isMatched = _matchedIndices.contains(index);

    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: isFlipped ? 1.0 : 0.0),
        builder: (context, value, child) {
          final angle = value * pi;
          final isBack = angle > pi / 2;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFront(card, isMatched),
                  )
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Logo
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/logos/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card, bool isMatched) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMatched
              ? [
                  Colors.white,
                  const Color(0xFF10B981).withValues(alpha: 0.05),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched 
              ? const Color(0xFF10B981) 
              : const Color(0xFFE5E7EB),
          width: isMatched ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isMatched
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isMatched ? 12 : 8,
            offset: Offset(0, isMatched ? 6 : 4),
          ),
          if (isMatched)
            const BoxShadow(
              color: Color(0x3310B981),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
        ],
      ),
      child: card.type == CardType.logo
          ? _buildLogoCard(card)
          : _buildNameCard(card),
    );
  }

  Widget _buildLogoCard(MemoryCard card) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                card.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(MemoryCard card) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              card.content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildResultScreen() {
    final isWin = _matches == (_cards.length ~/ 2);
    final isPerfect = isWin && _timeRemaining > 60;
    final accuracy = _matches / (_cards.length ~/ 2) * 100;
    
    // Calculate XP earned based on score
    int xpEarned = _score; // Base XP = score
    if (isPerfect) {
      xpEarned = (_score * 1.5).round(); // 50% bonus for perfect
    } else if (isWin) {
      xpEarned = (_score * 1.2).round(); // 20% bonus for completion
    }
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                              colors: isWin
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
                                color: isWin 
                                    ? AppDesignSystem.success.withValues(alpha: 0.4)
                                    : Colors.orange.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isWin ? Icons.emoji_events : Icons.timer_off,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

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
                                isWin 
                                    ? (isPerfect ? 'Perfect Match!' : 'Great Job!') 
                                    : 'Time\'s Up!',
                                style: AppTextStyles.h1.copyWith(
                                  color: isWin ? AppDesignSystem.success : Colors.orange,
                                  fontSize: 26,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  '$_matches/${_cards.length ~/ 2} pairs matched',
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

                  const SizedBox(height: 20),

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
                                    const Color(0xFF2196F3).withValues(alpha: 0.1),
                                    const Color(0xFFEC4899).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildFancyStatRow(
                                      Icons.star,
                                      'Score',
                                      '$_score points',
                                      const Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFancyStatRow(
                                      Icons.check_circle,
                                      'Matches',
                                      '$_matches/${_cards.length ~/ 2}',
                                      const Color(0xFF10B981),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFancyStatRow(
                                      Icons.touch_app,
                                      'Total Flips',
                                      '$_totalFlips flips',
                                      const Color(0xFF8B5CF6),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFancyStatRow(
                                      Icons.speed,
                                      'Efficiency',
                                      '${accuracy.toStringAsFixed(0)}%',
                                      const Color(0xFF2196F3),
                                    ),
                                    if (isWin) ...[
                                      const SizedBox(height: 12),
                                      _buildFancyStatRow(
                                        Icons.military_tech,
                                        'XP Earned',
                                        '+$xpEarned XP',
                                        const Color(0xFFEC4899),
                                        isHighlight: true,
                                      ),
                                    ],
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
                                color: const Color(0xFF2196F3),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Back to Games',
                                    style: TextStyle(color: Color(0xFF2196F3)),
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
          if (isWin)
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
            color: isHighlight ? const Color(0xFF2196F3) : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Memory Card Model
class MemoryCard {
  final String id;
  final CardType type;
  final String content;
  final String imageUrl;
  final String pairId;
  final int points;

  MemoryCard({
    required this.id,
    required this.type,
    required this.content,
    required this.imageUrl,
    required this.pairId,
    required this.points,
  });
}

enum CardType { logo, name }
