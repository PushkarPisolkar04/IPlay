import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Geographic coordinates model
class GeoCoordinates {
  final double lat;
  final double lng;

  GeoCoordinates({required this.lat, required this.lng});

  factory GeoCoordinates.fromJson(Map<String, dynamic> json) {
    return GeoCoordinates(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

/// GI Product model
class GIProduct {
  final String id;
  final String name;
  final String state;
  final String stateCode;
  final GeoCoordinates coordinates;
  final String category;
  final String imageUrl;
  final String description;
  final int registrationYear;
  final List<String> uniqueCharacteristics;
  final String hint;
  final String difficulty;
  final int points;

  GIProduct({
    required this.id,
    required this.name,
    required this.state,
    required this.stateCode,
    required this.coordinates,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.registrationYear,
    required this.uniqueCharacteristics,
    required this.hint,
    required this.difficulty,
    required this.points,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) throw ArgumentError('GI product id cannot be empty');
    if (name.isEmpty) throw ArgumentError('GI product name cannot be empty');
    if (state.isEmpty) throw ArgumentError('State cannot be empty');
    if (stateCode.isEmpty) throw ArgumentError('State code cannot be empty');
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  factory GIProduct.fromJson(Map<String, dynamic> json) {
    return GIProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String,
      stateCode: json['stateCode'] as String,
      coordinates: GeoCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      registrationYear: json['registrationYear'] as int,
      uniqueCharacteristics: List<String>.from(json['uniqueCharacteristics'] as List),
      hint: json['hint'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'stateCode': stateCode,
      'coordinates': coordinates.toJson(),
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'registrationYear': registrationYear,
      'uniqueCharacteristics': uniqueCharacteristics,
      'hint': hint,
      'difficulty': difficulty,
      'points': points,
    };
  }
}

/// State data for India map
class StateData {
  final String code;
  final String name;
  final String svgPath;
  final Color color;

  StateData({
    required this.code,
    required this.name,
    required this.svgPath,
    required this.color,
  });

  factory StateData.fromJson(Map<String, dynamic> json) {
    return StateData(
      code: json['code'] as String,
      name: json['name'] as String,
      svgPath: json['svgPath'] as String? ?? '', // Allow null, default to empty string
      color: Color(int.parse(json['color'] as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'svgPath': svgPath,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    };
  }
}

/// India map data model
class IndiaMapData {
  final List<StateData> states;
  final String? mapSvgUrl;

  IndiaMapData({
    required this.states,
    this.mapSvgUrl,
  });

  /// Get state by code
  StateData? getStateByCode(String code) {
    try {
      return states.firstWhere(
        (s) => s.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get state by name
  StateData? getStateByName(String name) {
    try {
      return states.firstWhere(
        (s) => s.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  factory IndiaMapData.fromJson(Map<String, dynamic> json) {
    return IndiaMapData(
      states: (json['states'] as List)
          .map((s) => StateData.fromJson(s as Map<String, dynamic>))
          .toList(),
      mapSvgUrl: json['mapSvgUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'states': states.map((s) => s.toJson()).toList(),
      if (mapSvgUrl != null) 'mapSvgUrl': mapSvgUrl,
    };
  }
}

/// GI Mapper game model
class GIMapperGame extends GameModel {
  final List<GIProduct> giProducts;
  final IndiaMapData mapData;
  final int pairsPerGame;
  final int? timeLimit;
  final bool randomSelection;
  final bool showHintsAfterWrongAnswer;

  GIMapperGame({
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
    required this.giProducts,
    required this.mapData,
    required this.pairsPerGame,
    this.timeLimit,
    this.randomSelection = true,
    this.showHintsAfterWrongAnswer = true,
  }) {
    _validate();
  }

  void _validate() {
    if (giProducts.isEmpty) {
      throw ArgumentError('GI products cannot be empty');
    }
    if (mapData.states.isEmpty) {
      throw ArgumentError('Map data states cannot be empty');
    }
    if (pairsPerGame <= 0) {
      throw ArgumentError('Pairs per game must be positive');
    }
    if (pairsPerGame > giProducts.length) {
      throw ArgumentError('Pairs per game exceeds available GI products');
    }
  }

  /// Select random GI products for a game session
  List<GIProduct> selectRandomProducts() {
    if (!randomSelection) {
      return giProducts.take(pairsPerGame).toList();
    }

    final random = Random();
    final shuffled = List<GIProduct>.from(giProducts)..shuffle(random);
    return shuffled.take(pairsPerGame).toList();
  }

  /// Get products by state
  List<GIProduct> getProductsByState(String state) {
    return giProducts
        .where((p) => p.state.toLowerCase() == state.toLowerCase())
        .toList();
  }

  /// Get products by category
  List<GIProduct> getProductsByCategory(String category) {
    return giProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get products by difficulty
  List<GIProduct> getProductsByDifficulty(String difficulty) {
    return giProducts
        .where((p) => p.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  factory GIMapperGame.fromJson(Map<String, dynamic> json) {
    return GIMapperGame(
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
      giProducts: (json['giProducts'] as List)
          .map((p) => GIProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      mapData: IndiaMapData.fromJson(json['mapData'] as Map<String, dynamic>),
      pairsPerGame: json['pairsPerGame'] as int,
      timeLimit: json['timeLimit'] as int?,
      randomSelection: json['randomSelection'] as bool? ?? true,
      showHintsAfterWrongAnswer: json['showHintsAfterWrongAnswer'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'giProducts': giProducts.map((p) => p.toJson()).toList(),
      'mapData': mapData.toJson(),
      'pairsPerGame': pairsPerGame,
      if (timeLimit != null) 'timeLimit': timeLimit,
      'randomSelection': randomSelection,
      'showHintsAfterWrongAnswer': showHintsAfterWrongAnswer,
    };
  }
}
