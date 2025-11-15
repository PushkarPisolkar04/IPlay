import 'package:flutter/material.dart';
import 'game_model.dart';

/// Coordinate model for positions
class Coordinate {
  final double x;
  final double y;

  Coordinate({required this.x, required this.y});

  factory Coordinate.fromJson(dynamic json) {
    if (json is List) {
      return Coordinate(
        x: (json[0] as num).toDouble(),
        y: (json[1] as num).toDouble(),
      );
    } else if (json is Map<String, dynamic>) {
      return Coordinate(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );
    }
    throw ArgumentError('Invalid coordinate format');
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// Tower upgrade model
class TowerUpgrade {
  final int level;
  final int cost;
  final int damage;
  final double range;
  final double attackSpeed;
  final double? slowAmount;
  final int? incomePerSecond;

  TowerUpgrade({
    required this.level,
    required this.cost,
    required this.damage,
    required this.range,
    required this.attackSpeed,
    this.slowAmount,
    this.incomePerSecond,
  });

  factory TowerUpgrade.fromJson(Map<String, dynamic> json) {
    return TowerUpgrade(
      level: json['level'] as int,
      cost: json['cost'] as int,
      damage: json['damage'] as int,
      range: (json['range'] as num).toDouble(),
      attackSpeed: (json['attackSpeed'] as num).toDouble(),
      slowAmount: json['slowAmount'] != null ? (json['slowAmount'] as num).toDouble() : null,
      incomePerSecond: json['incomePerSecond'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'cost': cost,
      'damage': damage,
      'range': range,
      'attackSpeed': attackSpeed,
      if (slowAmount != null) 'slowAmount': slowAmount,
      if (incomePerSecond != null) 'incomePerSecond': incomePerSecond,
    };
  }
}

/// Tower model
class Tower {
  final String id;
  final String name;
  final String description;
  final int cost;
  final int damage;
  final double range;
  final double attackSpeed;
  final String attackType;
  final String projectileType;
  final String spriteUrl;
  final String projectileUrl;
  final Color color;
  final String? specialEffect;
  final double? slowAmount;
  final int? incomePerSecond;
  final List<TowerUpgrade> upgrades;

  Tower({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.damage,
    required this.range,
    required this.attackSpeed,
    required this.attackType,
    required this.projectileType,
    required this.spriteUrl,
    required this.projectileUrl,
    required this.color,
    this.specialEffect,
    this.slowAmount,
    this.incomePerSecond,
    required this.upgrades,
  });

  factory Tower.fromJson(Map<String, dynamic> json) {
    return Tower(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cost: json['cost'] as int,
      damage: json['damage'] as int,
      range: (json['range'] as num).toDouble(),
      attackSpeed: (json['attackSpeed'] as num).toDouble(),
      attackType: json['attackType'] as String,
      projectileType: json['projectileType'] as String,
      spriteUrl: json['spriteUrl'] as String,
      projectileUrl: json['projectileUrl'] as String,
      color: Color(int.parse(json['color'] as String)),
      specialEffect: json['specialEffect'] as String?,
      slowAmount: json['slowAmount'] != null ? (json['slowAmount'] as num).toDouble() : null,
      incomePerSecond: json['incomePerSecond'] as int?,
      upgrades: (json['upgrades'] as List)
          .map((u) => TowerUpgrade.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'damage': damage,
      'range': range,
      'attackSpeed': attackSpeed,
      'attackType': attackType,
      'projectileType': projectileType,
      'spriteUrl': spriteUrl,
      'projectileUrl': projectileUrl,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      if (specialEffect != null) 'specialEffect': specialEffect,
      if (slowAmount != null) 'slowAmount': slowAmount,
      if (incomePerSecond != null) 'incomePerSecond': incomePerSecond,
      'upgrades': upgrades.map((u) => u.toJson()).toList(),
    };
  }
}

/// Enemy model
class Enemy {
  final String id;
  final String name;
  final String description;
  final int baseHealth;
  final double baseSpeed;
  final int reward;
  final String spriteUrl;
  final Color color;
  final String? specialAbility;

  Enemy({
    required this.id,
    required this.name,
    required this.description,
    required this.baseHealth,
    required this.baseSpeed,
    required this.reward,
    required this.spriteUrl,
    required this.color,
    this.specialAbility,
  });

  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      baseHealth: json['baseHealth'] as int,
      baseSpeed: (json['baseSpeed'] as num).toDouble(),
      reward: json['reward'] as int,
      spriteUrl: json['spriteUrl'] as String,
      color: Color(int.parse(json['color'] as String)),
      specialAbility: json['specialAbility'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseHealth': baseHealth,
      'baseSpeed': baseSpeed,
      'reward': reward,
      'spriteUrl': spriteUrl,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      if (specialAbility != null) 'specialAbility': specialAbility,
    };
  }
}

/// Wave enemy configuration
class WaveEnemy {
  final String type;
  final int count;
  final int health;
  final double speed;

  WaveEnemy({
    required this.type,
    required this.count,
    required this.health,
    required this.speed,
  });

  factory WaveEnemy.fromJson(Map<String, dynamic> json) {
    return WaveEnemy(
      type: json['type'] as String,
      count: json['count'] as int,
      health: json['health'] as int,
      speed: (json['speed'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'count': count,
      'health': health,
      'speed': speed,
    };
  }
}

/// Wave model
class Wave {
  final int waveNumber;
  final List<WaveEnemy> enemies;
  final int spawnInterval;

  Wave({
    required this.waveNumber,
    required this.enemies,
    required this.spawnInterval,
  });

  factory Wave.fromJson(Map<String, dynamic> json) {
    return Wave(
      waveNumber: json['waveNumber'] as int,
      enemies: (json['enemies'] as List)
          .map((e) => WaveEnemy.fromJson(e as Map<String, dynamic>))
          .toList(),
      spawnInterval: json['spawnInterval'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waveNumber': waveNumber,
      'enemies': enemies.map((e) => e.toJson()).toList(),
      'spawnInterval': spawnInterval,
    };
  }
}

/// Tower defense level model
class TowerDefenseLevel {
  final int levelNumber;
  final String? name;
  final String? description;
  final String? difficulty;
  final List<Wave> waves;
  final int startingCoins;
  final List<Coordinate> pathCoordinates;
  final int ipAssetHealth;
  final String? mapLayout;

  TowerDefenseLevel({
    required this.levelNumber,
    this.name,
    this.description,
    this.difficulty,
    required this.waves,
    required this.startingCoins,
    required this.pathCoordinates,
    required this.ipAssetHealth,
    this.mapLayout,
  });

  factory TowerDefenseLevel.fromJson(Map<String, dynamic> json) {
    return TowerDefenseLevel(
      levelNumber: json['levelNumber'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      waves: (json['waves'] as List)
          .map((w) => Wave.fromJson(w as Map<String, dynamic>))
          .toList(),
      startingCoins: json['startingCoins'] as int,
      pathCoordinates: (json['pathCoordinates'] as List)
          .map((c) => Coordinate.fromJson(c))
          .toList(),
      ipAssetHealth: json['ipAssetHealth'] as int,
      mapLayout: json['mapLayout'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (difficulty != null) 'difficulty': difficulty,
      'waves': waves.map((w) => w.toJson()).toList(),
      'startingCoins': startingCoins,
      'pathCoordinates': pathCoordinates.map((c) => c.toJson()).toList(),
      'ipAssetHealth': ipAssetHealth,
      if (mapLayout != null) 'mapLayout': mapLayout,
    };
  }
}

/// IP Defender game model
class IPDefenderGame extends GameModel {
  final List<Tower> towers;
  final List<Enemy> enemies;
  final List<TowerDefenseLevel> levels;

  IPDefenderGame({
    required super.id,
    required super.name,
    required super.description,
    required super.summary,
    required super.iconPath,
    required super.color,
    required super.difficulty,
    required super.gameType,
    required super.xpReward,
    required super.estimatedMinutes,
    required super.rewards,
    required super.leaderboard,
    required super.version,
    required super.updatedAt,
    super.allowRetry,
    required this.towers,
    required this.enemies,
    required this.levels,
  }) {
    _validate();
  }

  void _validate() {
    if (towers.isEmpty) throw ArgumentError('Towers cannot be empty');
    if (enemies.isEmpty) throw ArgumentError('Enemies cannot be empty');
    if (levels.isEmpty) throw ArgumentError('Levels cannot be empty');
  }

  factory IPDefenderGame.fromJson(Map<String, dynamic> json) {
    return IPDefenderGame(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      summary: json['summary'] as String? ?? json['description'] as String,
      iconPath: json['iconPath'] as String,
      color: Color(int.parse(json['color'] as String)),
      difficulty: json['difficulty'] as String,
      gameType: json['gameType'] as String,
      xpReward: json['xpReward'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      rewards: GameRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      leaderboard: LeaderboardConfig.fromJson(json['leaderboard'] as Map<String, dynamic>),
      version: json['version'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      allowRetry: json['allowRetry'] as bool? ?? true,
      towers: (json['towers'] as List)
          .map((t) => Tower.fromJson(t as Map<String, dynamic>))
          .toList(),
      enemies: (json['enemies'] as List)
          .map((e) => Enemy.fromJson(e as Map<String, dynamic>))
          .toList(),
      levels: (json['levels'] as List)
          .map((l) => TowerDefenseLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'towers': towers.map((t) => t.toJson()).toList(),
      'enemies': enemies.map((e) => e.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
    };
  }
}
