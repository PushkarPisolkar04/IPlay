import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/primary_button.dart';
import '../../services/game_content_service.dart';
import '../../services/game_integration_service.dart';
import '../../models/ip_defender_model.dart';
import '../../core/game_engine/td_game_engine.dart';
import '../../core/game_engine/td_game_painter.dart';
import '../../core/game_engine/svg_to_image.dart';

/// IP Defender Tower Defense Game
class IPDefenderTDScreen extends StatefulWidget {
  const IPDefenderTDScreen({super.key});

  @override
  State<IPDefenderTDScreen> createState() => _IPDefenderTDScreenState();
}

class _IPDefenderTDScreenState extends State<IPDefenderTDScreen>
    with SingleTickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final GameContentService _gameService = GameContentService();

  IPDefenderGame? _gameData;
  bool _loading = true;
  String? _error;

  bool _gameStarted = false;
  int _currentLevelIndex = 0;

  TDGameEngine? _engine;
  Ticker? _ticker;
  Duration _lastFrameTime = Duration.zero;

  // UI state
  PlacedTower? _selectedTower;
  Tower? _towerToPlace;
  Coordinate? _hoverGridPos;
  Map<String, ui.Image>? _svgImages;

  @override
  void initState() {
    super.initState();
    _loadGameContent();
  }

  Future<void> _loadGameContent() async {
    try {
      final IPDefenderGame gameData = await _gameService.loadIPDefender();
      
      // Load SVG assets
      await _loadSvgAssets(gameData);
      
      setState(() {
        _gameData = gameData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSvgAssets(IPDefenderGame gameData) async {
    try {
      final Map<String, String> assetPaths = {};
      
      // Add game map
      assetPaths['assets/maps/game_map.svg'] = 'assets/maps/game_map.svg';
      
      // Collect all tower sprite URLs
      for (final tower in gameData.towers) {
        assetPaths[tower.spriteUrl] = tower.spriteUrl;
        assetPaths[tower.projectileUrl] = tower.projectileUrl;
      }
      
      // Collect all enemy sprite URLs
      for (final enemy in gameData.enemies) {
        assetPaths[enemy.spriteUrl] = enemy.spriteUrl;
      }
      
      // Load all SVGs as images
      _svgImages = await SvgToImage.loadMultipleSvgs(assetPaths, width: 100, height: 100);
    } catch (e) {
      // If SVG loading fails, game will use fallback rendering
      print('Failed to load SVG assets: $e');
      _svgImages = {};
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_gameData == null) return;

    final level = _gameData!.levels[_currentLevelIndex];

    setState(() {
      _gameStarted = true;
      _engine = TDGameEngine(
        levelData: level,
        availableTowers: _gameData!.towers,
        enemyTypes: _gameData!.enemies,
        path: level.pathCoordinates,
      );
    });

    // Start game loop at 60 FPS
    _ticker = createTicker(_onTick);
    _ticker!.start();
  }


  void _onTick(Duration elapsed) {
    if (_engine == null) return;

    final deltaTime = (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = elapsed;

    setState(() {
      _engine!.update(deltaTime);
    });

    // Check if game ended
    if (_engine!.isGameOver) {
      _ticker?.stop();
      _saveScore();
    }
  }

  Future<void> _saveScore() async {
    if (_engine == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _gameData != null) {
      try {
        final gameIntegrationService = GameIntegrationService();
        final score = _engine!.coins + (_engine!.ipAssetHealth * 10);
        
        final isFirstCompletion = await gameIntegrationService.isFirstCompletion(_gameData!.id);
        final isPerfectScore = _engine!.ipAssetHealth == _gameData!.levels[_currentLevelIndex].ipAssetHealth;
        
        // Award XP with automatic bonuses
        final xpEarned = await gameIntegrationService.awardGameXP(
          gameId: _gameData!.id,
          baseXP: _engine!.isVictory ? _gameData!.xpReward : (_gameData!.xpReward ~/ 2),
          score: score,
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );
        
        // Save progress
        await gameIntegrationService.saveGameProgress(
          gameId: _gameData!.id,
          score: score,
          timeSpentSeconds: 0,
          completed: _engine!.isVictory,
        );
        
        // Submit to leaderboards
        if (_engine!.isVictory) {
          await gameIntegrationService.submitToLeaderboards(
            gameId: _gameData!.id,
            score: score,
            scopes: _gameData!.leaderboard.scope,
          );
        }
        
        // Log analytics
        await gameIntegrationService.logGameComplete(
          gameId: _gameData!.id,
          score: score,
          timeSpentSeconds: 0,
          isPerfectScore: isPerfectScore,
        );
      } catch (e) {
        // Error saving score
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameStarted = false;
      _engine = null;
      _selectedTower = null;
      _towerToPlace = null;
      _lastFrameTime = Duration.zero;
    });
  }

  void _onTapGame(TapDownDetails details) {
    if (_engine == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);

    // Adjust for game area offset (account for HUD)
    final gameAreaOffset = Offset(0, 100); // Top HUD height
    final adjustedPosition = localPosition - gameAreaOffset;

    final gridPos = _engine!.worldToGrid(
      Coordinate(x: adjustedPosition.dx, y: adjustedPosition.dy),
    );

    setState(() {
      if (_towerToPlace != null) {
        // Try to place tower
        if (_engine!.placeTower(_towerToPlace!, gridPos)) {
          HapticFeedbackUtil.lightImpact();
          _towerToPlace = null;
        }
      } else {
        // Check if tapped on existing tower
        _selectedTower = null;
        for (final tower in _engine!.placedTowers) {
          if (tower.gridPosition.x == gridPos.x &&
              tower.gridPosition.y == gridPos.y) {
            _selectedTower = tower;
            HapticFeedbackUtil.lightImpact();
            break;
          }
        }
      }
    });
  }

  void _onHoverGame(dynamic event) {
    if (_engine == null || _towerToPlace == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(event.position);
    final gameAreaOffset = Offset(0, 100);
    final adjustedPosition = localPosition - gameAreaOffset;

    final gridPos = _engine!.worldToGrid(
      Coordinate(x: adjustedPosition.dx, y: adjustedPosition.dy),
    );

    setState(() {
      _hoverGridPos = gridPos;
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

    if (_engine!.isGameOver) {
      return _buildResultScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('IP Defender'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Loading game content...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('IP Defender'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppDesignSystem.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load game content',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error ?? 'Unknown error',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Retry',
                onPressed: _loadGameContent,
                fullWidth: true,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    if (_gameData == null) return _buildLoadingScreen();

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(_gameData!.name),
        backgroundColor: _gameData!.color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _gameData!.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield,
                  size: 60,
                  color: _gameData!.color,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _gameData!.name,
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _gameData!.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
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
                    _buildRuleItem('🏗️', 'Build towers to defend your IP assets'),
                    _buildRuleItem('⚡', 'Start waves to spawn enemies'),
                    _buildRuleItem('💰', 'Earn coins to build and upgrade towers'),
                    _buildRuleItem('🎯', 'Complete all waves to win'),
                    _buildRuleItem('❤️', 'Don\'t let IP health reach 0'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Level selection
              Text('Select Level', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gameData!.levels.length,
                  itemBuilder: (context, index) {
                    final level = _gameData!.levels[index];
                    final isSelected = _currentLevelIndex == index;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentLevelIndex = index;
                        });
                        HapticFeedbackUtil.lightImpact();
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _gameData!.color
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _gameData!.color,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : _gameData!.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              level.difficulty ?? 'Normal',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Start Level ${_currentLevelIndex + 1}',
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
    if (_engine == null || _gameData == null) return _buildLoadingScreen();

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD
            _buildTopHUD(),
            // Game area
            Expanded(
              child: GestureDetector(
                onTapDown: _onTapGame,
                child: MouseRegion(
                  onHover: _onHoverGame,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      image: _svgImages != null && _svgImages!.containsKey('assets/maps/game_map.svg')
                          ? null // SVG will be drawn by painter
                          : null,
                    ),
                    child: CustomPaint(
                      painter: TDGamePainter(
                        engine: _engine!,
                        selectedTower: _selectedTower,
                        hoverGridPos: _hoverGridPos,
                        towerToPlace: _towerToPlace,
                        svgImages: _svgImages,
                      ),
                      size: Size(
                        TDGameEngine.gridWidth * TDGameEngine.tileSize,
                        TDGameEngine.gridHeight * TDGameEngine.tileSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom UI
            _buildBottomUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    if (_engine == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppDesignSystem.backgroundGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHUDItem(Icons.favorite, 'Health', '${_engine!.ipAssetHealth}'),
          _buildHUDItem(Icons.monetization_on, 'Coins', '${_engine!.coins}'),
          _buildHUDItem(
            Icons.waves,
            'Wave',
            '${_engine!.currentWaveIndex}/${_engine!.levelData.waves.length}',
          ),
          if (!_engine!.isWaveActive && _engine!.currentWaveIndex < _engine!.levelData.waves.length)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _engine!.startNextWave();
                });
                HapticFeedbackUtil.lightImpact();
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start Wave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppDesignSystem.primaryIndigo, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3.copyWith(fontSize: 16)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomUI() {
    if (_engine == null || _gameData == null) return const SizedBox();

    if (_selectedTower != null) {
      return _buildTowerInfoPanel();
    } else {
      return _buildTowerMenu();
    }
  }

  Widget _buildTowerMenu() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: AppDesignSystem.backgroundGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build Tower', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gameData!.towers.length,
              itemBuilder: (context, index) {
                final tower = _gameData!.towers[index];
                final canAfford = _engine!.coins >= tower.cost;

                return GestureDetector(
                  onTap: canAfford
                      ? () {
                          setState(() {
                            _towerToPlace = tower;
                            _selectedTower = null;
                          });
                          HapticFeedbackUtil.lightImpact();
                        }
                      : null,
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _towerToPlace == tower
                          ? tower.color.withValues(alpha: 0.3)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _towerToPlace == tower
                            ? tower.color
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tower.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.castle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tower.cost}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: canAfford ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerInfoPanel() {
    if (_selectedTower == null) return const SizedBox();

    final tower = _selectedTower!;
    final canUpgrade = tower.canUpgrade() && _engine!.coins >= tower.getUpgradeCost();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppDesignSystem.backgroundGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tower.towerData.name,
                      style: AppTextStyles.cardTitle,
                    ),
                    Text(
                      'Level ${tower.level}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (tower.canUpgrade())
                    ElevatedButton.icon(
                      onPressed: canUpgrade
                          ? () {
                              setState(() {
                                _engine!.upgradeTower(tower);
                              });
                              HapticFeedbackUtil.lightImpact();
                            }
                          : null,
                      icon: const Icon(Icons.upgrade, size: 16),
                      label: Text('${tower.getUpgradeCost()}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _engine!.sellTower(tower);
                        _selectedTower = null;
                      });
                      HapticFeedbackUtil.lightImpact();
                    },
                    icon: const Icon(Icons.sell, size: 16),
                    label: const Text('Sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignSystem.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedTower = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _buildStatChip('⚔️ ${tower.damage}'),
              const SizedBox(width: AppSpacing.xs),
              _buildStatChip('📏 ${tower.range.toStringAsFixed(1)}'),
              const SizedBox(width: AppSpacing.xs),
              _buildStatChip('⚡ ${tower.attackSpeed.toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildResultScreen() {
    if (_engine == null || _gameData == null) return _buildLoadingScreen();

    final isVictory = _engine!.isVictory;
    final score = _engine!.coins + (_engine!.ipAssetHealth * 10);
    final xpEarned = isVictory ? _gameData!.xpReward : (_gameData!.xpReward ~/ 2);

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over'),
        backgroundColor: _gameData!.color,
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
                  color: (isVictory ? AppDesignSystem.success : Colors.orange)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVictory ? Icons.emoji_events : Icons.shield_outlined,
                  size: 60,
                  color: isVictory ? AppDesignSystem.success : Colors.orange,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                isVictory ? 'Victory!' : 'Defeated!',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isVictory
                    ? 'You successfully defended all waves!'
                    : 'Your IP assets were compromised!',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
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
                    _buildStatRow('Score', score.toString()),
                    const Divider(height: 24),
                    _buildStatRow('Waves Completed', '${_engine!.currentWaveIndex}'),
                    const Divider(height: 24),
                    _buildStatRow('IP Health', '${_engine!.ipAssetHealth}'),
                    const Divider(height: 24),
                    _buildStatRow('Coins Remaining', '${_engine!.coins}'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isVictory && _currentLevelIndex < _gameData!.levels.length - 1)
                PrimaryButton(
                  text: 'Next Level',
                  onPressed: () {
                    setState(() {
                      _currentLevelIndex++;
                      _gameStarted = false;
                      _engine = null;
                      _selectedTower = null;
                      _towerToPlace = null;
                      _lastFrameTime = Duration.zero;
                    });
                    HapticFeedbackUtil.lightImpact();
                    // Auto-start next level after a short delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _startGame();
                    });
                  },
                  fullWidth: true,
                  icon: Icons.arrow_forward,
                ),
              if (isVictory && _currentLevelIndex < _gameData!.levels.length - 1)
                const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                text: isVictory && _currentLevelIndex >= _gameData!.levels.length - 1
                    ? 'Play Again'
                    : 'Retry Level',
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
            color: isHighlight
                ? const Color(0xFFE91E63)
                : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }
}
