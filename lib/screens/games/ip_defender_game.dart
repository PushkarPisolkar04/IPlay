import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/game_integration_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/loading_skeleton.dart';

/// IP Defender - Tower Defense Game
class IPDefenderGame extends StatefulWidget {
  const IPDefenderGame({super.key});

  @override
  State<IPDefenderGame> createState() => _IPDefenderGameState();
}

class _IPDefenderGameState extends State<IPDefenderGame> with TickerProviderStateMixin {
  final GameIntegrationService _gameService = GameIntegrationService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  final GlobalKey _gameAreaKey = GlobalKey();
  
  Map<String, dynamic>? _gameData;
  bool _isLoading = true;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _isPaused = false;
  
  int _currentLevelIndex = 0;
  int _currentWaveIndex = 0;
  int _coins = 0;
  int _ipAssetHealth = 100;
  int _score = 0;
  
  final List<Tower> _placedTowers = [];
  final List<Enemy> _activeEnemies = [];
  final List<Projectile> _activeProjectiles = [];
  
  Timer? _gameLoopTimer;
  Timer? _spawnTimer;
  Timer? _incomeTimer;
  
  Tower? _selectedTowerType;
  Tower? _selectedPlacedTower;
  Offset? _dragPosition;
  
  final Random _random = Random();
  int _enemiesSpawned = 0;
  int _enemiesKilled = 0;
  bool _waveInProgress = false;
  
  double _mapScaleX = 1.0;
  double _mapScaleY = 1.0;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _stopAllTimers();
    _confettiController.dispose();
    super.dispose();
  }
  
  void _playConfettiMultipleTimes() {
    // Play confetti 3 times with delays
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _confettiController.play();
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _confettiController.play();
    });
  }

  void _stopAllTimers() {
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();
    _incomeTimer?.cancel();
  }

  Future<void> _loadGameData() async {
    try {
      final String jsonString = await rootBundle.loadString('content/games/ip_defender.json');
      setState(() {
        _gameData = json.decode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startGame() {
    if (_gameData == null) return;
    
    final level = _gameData!['levels'][_currentLevelIndex];
    setState(() {
      _gameStarted = true;
      _gameEnded = false;
      _isPaused = false;
      _coins = level['startingCoins'];
      _ipAssetHealth = level['ipAssetHealth'];
      _score = 0;
      _currentWaveIndex = 0;
      _placedTowers.clear();
      _activeEnemies.clear();
      _activeProjectiles.clear();
      _enemiesSpawned = 0;
      _enemiesKilled = 0;
      _waveInProgress = false;
    });
    
    _startGameLoop();
    _startIncomeGeneration();
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused || _gameEnded) return;
      
      setState(() {
        _updateEnemies();
        _updateTowers();
        _updateProjectiles();
      });
    });
  }

  void _startIncomeGeneration() {
    _incomeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Only generate income during active waves
      if (_isPaused || _gameEnded || !_waveInProgress) return;
      
      int income = 0;
      for (var tower in _placedTowers) {
        if (tower.specialEffect == 'income') {
          income += tower.incomePerSecond;
        }
      }
      
      if (income > 0) {
        setState(() {
          _coins += income;
        });
      }
    });
  }

  void _startWave() {
    if (_gameData == null || _waveInProgress || _isPaused) return;
    
    final level = _gameData!['levels'][_currentLevelIndex];
    final waves = level['waves'] as List;
    
    if (_currentWaveIndex >= waves.length) {
      _completeLevel();
      return;
    }
    
    setState(() {
      _waveInProgress = true;
      _enemiesSpawned = 0;
    });
    
    final wave = waves[_currentWaveIndex];
    final enemies = wave['enemies'] as List;
    final spawnInterval = wave['spawnInterval'];
    
    int totalEnemies = 0;
    for (var enemyData in enemies) {
      totalEnemies += enemyData['count'] as int;
    }
    
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnInterval), (timer) {
      if (_isPaused || _gameEnded) return;
      
      if (_enemiesSpawned >= totalEnemies) {
        timer.cancel();
        return;
      }
      
      _spawnEnemy(enemies);
      _enemiesSpawned++;
    });
  }

  void _spawnEnemy(List enemies) {
    final level = _gameData!['levels'][_currentLevelIndex];
    final pathCoords = level['pathCoordinates'] as List;
    
    // Pick random enemy type from wave
    final enemyData = enemies[_random.nextInt(enemies.length)];
    final enemyType = enemyData['type'];
    final enemyConfig = (_gameData!['enemies'] as List).firstWhere((e) => e['id'] == enemyType);
    
    // Scale path coordinates from reference map to actual display size
    final scaledPathCoords = pathCoords.map((c) {
      final x = (c['x'] as num).toDouble();
      final y = (c['y'] as num).toDouble();
      return Offset(x * _mapScaleX, y * _mapScaleY);
    }).toList();
    
    final enemy = Enemy(
      id: DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
      type: enemyType,
      health: (enemyData['health'] as num).toDouble(),
      maxHealth: (enemyData['health'] as num).toDouble(),
      speed: (enemyData['speed'] as num).toDouble(),
      reward: enemyConfig['reward'],
      spriteUrl: enemyConfig['spriteUrl'],
      color: Color(int.parse(enemyConfig['color'].toString().replaceFirst('0x', '0xFF'))),
      size: (enemyConfig['size'] as num).toDouble(),
      pathIndex: 0,
      progress: 0.0,
      pathCoordinates: scaledPathCoords,
    );
    
    setState(() {
      _activeEnemies.add(enemy);
    });
  }

  void _updateEnemies() {
    final toRemove = <Enemy>[];
    
    for (var enemy in _activeEnemies) {
      // Reduced speed multiplier from 0.01 to 0.006 for better gameplay
      enemy.progress += enemy.speed * 0.006 * (enemy.slowFactor);
      
      if (enemy.progress >= 1.0) {
        enemy.progress = 0.0;
        enemy.pathIndex++;
        
        if (enemy.pathIndex >= enemy.pathCoordinates.length - 1) {
          // Enemy reached the end - damage based on enemy type
          int damage = 10;
          if (enemy.type == 'infringer') {
            damage = 20; // Heavy enemies do more damage
          } else if (enemy.type == 'pirate') {
            damage = 8; // Fast enemies do less damage
          } else if (enemy.type == 'copycat') {
            damage = 12;
          }
          
          _ipAssetHealth = (_ipAssetHealth - damage).clamp(0, 100);
          toRemove.add(enemy);
          
          if (_ipAssetHealth <= 0) {
            _endGame(false);
          }
        }
      }
      
      // Reset slow effect
      enemy.slowFactor = 1.0;
    }
    
    for (var enemy in toRemove) {
      _activeEnemies.remove(enemy);
    }
    
    // Check if wave is complete
    final level = _gameData!['levels'][_currentLevelIndex];
    final waves = level['waves'] as List;
    if (_currentWaveIndex < waves.length) {
      final wave = waves[_currentWaveIndex];
      final enemies = wave['enemies'] as List;
      int totalEnemies = 0;
      for (var enemyData in enemies) {
        totalEnemies += enemyData['count'] as int;
      }
      
      if (_waveInProgress && _activeEnemies.isEmpty && _enemiesSpawned >= totalEnemies) {
        _completeWave();
      }
    }
  }

  void _updateTowers() {
    for (var tower in _placedTowers) {
      tower.cooldown -= 0.05;
      
      if (tower.cooldown <= 0) {
        _towerAttack(tower);
        tower.cooldown = 1.0 / tower.attackSpeed;
      }
    }
  }

  void _towerAttack(Tower tower) {
    Enemy? target;
    double closestDist = double.infinity;
    
    for (var enemy in _activeEnemies) {
      final enemyPos = _getEnemyPosition(enemy);
      final dist = (enemyPos - tower.position).distance;
      
      if (dist <= tower.range * 40 && dist < closestDist) {
        closestDist = dist;
        target = enemy;
      }
    }
    
    if (target != null) {
      // All towers now use projectiles
      _createProjectile(tower, target);
      
      // Apply special effects
      if (tower.specialEffect == 'slow') {
        target.slowFactor = 1.0 - tower.slowAmount;
      }
    }
  }

  void _createProjectile(Tower tower, Enemy target) {
    final projectile = Projectile(
      position: tower.position,
      target: target,
      damage: tower.damage,
      speed: 8.0, // Increased from 5.0 for faster projectiles
      spriteUrl: tower.projectileUrl,
      color: tower.color,
    );
    
    setState(() {
      _activeProjectiles.add(projectile);
    });
  }

  void _areaAttack(Tower tower) {
    // Create a copy of the list to avoid concurrent modification
    final enemiesCopy = List<Enemy>.from(_activeEnemies);
    
    for (var enemy in enemiesCopy) {
      if (!_activeEnemies.contains(enemy)) continue;
      
      final enemyPos = _getEnemyPosition(enemy);
      final dist = (enemyPos - tower.position).distance;
      
      if (dist <= tower.range * 40) {
        enemy.health -= tower.damage;
        
        if (tower.specialEffect == 'slow') {
          enemy.slowFactor = 1.0 - tower.slowAmount;
        }
        
        if (enemy.health <= 0) {
          _killEnemy(enemy);
        }
      }
    }
  }

  void _updateProjectiles() {
    final toRemove = <Projectile>[];
    
    for (var projectile in _activeProjectiles) {
      if (!_activeEnemies.contains(projectile.target)) {
        toRemove.add(projectile);
        continue;
      }
      
      final targetPos = _getEnemyPosition(projectile.target);
      final direction = targetPos - projectile.position;
      final distance = direction.distance;
      
      if (distance < projectile.speed) {
        // Hit target
        projectile.target.health -= projectile.damage;
        
        if (projectile.target.health <= 0) {
          _killEnemy(projectile.target);
        }
        
        toRemove.add(projectile);
      } else {
        projectile.position += Offset(
          direction.dx / distance * projectile.speed,
          direction.dy / distance * projectile.speed,
        );
      }
    }
    
    for (var projectile in toRemove) {
      _activeProjectiles.remove(projectile);
    }
  }

  void _killEnemy(Enemy enemy) {
    setState(() {
      _activeEnemies.remove(enemy);
      _coins += enemy.reward;
      // Score is 2x the reward for killing enemies
      _score += enemy.reward * 2;
      _enemiesKilled++;
    });
  }

  Offset _getEnemyPosition(Enemy enemy) {
    if (enemy.pathIndex >= enemy.pathCoordinates.length - 1) {
      return enemy.pathCoordinates.last;
    }
    
    final start = enemy.pathCoordinates[enemy.pathIndex];
    final end = enemy.pathCoordinates[enemy.pathIndex + 1];
    
    return Offset(
      start.dx + (end.dx - start.dx) * enemy.progress,
      start.dy + (end.dy - start.dy) * enemy.progress,
    );
  }

  void _completeWave() {
    if (!_waveInProgress) return;
    
    final level = _gameData!['levels'][_currentLevelIndex];
    final waves = level['waves'] as List;
    
    if (_currentWaveIndex < waves.length) {
      final wave = waves[_currentWaveIndex];
      final waveReward = (wave['reward'] as num).toInt();
      
      setState(() {
        _waveInProgress = false;
        _coins += waveReward;
        // Wave completion bonus: 3x the wave reward
        _score += waveReward * 3;
        _currentWaveIndex++;
        
        // Check if all waves are complete
        if (_currentWaveIndex >= waves.length) {
          // Level complete!
          _completeLevel();
        }
      });
    }
  }

  void _completeLevel() {
    _endGame(true);
  }

  void _endGame(bool victory) {
    _stopAllTimers();
    
    setState(() {
      _gameEnded = true;
    });
    
    _saveScore(victory);
  }

  Future<void> _saveScore(bool victory) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        const gameId = 'ip_defender';
        final isFirstCompletion = await _gameService.isFirstCompletion(gameId);
        final maxHealth = _gameData!['levels'][_currentLevelIndex]['ipAssetHealth'];
        
        // Calculate final score with multiple bonuses
        int finalScore = _score;
        
        if (victory) {
          // Health preservation bonus: 15 points per remaining health
          final healthBonus = _ipAssetHealth * 15;
          finalScore += healthBonus;
          
          // Coins remaining bonus: 1 point per 2 coins saved
          final coinsBonus = (_coins / 2).floor();
          finalScore += coinsBonus;
          
          // Tower efficiency bonus: fewer towers = higher bonus
          final towerCount = _placedTowers.length;
          int efficiencyBonus = 0;
          if (towerCount <= 3) {
            efficiencyBonus = 300; // Excellent efficiency
          } else if (towerCount <= 5) {
            efficiencyBonus = 150; // Good efficiency
          } else if (towerCount <= 7) {
            efficiencyBonus = 50; // Decent efficiency
          }
          finalScore += efficiencyBonus;
          
          // Perfect health bonus
          if (_ipAssetHealth == maxHealth) {
            finalScore += 500; // Big bonus for perfect defense
          }
          
          // Wave completion bonus (already in _score from waves)
          // Enemy kill bonus (already in _score from kills)
        }
        
        // Calculate XP (capped at 1000-1500 max)
        // Convert score to XP with a scaling factor
        int baseXP = (finalScore * 0.25).round(); // Scale down score to XP
        
        // Cap XP based on performance
        int maxXP = 800; // Base max XP
        if (victory) {
          if (_ipAssetHealth == maxHealth) {
            maxXP = 1500; // Perfect defense
          } else if (_ipAssetHealth >= maxHealth * 0.8) {
            maxXP = 1200; // Excellent defense
          } else if (_ipAssetHealth >= maxHealth * 0.5) {
            maxXP = 1000; // Good defense
          }
        }
        
        final cappedXP = baseXP.clamp(0, maxXP);
        
        // Save progress first (creates the document)
        await _gameService.saveGameProgress(
          gameId: gameId,
          score: finalScore,
          timeSpentSeconds: 0,
          completed: victory,
        );
        
        // Then award XP and check for badges
        final result = await _gameService.awardGameXP(
          gameId: gameId,
          baseXP: cappedXP,
          score: finalScore,
          isPerfectScore: victory && _ipAssetHealth == maxHealth,
          isFirstCompletion: isFirstCompletion,
        );
        
        final newBadges = result['newBadges'] as List<String>;
        
        // Show badge animations if any badges were unlocked
        if (newBadges.isNotEmpty && mounted) {
          await _gameService.showBadgeAnimations(context, newBadges);
        }
        
        // Update displayed score
        setState(() {
          _score = finalScore;
        });
      } catch (e) {
        // Error saving
      }
    }
  }

  void _placeTower(Offset position) {
    if (_selectedTowerType == null || _coins < _selectedTowerType!.cost) return;
    
    // Check if position is valid (not too close to other towers)
    for (var tower in _placedTowers) {
      if ((tower.position - position).distance < 70) {
        return; // Too close to another tower
      }
    }
    
    // Check if not on the path (basic check - should be improved with actual path collision)
    final level = _gameData!['levels'][_currentLevelIndex];
    final pathCoords = level['pathCoordinates'] as List;
    for (int i = 0; i < pathCoords.length - 1; i++) {
      // Scale path coordinates from reference map to actual display size
      final start = Offset(
        (pathCoords[i]['x'] as num).toDouble() * _mapScaleX,
        (pathCoords[i]['y'] as num).toDouble() * _mapScaleY,
      );
      final end = Offset(
        (pathCoords[i + 1]['x'] as num).toDouble() * _mapScaleX,
        (pathCoords[i + 1]['y'] as num).toDouble() * _mapScaleY,
      );
      
      // Check distance to path segment
      final distToPath = _distanceToLineSegment(position, start, end);
      if (distToPath < 40) {
        return; // Too close to path
      }
    }
    
    final newTower = Tower(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedTowerType!.type,
      position: position,
      cost: _selectedTowerType!.cost,
      damage: _selectedTowerType!.damage,
      range: _selectedTowerType!.range,
      attackSpeed: _selectedTowerType!.attackSpeed,
      attackType: _selectedTowerType!.attackType,
      projectileType: _selectedTowerType!.projectileType,
      spriteUrl: _selectedTowerType!.spriteUrl,
      projectileUrl: _selectedTowerType!.projectileUrl,
      color: _selectedTowerType!.color,
      level: 1,
      specialEffect: _selectedTowerType!.specialEffect,
      slowAmount: _selectedTowerType!.slowAmount,
      incomePerSecond: _selectedTowerType!.incomePerSecond,
      cooldown: 0,
    );
    
    setState(() {
      _placedTowers.add(newTower);
      _coins -= _selectedTowerType!.cost;
      _selectedTowerType = null;
    });
  }
  
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final lengthSquared = (lineEnd - lineStart).distanceSquared;
    if (lengthSquared == 0) return (point - lineStart).distance;
    
    final t = ((point - lineStart).dx * (lineEnd - lineStart).dx + 
               (point - lineStart).dy * (lineEnd - lineStart).dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);
    
    final projection = Offset(
      lineStart.dx + clampedT * (lineEnd - lineStart).dx,
      lineStart.dy + clampedT * (lineEnd - lineStart).dy,
    );
    
    return (point - projection).distance;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('IP Defender'),
          backgroundColor: AppDesignSystem.error,
          foregroundColor: Colors.white,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(height: 16),
              LoadingSkeleton(height: 150, borderRadius: BorderRadius.all(Radius.circular(12))),
              SizedBox(height: 16),
              LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12))),
            ],
          ),
        ),
      );
    }

    if (_gameData == null) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('IP Defender'),
          backgroundColor: AppDesignSystem.error,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Failed to load game data')),
      );
    }

    if (!_gameStarted) {
      return _buildLevelSelectScreen();
    }

    if (_gameEnded) {
      return _buildResultScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildLevelSelectScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('IP Defender', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.error,
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
                      color: AppDesignSystem.error.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/logos/ip_defender.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield,
                      size: 50,
                      color: AppDesignSystem.error,
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'IP Defender',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Defend your IP assets from waves of infringers!',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Game rules
              Container(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 8),
                    _buildRuleItem('🏰', 'Build towers to defend your IP assets'),
                    _buildRuleItem('⚔️', 'Survive 5 waves of infringers'),
                    _buildRuleItem('💰', 'Earn coins to upgrade your defenses'),
                    _buildRuleItem('❤️', 'Protect your IP health from reaching zero'),
                  ],
                ),
              ),

              // Adjustable spacing above start button
              const SizedBox(height: 30),

              // Start button
              PrimaryButton(
                text: 'Start Game',
                onPressed: () {
                  setState(() {
                    _currentLevelIndex = 0;
                  });
                  _startGame();
                },
                fullWidth: true,
                icon: Icons.play_arrow,
                color: AppDesignSystem.error,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.3,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    final level = _gameData!['levels'][_currentLevelIndex];
    final waves = level['waves'] as List;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2D5016),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate scale based on reference dimensions
                  final level = _gameData!['levels'][_currentLevelIndex];
                  final refWidth = (level['referenceMapWidth'] as num?)?.toDouble() ?? 830.0;
                  final refHeight = (level['referenceMapHeight'] as num?)?.toDouble() ?? 1248.0;
                  _mapScaleX = constraints.maxWidth / refWidth;
                  _mapScaleY = constraints.maxHeight / refHeight;
                  
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Map background
                      Positioned.fill(
                        child: Image.asset(
                          'assets/maps/game_map.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      // Game area with gesture detection
                      Positioned.fill(
                        child: GestureDetector(
                          onTapUp: (details) {
                            if (_selectedTowerType != null && !_isPaused) {
                              _placeTower(details.localPosition);
                            }
                          },
                          onPanUpdate: (details) {
                            if (_selectedTowerType != null) {
                              setState(() {
                                _dragPosition = details.localPosition;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _dragPosition = null;
                            });
                          },
                          child: CustomPaint(
                            painter: GamePainter(
                              towers: _placedTowers,
                              enemies: _activeEnemies,
                              projectiles: _activeProjectiles,
                              selectedTower: _selectedPlacedTower,
                              dragPosition: _dragPosition,
                              selectedTowerType: _selectedTowerType,
                            ),
                          ),
                        ),
                      ),
                      
                      // Towers
                      ..._placedTowers.map((tower) => _buildTowerWidget(tower)),
                      
                      // Enemies
                      ..._activeEnemies.map((enemy) => _buildEnemyWidget(enemy)),
                      
                      // Projectiles
                      ..._activeProjectiles.map((projectile) => _buildProjectileWidget(projectile)),
                      
                      // Floating Wave Button
                      if (!_waveInProgress && _currentWaveIndex < waves.length && !_isPaused)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: _startWave,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.play_arrow, color: Colors.white, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Start Wave',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Pause overlay
                      if (_isPaused)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pause_circle_outline,
                                      size: 64,
                                      color: Color(0xFF2196F3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Game Paused',
                                      style: AppTextStyles.h2,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPaused = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        'Resume',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final level = _gameData!['levels'][_currentLevelIndex];
    final waves = level['waves'] as List;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            color: AppDesignSystem.error.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Pause button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isPaused 
                        ? [AppDesignSystem.success, AppDesignSystem.success.withValues(alpha: 0.8)]
                        : [Colors.grey.shade700, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPaused ? AppDesignSystem.success : Colors.grey).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildStatChip(Icons.favorite, '$_ipAssetHealth', Colors.red)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildStatChip(Icons.monetization_on, '$_coins', const Color(0xFFFBBF24))),
                    const SizedBox(width: 4),
                    Expanded(child: _buildStatChip(Icons.waves, '${_currentWaveIndex}/${waves.length}', const Color(0xFF2196F3))),
                    const SizedBox(width: 4),
                    Expanded(child: _buildStatChip(Icons.star, '$_score', const Color(0xFFFF9800))),
                  ],
                ),
              ),
            ],
          ),
          

        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final towers = _gameData!['towers'] as List;
    
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: towers.map((towerData) {
          final canAfford = _coins >= towerData['cost'];
          final isSelected = _selectedTowerType?.type == towerData['id'];
          
          return Expanded(
            child: GestureDetector(
            onTap: () {
              if (canAfford) {
                setState(() {
                  _selectedTowerType = isSelected ? null : Tower(
                    id: '',
                    type: towerData['id'],
                    position: Offset.zero,
                    cost: towerData['cost'],
                    damage: (towerData['damage'] as num).toDouble(),
                    range: (towerData['range'] as num).toDouble(),
                    attackSpeed: (towerData['attackSpeed'] as num).toDouble(),
                    attackType: towerData['attackType'],
                    projectileType: towerData['projectileType'],
                    spriteUrl: towerData['spriteUrl'],
                    projectileUrl: towerData['projectileUrl'],
                    color: Color(int.parse(towerData['color'].toString().replaceFirst('0x', '0xFF'))),
                    level: 1,
                    specialEffect: towerData['specialEffect'],
                    slowAmount: (towerData['slowAmount'] as num?)?.toDouble() ?? 0.0,
                    incomePerSecond: towerData['incomePerSecond'] ?? 0,
                    cooldown: 0,
                  );
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: canAfford 
                            ? [Colors.white, Colors.grey.shade100]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF2196F3)
                      : (canAfford ? Colors.grey.shade300 : Colors.red.shade300),
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 2 : 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${towerData['spriteUrl']}',
                    width: 28,
                    height: 28,
                    color: isSelected 
                        ? Colors.white
                        : (canAfford ? null : Colors.grey),
                    colorBlendMode: isSelected || !canAfford ? BlendMode.srcIn : null,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: canAfford 
                          ? const Color(0xFFFBBF24).withValues(alpha: isSelected ? 0.3 : 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 10,
                          color: canAfford ? const Color(0xFFF59E0B) : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${towerData['cost']}',
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white
                                : (canAfford ? const Color(0xFFF59E0B) : Colors.red),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTowerWidget(Tower tower) {
    return Positioned(
      left: tower.position.dx - 35,
      top: tower.position.dy - 35,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlacedTower = _selectedPlacedTower == tower ? null : tower;
          });
        },
        child: Container(
          width: 90,
          height: 90,
          decoration: _selectedPlacedTower == tower
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFBBF24),
                    width: 3,
                  ),
                )
              : null,
          child: Image.asset(
            'assets/${tower.spriteUrl}',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildEnemyWidget(Enemy enemy) {
    final pos = _getEnemyPosition(enemy);
    final healthPercent = enemy.health / enemy.maxHealth;
    final displaySize = enemy.size * 2.0; 
    
    return Positioned(
      left: pos.dx - displaySize / 2,
      top: pos.dy - displaySize / 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: displaySize,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: healthPercent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: healthPercent > 0.5 
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : (healthPercent > 0.25 
                            ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)]),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Image.asset(
            'assets/${enemy.spriteUrl}',
            width: displaySize,
            height: displaySize,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectileWidget(Projectile projectile) {
    return Positioned(
      left: projectile.position.dx - 10,
      top: projectile.position.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: projectile.color.withValues(alpha: 0.3),
          boxShadow: [
            BoxShadow(
              color: projectile.color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/${projectile.spriteUrl}',
            width: 14,
            height: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final victory = _ipAssetHealth > 0;
    final maxHealth = _gameData!['levels'][_currentLevelIndex]['ipAssetHealth'];
    final isPerfect = victory && _ipAssetHealth == maxHealth;
    final healthPercent = (_ipAssetHealth / maxHealth * 100).round();
    
    // Trigger confetti when result screen is shown
    if (victory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playConfettiMultipleTimes();
      });
    }
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.error,
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
                              colors: isPerfect
                                  ? [
                                      AppDesignSystem.error,
                                      AppDesignSystem.error.withOpacity(0.7),
                                    ]
                                  : victory
                                      ? [
                                          AppDesignSystem.success,
                                          AppDesignSystem.success.withOpacity(0.7),
                                        ]
                                      : [
                                          Colors.orange,
                                          Colors.orange.withOpacity(0.7),
                                        ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isPerfect
                                        ? AppDesignSystem.error
                                        : victory
                                            ? AppDesignSystem.success
                                            : Colors.orange)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPerfect
                                ? Icons.emoji_events
                                : victory
                                    ? Icons.check_circle
                                    : Icons.refresh,
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
                                isPerfect
                                    ? 'Perfect Defense!'
                                    : victory
                                        ? 'Victory!'
                                        : 'Defeated!',
                                style: AppTextStyles.h1.copyWith(
                                  color: isPerfect
                                      ? AppDesignSystem.error
                                      : victory
                                          ? AppDesignSystem.success
                                          : Colors.orange,
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  victory ? 'Level Complete!' : 'Your IP assets were compromised!',
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
                                  AppDesignSystem.error.withOpacity(0.2),
                                  AppDesignSystem.error.withOpacity(0.1),
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
                                    color: AppDesignSystem.error.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildFancyStatRow(
                                    Icons.military_tech,
                                    'Final Score',
                                    '$_score',
                                    AppDesignSystem.error,
                                    isHighlight: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.favorite,
                                    'Health',
                                    '$_ipAssetHealth / $maxHealth ($healthPercent%)',
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.waves,
                                    'Waves',
                                    '$_currentWaveIndex / ${(_gameData!['levels'][_currentLevelIndex]['waves'] as List).length}',
                                    const Color(0xFF2196F3),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.shield,
                                    'Enemies Defeated',
                                    '$_enemiesKilled',
                                    const Color(0xFF9C27B0),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.account_balance,
                                    'Towers Built',
                                    '${_placedTowers.length}',
                                    const Color(0xFF4CAF50),
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
                              onPressed: () {
                                setState(() {
                                  _gameEnded = false;
                                  _gameStarted = false;
                                });
                              },
                              fullWidth: true,
                              icon: Icons.refresh,
                              color: AppDesignSystem.error,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppDesignSystem.error, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Back to Games',
                                  style: TextStyle(color: AppDesignSystem.error),
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
          if (victory)
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
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
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

// Game Painter for drawing ranges and effects
class GamePainter extends CustomPainter {
  final List<Tower> towers;
  final List<Enemy> enemies;
  final List<Projectile> projectiles;
  final Tower? selectedTower;
  final Offset? dragPosition;
  final Tower? selectedTowerType;

  GamePainter({
    required this.towers,
    required this.enemies,
    required this.projectiles,
    this.selectedTower,
    this.dragPosition,
    this.selectedTowerType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw selected tower range
    if (selectedTower != null) {
      final paint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = const Color(0xFF2196F3).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        selectedTower!.position,
        selectedTower!.range * 40,
        paint,
      );
      
      canvas.drawCircle(
        selectedTower!.position,
        selectedTower!.range * 40,
        borderPaint,
      );
    }
    
    // Draw drag position range
    if (dragPosition != null && selectedTowerType != null) {
      final paint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawCircle(
        dragPosition!,
        selectedTowerType!.range * 40,
        paint,
      );
      
      canvas.drawCircle(
        dragPosition!,
        selectedTowerType!.range * 40,
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Models
class Tower {
  final String id;
  final String type;
  Offset position;
  final int cost;
  double damage;
  double range;
  double attackSpeed;
  final String attackType;
  final String projectileType;
  final String spriteUrl;
  final String projectileUrl;
  final Color color;
  int level;
  final String? specialEffect;
  double slowAmount;
  int incomePerSecond;
  double cooldown;

  Tower({
    required this.id,
    required this.type,
    required this.position,
    required this.cost,
    required this.damage,
    required this.range,
    required this.attackSpeed,
    required this.attackType,
    required this.projectileType,
    required this.spriteUrl,
    required this.projectileUrl,
    required this.color,
    required this.level,
    this.specialEffect,
    required this.slowAmount,
    required this.incomePerSecond,
    required this.cooldown,
  });
}

class Enemy {
  final String id;
  final String type;
  double health;
  final double maxHealth;
  final double speed;
  final int reward;
  final String spriteUrl;
  final Color color;
  final double size;
  int pathIndex;
  double progress;
  final List<Offset> pathCoordinates;
  double slowFactor;

  Enemy({
    required this.id,
    required this.type,
    required this.health,
    required this.maxHealth,
    required this.speed,
    required this.reward,
    required this.spriteUrl,
    required this.color,
    required this.size,
    required this.pathIndex,
    required this.progress,
    required this.pathCoordinates,
    this.slowFactor = 1.0,
  });
}

class Projectile {
  Offset position;
  final Enemy target;
  final double damage;
  final double speed;
  final String spriteUrl;
  final Color color;

  Projectile({
    required this.position,
    required this.target,
    required this.damage,
    required this.speed,
    required this.spriteUrl,
    required this.color,
  });
}
