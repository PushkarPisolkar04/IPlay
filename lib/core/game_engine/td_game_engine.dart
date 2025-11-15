import 'dart:math';
import '../../models/ip_defender_model.dart';

/// Represents a placed tower instance in the game
class PlacedTower {
  final String id;
  final Tower towerData;
  final Coordinate gridPosition;
  int level;
  double attackCooldown;
  GameEnemy? currentTarget;

  PlacedTower({
    required this.id,
    required this.towerData,
    required this.gridPosition,
    this.level = 1,
    this.attackCooldown = 0,
    this.currentTarget,
  });

  TowerUpgrade? get currentUpgrade {
    if (level == 1) return null;
    return towerData.upgrades.firstWhere((u) => u.level == level);
  }

  int get damage => currentUpgrade?.damage ?? towerData.damage;
  double get range => currentUpgrade?.range ?? towerData.range;
  double get attackSpeed => currentUpgrade?.attackSpeed ?? towerData.attackSpeed;
  double? get slowAmount => currentUpgrade?.slowAmount ?? towerData.slowAmount;
  int? get incomePerSecond => currentUpgrade?.incomePerSecond ?? towerData.incomePerSecond;

  int getUpgradeCost() {
    if (level >= towerData.upgrades.length + 1) return 0;
    return towerData.upgrades.firstWhere((u) => u.level == level + 1).cost;
  }

  bool canUpgrade() {
    return level < towerData.upgrades.length + 1;
  }
}

/// Represents an enemy instance in the game
class GameEnemy {
  final String id;
  final Enemy enemyData;
  double pathProgress; // 0.0 to 1.0
  int currentHealth;
  double slowEffect; // 0.0 to 1.0 (1.0 = full speed, 0.5 = 50% speed)
  
  GameEnemy({
    required this.id,
    required this.enemyData,
    this.pathProgress = 0.0,
    required this.currentHealth,
    this.slowEffect = 1.0,
  });

  double get effectiveSpeed => enemyData.baseSpeed * slowEffect;
  bool get isDead => currentHealth <= 0;
  bool get reachedEnd => pathProgress >= 1.0;
}

/// Represents a projectile fired by a tower
class Projectile {
  final String id;
  final PlacedTower tower;
  final GameEnemy target;
  Coordinate position;
  final double speed = 5.0;

  Projectile({
    required this.id,
    required this.tower,
    required this.target,
    required this.position,
  });
}


/// Main tower defense game engine
class TDGameEngine {
  final TowerDefenseLevel levelData;
  final List<Tower> availableTowers;
  final List<Enemy> enemyTypes;
  final List<Coordinate> path;
  
  // Game state
  int coins;
  int ipAssetHealth;
  int currentWaveIndex = 0;
  bool isWaveActive = false;
  bool isGameOver = false;
  bool isVictory = false;
  
  // Game objects
  final List<PlacedTower> placedTowers = [];
  final List<GameEnemy> activeEnemies = [];
  final List<Projectile> activeProjectiles = [];
  
  // Spawn tracking
  int enemiesSpawnedInWave = 0;
  int totalEnemiesInWave = 0;
  double spawnCooldown = 0;
  
  // Grid system (10x15 grid)
  static const int gridWidth = 10;
  static const int gridHeight = 15;
  static const double tileSize = 40.0;
  
  TDGameEngine({
    required this.levelData,
    required this.availableTowers,
    required this.enemyTypes,
    required this.path,
  })  : coins = levelData.startingCoins,
        ipAssetHealth = levelData.ipAssetHealth;

  /// Update game state (called every frame)
  void update(double deltaTime) {
    if (isGameOver) return;

    // Update tower cooldowns and income
    for (final tower in placedTowers) {
      if (tower.attackCooldown > 0) {
        tower.attackCooldown -= deltaTime;
      }
      
      // Generate income from trade secret vaults
      if (tower.incomePerSecond != null) {
        coins += (tower.incomePerSecond! * deltaTime).round();
      }
    }

    // Update enemies
    _updateEnemies(deltaTime);

    // Update projectiles
    _updateProjectiles(deltaTime);

    // Tower targeting and attacking
    _updateTowers(deltaTime);

    // Spawn enemies if wave is active
    if (isWaveActive) {
      _updateWaveSpawning(deltaTime);
    }

    // Check win/lose conditions
    _checkGameState();
  }

  void _updateEnemies(double deltaTime) {
    final enemiesToRemove = <GameEnemy>[];
    
    for (final enemy in activeEnemies) {
      // Update position along path
      enemy.pathProgress += enemy.effectiveSpeed * deltaTime * 0.01;
      
      // Reset slow effect (will be reapplied by towers)
      enemy.slowEffect = 1.0;
      
      // Check if reached end
      if (enemy.reachedEnd) {
        ipAssetHealth -= 10;
        enemiesToRemove.add(enemy);
      }
      
      // Check if dead
      if (enemy.isDead) {
        coins += enemy.enemyData.reward;
        enemiesToRemove.add(enemy);
      }
    }
    
    activeEnemies.removeWhere((e) => enemiesToRemove.contains(e));
  }

  void _updateProjectiles(double deltaTime) {
    final projectilesToRemove = <Projectile>[];
    
    for (final projectile in activeProjectiles) {
      // Move projectile towards target
      final targetPos = getEnemyPosition(projectile.target);
      final dx = targetPos.x - projectile.position.x;
      final dy = targetPos.y - projectile.position.y;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance < projectile.speed) {
        // Hit target
        _damageEnemy(projectile.target, projectile.tower.damage);
        
        // Apply slow effect if tower has it
        if (projectile.tower.slowAmount != null) {
          projectile.target.slowEffect = 1.0 - projectile.tower.slowAmount!;
        }
        
        projectilesToRemove.add(projectile);
      } else {
        // Move towards target
        projectile.position = Coordinate(
          x: projectile.position.x + (dx / distance) * projectile.speed,
          y: projectile.position.y + (dy / distance) * projectile.speed,
        );
      }
    }
    
    activeProjectiles.removeWhere((p) => projectilesToRemove.contains(p));
  }

  void _updateTowers(double deltaTime) {
    for (final tower in placedTowers) {
      // Find target if don't have one
      if (tower.currentTarget == null || tower.currentTarget!.isDead || tower.currentTarget!.reachedEnd) {
        tower.currentTarget = _findNearestEnemy(tower);
      }
      
      // Attack if have target and cooldown ready
      if (tower.currentTarget != null && tower.attackCooldown <= 0) {
        final targetPos = getEnemyPosition(tower.currentTarget!);
        final towerPos = gridToWorld(tower.gridPosition);
        final distance = _distance(towerPos, targetPos);
        
        if (distance <= tower.range * tileSize) {
          _fireTower(tower);
          tower.attackCooldown = 1.0 / tower.attackSpeed;
        } else {
          tower.currentTarget = null;
        }
      }
    }
  }

  void _updateWaveSpawning(double deltaTime) {
    if (currentWaveIndex >= levelData.waves.length) return;
    
    final wave = levelData.waves[currentWaveIndex];
    
    if (spawnCooldown > 0) {
      spawnCooldown -= deltaTime;
      return;
    }
    
    if (enemiesSpawnedInWave < totalEnemiesInWave) {
      _spawnNextEnemy(wave);
      spawnCooldown = wave.spawnInterval / 1000.0; // Convert ms to seconds
      enemiesSpawnedInWave++;
    } else if (activeEnemies.isEmpty) {
      // Wave complete
      _completeWave();
    }
  }

  void _spawnNextEnemy(Wave wave) {
    // Determine which enemy type to spawn
    int currentCount = 0;
    for (final waveEnemy in wave.enemies) {
      if (enemiesSpawnedInWave >= currentCount && enemiesSpawnedInWave < currentCount + waveEnemy.count) {
        final enemyData = enemyTypes.firstWhere((e) => e.id == waveEnemy.type);
        final enemy = GameEnemy(
          id: '${DateTime.now().millisecondsSinceEpoch}_$enemiesSpawnedInWave',
          enemyData: enemyData,
          currentHealth: waveEnemy.health,
        );
        activeEnemies.add(enemy);
        return;
      }
      currentCount += waveEnemy.count;
    }
  }

  GameEnemy? _findNearestEnemy(PlacedTower tower) {
    final towerPos = gridToWorld(tower.gridPosition);
    GameEnemy? nearest;
    double nearestDist = double.infinity;
    
    for (final enemy in activeEnemies) {
      if (enemy.isDead || enemy.reachedEnd) continue;
      
      final enemyPos = getEnemyPosition(enemy);
      final dist = _distance(towerPos, enemyPos);
      
      if (dist <= tower.range * tileSize && dist < nearestDist) {
        nearest = enemy;
        nearestDist = dist;
      }
    }
    
    return nearest;
  }

  void _fireTower(PlacedTower tower) {
    if (tower.currentTarget == null) return;
    
    final projectile = Projectile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tower: tower,
      target: tower.currentTarget!,
      position: gridToWorld(tower.gridPosition),
    );
    
    activeProjectiles.add(projectile);
  }

  void _damageEnemy(GameEnemy enemy, int damage) {
    enemy.currentHealth -= damage;
  }

  void _completeWave() {
    isWaveActive = false;
    enemiesSpawnedInWave = 0;
    totalEnemiesInWave = 0;
  }

  void _checkGameState() {
    if (ipAssetHealth <= 0) {
      isGameOver = true;
      isVictory = false;
    } else if (currentWaveIndex >= levelData.waves.length && activeEnemies.isEmpty && !isWaveActive) {
      isGameOver = true;
      isVictory = true;
    }
  }

  /// Start the next wave
  void startNextWave() {
    if (currentWaveIndex >= levelData.waves.length) return;
    
    final wave = levelData.waves[currentWaveIndex];
    totalEnemiesInWave = wave.enemies.fold(0, (sum, e) => sum + e.count);
    enemiesSpawnedInWave = 0;
    spawnCooldown = 0;
    isWaveActive = true;
    currentWaveIndex++;
  }

  /// Place a tower at grid position
  bool placeTower(Tower towerData, Coordinate gridPos) {
    // Check if can afford
    if (coins < towerData.cost) return false;
    
    // Check if position is valid (not on path, not occupied)
    if (!isValidTowerPosition(gridPos)) return false;
    
    // Place tower
    final tower = PlacedTower(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      towerData: towerData,
      gridPosition: gridPos,
    );
    
    placedTowers.add(tower);
    coins -= towerData.cost;
    return true;
  }

  /// Upgrade a tower
  bool upgradeTower(PlacedTower tower) {
    if (!tower.canUpgrade()) return false;
    
    final cost = tower.getUpgradeCost();
    if (coins < cost) return false;
    
    tower.level++;
    coins -= cost;
    return true;
  }

  /// Sell a tower
  void sellTower(PlacedTower tower) {
    placedTowers.remove(tower);
    // Refund 70% of total cost
    int totalCost = tower.towerData.cost;
    for (int i = 2; i <= tower.level; i++) {
      totalCost += tower.towerData.upgrades.firstWhere((u) => u.level == i).cost;
    }
    coins += (totalCost * 0.7).round();
  }

  /// Check if a grid position is valid for tower placement
  bool isValidTowerPosition(Coordinate gridPos) {
    // Check bounds
    if (gridPos.x < 0 || gridPos.x >= gridWidth || gridPos.y < 0 || gridPos.y >= gridHeight) {
      return false;
    }
    
    // Check if already occupied
    for (final tower in placedTowers) {
      if (tower.gridPosition.x == gridPos.x && tower.gridPosition.y == gridPos.y) {
        return false;
      }
    }
    
    // Check if on path (simplified - just check if too close to path)
    final worldPos = gridToWorld(gridPos);
    for (final pathPoint in path) {
      if (_distance(worldPos, pathPoint) < tileSize * 0.8) {
        return false;
      }
    }
    
    return true;
  }

  /// Convert grid coordinates to world coordinates
  Coordinate gridToWorld(Coordinate gridPos) {
    return Coordinate(
      x: gridPos.x * tileSize + tileSize / 2,
      y: gridPos.y * tileSize + tileSize / 2,
    );
  }

  /// Convert world coordinates to grid coordinates
  Coordinate worldToGrid(Coordinate worldPos) {
    return Coordinate(
      x: (worldPos.x / tileSize).floor().toDouble(),
      y: (worldPos.y / tileSize).floor().toDouble(),
    );
  }

  /// Get enemy position along path
  Coordinate getEnemyPosition(GameEnemy enemy) {
    if (path.isEmpty) return Coordinate(x: 0, y: 0);
    
    final totalSegments = path.length - 1;
    final segmentProgress = enemy.pathProgress * totalSegments;
    final segmentIndex = segmentProgress.floor().clamp(0, totalSegments - 1);
    final segmentFraction = segmentProgress - segmentIndex;
    
    final start = path[segmentIndex];
    final end = path[min(segmentIndex + 1, path.length - 1)];
    
    return Coordinate(
      x: start.x + (end.x - start.x) * segmentFraction,
      y: start.y + (end.y - start.y) * segmentFraction,
    );
  }

  double _distance(Coordinate a, Coordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}
