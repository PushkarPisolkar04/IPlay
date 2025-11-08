import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/primary_button.dart';

/// IP Defender - Tap infringers to protect your IP assets
class IPDefenderGame extends StatefulWidget {
  const IPDefenderGame({super.key});

  @override
  State<IPDefenderGame> createState() => _IPDefenderGameState();
}

class _IPDefenderGameState extends State<IPDefenderGame> with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  
  bool _gameStarted = false;
  bool _gameEnded = false;
  
  int _currentWave = 1;
  int _score = 0;
  int _assetsStolen = 0;
  int _infringersDefeated = 0;
  
  final List<Infringer> _infringers = [];
  Timer? _spawnTimer;
  Timer? _moveTimer;
  
  final Random _random = Random();
  final int _maxWaves = 5;
  final int _maxAssetsStolen = 3;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentWave = 1;
      _score = 0;
      _assetsStolen = 0;
      _infringersDefeated = 0;
      _infringers.clear();
    });
    _startWave();
  }

  void _startWave() {
    // Spawn infringers periodically
    final spawnInterval = Duration(milliseconds: max(500, 2000 - (_currentWave * 200)));
    _spawnTimer = Timer.periodic(spawnInterval, (timer) {
      if (_assetsStolen >= _maxAssetsStolen) {
        _endGame();
        return;
      }
      
      _spawnInfringer();
    });
    
    // Move infringers
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _infringers.removeWhere((infringer) {
          infringer.position += infringer.speed;
          
          // Check if reached the center (asset stolen)
          if (infringer.position >= 1.0) {
            _assetsStolen++;
            if (_assetsStolen >= _maxAssetsStolen) {
              _endGame();
            }
            return true;
          }
          return false;
        });
      });
    });
    
    // End wave after duration
    Future.delayed(Duration(seconds: 15 + (_currentWave * 5)), () {
      if (_gameStarted && !_gameEnded) {
        _endWave();
      }
    });
  }

  void _spawnInfringer() {
    if (!_gameStarted || _gameEnded) return;
    
    final infringer = Infringer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _getRandomInfringerType(),
      direction: _random.nextInt(4), // 0: top, 1: right, 2: bottom, 3: left
      speed: 0.01 + (_currentWave * 0.002),
      position: 0.0,
    );
    
    setState(() {
      _infringers.add(infringer);
    });
  }

  String _getRandomInfringerType() {
    final types = ['Pirate', 'Copycat', 'Faker', 'Thief'];
    return types[_random.nextInt(types.length)];
  }

  void _tapInfringer(Infringer infringer) {
    // Haptic feedback for successful tap
    HapticFeedbackUtil.lightImpact();
    
    setState(() {
      _infringers.remove(infringer);
      _infringersDefeated++;
      _score += 10;
    });
  }

  void _endWave() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    
    if (_currentWave < _maxWaves && _assetsStolen < _maxAssetsStolen) {
      // Next wave
      setState(() {
        _currentWave++;
        _infringers.clear();
      });
      
      // Show wave transition
      Future.delayed(const Duration(seconds: 2), () {
        if (_gameStarted && !_gameEnded) {
          _startWave();
        }
      });
    } else {
      _endGame();
    }
  }

  void _endGame() {
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    
    // Haptic feedback for XP gain
    HapticFeedbackUtil.xpGain();
    
    setState(() {
      _gameEnded = true;
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final xpEarned = _score;
        
        // Save to progress
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_ip_defender',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: _infringersDefeated,
          totalQuestions: _infringersDefeated + _assetsStolen,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_ip_defender')
            .set({
          'userId': user.uid,
          'contentId': 'game_ip_defender',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': _score,
          'infringersDefeated': _infringersDefeated,
          'wavesCompleted': _currentWave,
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
        final currentBestScore = currentScores['ip_defender'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'ip_defender': _score > currentBestScore ? _score : currentBestScore,
            },
            'lastPlayedAt': Timestamp.now(),
          },
        }, SetOptions(merge: true));
        
        // print('✅ Game score saved: $_score, XP earned: $xpEarned');
      } catch (e) {
        // print('❌ Error saving game score: $e');
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
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
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('IP Defender'),
        backgroundColor: AppDesignSystem.error,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppDesignSystem.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 60,
                  color: AppDesignSystem.error,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'IP Defender',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Protect your IP assets from infringers!',
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
                    _buildRuleItem('🛡️', 'Defend your IP assets'),
                    _buildRuleItem('👾', 'Tap infringers to stop them'),
                    _buildRuleItem('📈', '5 waves with increasing difficulty'),
                    _buildRuleItem('❌', 'Game over if 3 assets stolen'),
                    _buildRuleItem('⭐', '10 points per infringer stopped'),
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
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('Wave $_currentWave/$_maxWaves'),
        backgroundColor: AppDesignSystem.error,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppDesignSystem.backgroundGrey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.stars, 'Score', _score.toString()),
                  _buildStatItem(Icons.shield, 'Assets', '${_maxAssetsStolen - _assetsStolen}'),
                  _buildStatItem(Icons.check_circle, 'Defeated', _infringersDefeated.toString()),
                ],
              ),
            ),

            // Game area
            Expanded(
              child: Stack(
                children: [
                  // Center asset (what we're protecting)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppDesignSystem.success,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.copyright,
                        size: 40,
                        color: AppDesignSystem.success,
                      ),
                    ),
                  ),

                  // Infringers
                  ..._infringers.map((infringer) => _buildInfringer(infringer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfringer(Infringer infringer) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = (size.height - 200) / 2; // Adjust for app bar and stats
    
    double left = 0;
    double top = 0;
    
    // Calculate position based on direction
    switch (infringer.direction) {
      case 0: // From top
        left = centerX - 20 + (_random.nextDouble() * 40 - 20);
        top = (centerY - 200) * (1 - infringer.position);
        break;
      case 1: // From right
        left = centerX + (size.width / 2 - 100) * infringer.position;
        top = centerY - 20 + (_random.nextDouble() * 40 - 20);
        break;
      case 2: // From bottom
        left = centerX - 20 + (_random.nextDouble() * 40 - 20);
        top = centerY + (size.height / 2 - 200) * infringer.position;
        break;
      case 3: // From left
        left = centerX - (size.width / 2 - 100) * (1 - infringer.position);
        top = centerY - 20 + (_random.nextDouble() * 40 - 20);
        break;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _tapInfringer(infringer),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppDesignSystem.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppDesignSystem.error.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppDesignSystem.primaryIndigo, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(fontSize: 18),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final survived = _assetsStolen < _maxAssetsStolen;
    final xpEarned = _score;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over'),
        backgroundColor: AppDesignSystem.error,
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
                  color: survived ? AppDesignSystem.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  survived ? Icons.emoji_events : Icons.shield_outlined,
                  size: 60,
                  color: survived ? AppDesignSystem.success : Colors.orange,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                survived ? 'Victory!' : 'Defeated!',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                survived
                    ? 'You successfully defended your IP assets!'
                    : 'Too many assets were stolen!',
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
                    _buildStatRow('Waves Completed', '$_currentWave/$_maxWaves'),
                    const Divider(height: 24),
                    _buildStatRow('Infringers Defeated', _infringersDefeated.toString()),
                    const Divider(height: 24),
                    _buildStatRow('Assets Stolen', '$_assetsStolen/$_maxAssetsStolen'),
                    const Divider(height: 24),
                    _buildStatRow('Final Score', _score.toString()),
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
            color: isHighlight ? AppDesignSystem.error : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }
}

class Infringer {
  final String id;
  final String type;
  final int direction; // 0: top, 1: right, 2: bottom, 3: left
  final double speed;
  double position; // 0.0 to 1.0

  Infringer({
    required this.id,
    required this.type,
    required this.direction,
    required this.speed,
    required this.position,
  });
}
