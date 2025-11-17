import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/game_integration_service.dart';
import '../../widgets/primary_button.dart';

/// IP Defender - Tower Defense Game
class IPDefenderGame extends StatefulWidget {
  const IPDefenderGame({super.key});

  @override
  State<IPDefenderGame> createState() => _IPDefenderGameState();
}

class _IPDefenderGameState extends State<IPDefenderGame> with TickerProviderStateMixin {
  final GameIntegrationService _gameService = GameIntegrationService();
  
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

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _stopAllTimers();
    super.dispose();
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
      if (_isPaused || _gameEnded) return;
      
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
      pathCoordinates: pathCoords.map((c) => Offset(c['x'].toDouble(), c['y'].toDouble())).toList(),
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
          // Enemy reached the end
          _ipAssetHealth -= 10;
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
      if (tower.attackType == 'single') {
        _createProjectile(tower, target);
      } else if (tower.attackType == 'area') {
        _areaAttack(tower);
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
      _score += enemy.reward;
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
      
      setState(() {
        _waveInProgress = false;
        _coins += (wave['reward'] as num).toInt();
        _score += (wave['reward'] as num).toInt();
        _currentWaveIndex++;
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
        
        await _gameService.awardGameXP(
          gameId: gameId,
          baseXP: _score,
          score: _score,
          isPerfectScore: victory && _ipAssetHealth == (_gameData!['levels'][_currentLevelIndex]['ipAssetHealth']),
          isFirstCompletion: isFirstCompletion,
        );
        
        await _gameService.saveGameProgress(
          gameId: gameId,
          score: _score,
          timeSpentSeconds: 0,
          completed: victory,
        );
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
      final start = Offset(pathCoords[i]['x'].toDouble(), pathCoords[i]['y'].toDouble());
      final end = Offset(pathCoords[i + 1]['x'].toDouble(), pathCoords[i + 1]['y'].toDouble());
      
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
        body: const Center(child: CircularProgressIndicator()),
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
    final levels = _gameData!['levels'] as List;
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('IP Defender', style: TextStyle(color: Colors.white)),
        backgroundColor: AppDesignSystem.error,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppDesignSystem.error.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/logos/ip_defender.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.shield, size: 60, color: AppDesignSystem.error);
                  },
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text('Select Level', style: AppTextStyles.h2),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                'Tower Defense: Protect your IP assets!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              ...List.generate(levels.length, (index) {
                final level = levels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildLevelCard(level, index),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentLevelIndex = index;
        });
        _startGame();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppDesignSystem.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppDesignSystem.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${level['levelNumber']}',
                  style: AppTextStyles.h3.copyWith(color: AppDesignSystem.error),
                ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level['name'], style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    level['description'],
                    style: AppTextStyles.caption.copyWith(color: AppDesignSystem.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.waves, size: 14, color: AppDesignSystem.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${(level['waves'] as List).length} waves',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.monetization_on, size: 14, color: AppDesignSystem.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${level['startingCoins']} coins',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Icon(Icons.play_arrow, color: AppDesignSystem.error),
          ],
        ),
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
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Map background
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF4A7C2C),
                          child: SvgPicture.asset(
                            'assets/maps/game_map.svg',
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: 0.9),
                              BlendMode.modulate,
                            ),
                          ),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(Icons.favorite, '$_ipAssetHealth', Colors.red),
                      const SizedBox(width: 6),
                      _buildStatChip(Icons.monetization_on, '$_coins', const Color(0xFFFBBF24)),
                      const SizedBox(width: 6),
                      _buildStatChip(Icons.waves, '${_currentWaveIndex}/${waves.length}', const Color(0xFF2196F3)),
                      const SizedBox(width: 6),
                      _buildStatChip(Icons.star, '$_score', const Color(0xFFFF9800)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              if (!_waveInProgress && _currentWaveIndex < waves.length)
                Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _startWave,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Wave',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final towers = _gameData!['towers'] as List;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: towers.map((towerData) {
            final canAfford = _coins >= towerData['cost'];
            final isSelected = _selectedTowerType?.type == towerData['id'];
            
            return GestureDetector(
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
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF2196F3)
                        : (canAfford ? Colors.grey.shade300 : Colors.red.shade300),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: isSelected ? 12 : 6,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      towerData['spriteUrl'],
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        isSelected 
                            ? Colors.white
                            : (canAfford ? Color(int.parse(towerData['color'].toString().replaceFirst('0x', '0xFF'))) : Colors.grey),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: canAfford 
                            ? const Color(0xFFFBBF24).withValues(alpha: isSelected ? 0.3 : 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 12,
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
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTowerWidget(Tower tower) {
    return Positioned(
      left: tower.position.dx - 30,
      top: tower.position.dy - 30,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlacedTower = _selectedPlacedTower == tower ? null : tower;
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: _selectedPlacedTower == tower ? const Color(0xFFFBBF24) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset(
            tower.spriteUrl,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              tower.color,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnemyWidget(Enemy enemy) {
    final pos = _getEnemyPosition(enemy);
    final healthPercent = enemy.health / enemy.maxHealth;
    final displaySize = enemy.size * 1.5; // Increase enemy size by 50%
    
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SvgPicture.asset(
              enemy.spriteUrl,
              width: displaySize - 8,
              height: displaySize - 8,
              colorFilter: ColorFilter.mode(enemy.color, BlendMode.srcIn),
            ),
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
          child: SvgPicture.asset(
            projectile.spriteUrl,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(projectile.color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final victory = _ipAssetHealth > 0;
    
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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: victory ? AppDesignSystem.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  victory ? Icons.emoji_events : Icons.shield_outlined,
                  size: 60,
                  color: victory ? AppDesignSystem.success : Colors.orange,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                victory ? 'Victory!' : 'Defeated!',
                style: AppTextStyles.h1,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Text(
                victory ? 'Level Complete!' : 'Your IP assets were compromised!',
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
                    _buildStatRow('Final Score', _score.toString()),
                    const Divider(height: 24),
                    _buildStatRow('Enemies Defeated', _enemiesKilled.toString()),
                    const Divider(height: 24),
                    _buildStatRow('Health Remaining', '$_ipAssetHealth'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '+$_score XP', isHighlight: true),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
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

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary),
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
