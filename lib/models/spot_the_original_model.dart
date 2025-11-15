import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Product image model
class ProductImage {
  final String url;
  final bool isOriginal;
  final String label;
  final List<String>? differences;

  ProductImage({
    required this.url,
    required this.isOriginal,
    required this.label,
    this.differences,
  }) {
    _validate();
  }

  void _validate() {
    if (url.isEmpty) throw ArgumentError('Image URL cannot be empty');
    if (label.isEmpty) throw ArgumentError('Label cannot be empty');
    if (!isOriginal && (differences == null || differences!.isEmpty)) {
      throw ArgumentError('Counterfeit images must have differences listed');
    }
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String,
      isOriginal: json['isOriginal'] as bool,
      label: json['label'] as String,
      differences: json['differences'] != null
          ? List<String>.from(json['differences'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'isOriginal': isOriginal,
      'label': label,
      if (differences != null) 'differences': differences,
    };
  }
}

/// Educational information model
class EducationalInfo {
  final String brandHistory;
  final String trademarkInfo;
  final List<String> identificationTips;

  EducationalInfo({
    required this.brandHistory,
    required this.trademarkInfo,
    required this.identificationTips,
  });

  factory EducationalInfo.fromJson(Map<String, dynamic> json) {
    return EducationalInfo(
      brandHistory: json['brandHistory'] as String,
      trademarkInfo: json['trademarkInfo'] as String,
      identificationTips: List<String>.from(json['identificationTips'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandHistory': brandHistory,
      'trademarkInfo': trademarkInfo,
      'identificationTips': identificationTips,
    };
  }
}

/// Product set model
class ProductSet {
  final String id;
  final String productName;
  final String category;
  final List<ProductImage> images;
  final EducationalInfo educationalInfo;
  final String difficulty;
  final int points;

  ProductSet({
    required this.id,
    required this.productName,
    required this.category,
    required this.images,
    required this.educationalInfo,
    required this.difficulty,
    required this.points,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) throw ArgumentError('Product set id cannot be empty');
    if (productName.isEmpty) throw ArgumentError('Product name cannot be empty');
    if (images.length != 4) {
      throw ArgumentError('Product set must have exactly 4 images');
    }
    
    final originalCount = images.where((img) => img.isOriginal).length;
    if (originalCount != 1) {
      throw ArgumentError('Product set must have exactly 1 original image');
    }
    
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  /// Get the original image
  ProductImage get originalImage {
    return images.firstWhere((img) => img.isOriginal);
  }

  /// Get counterfeit images
  List<ProductImage> get counterfeitImages {
    return images.where((img) => !img.isOriginal).toList();
  }

  factory ProductSet.fromJson(Map<String, dynamic> json) {
    return ProductSet(
      id: json['id'] as String,
      productName: json['productName'] as String,
      category: json['category'] as String,
      images: (json['images'] as List)
          .map((img) => ProductImage.fromJson(img as Map<String, dynamic>))
          .toList(),
      educationalInfo: EducationalInfo.fromJson(
        json['educationalInfo'] as Map<String, dynamic>,
      ),
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'images': images.map((img) => img.toJson()).toList(),
      'educationalInfo': educationalInfo.toJson(),
      'difficulty': difficulty,
      'points': points,
    };
  }
}

/// Spot the Original game model
class SpotTheOriginalGame extends GameModel {
  final List<ProductSet> productSets;
  final int comparisonsPerGame;
  final int? timeLimit;
  final bool randomSelection;
  final bool showHintsAfterWrongAnswer;

  SpotTheOriginalGame({
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
    required this.productSets,
    required this.comparisonsPerGame,
    this.timeLimit,
    this.randomSelection = true,
    this.showHintsAfterWrongAnswer = true,
  }) {
    _validate();
  }

  void _validate() {
    if (productSets.isEmpty) {
      throw ArgumentError('Product sets cannot be empty');
    }
    if (comparisonsPerGame <= 0) {
      throw ArgumentError('Comparisons per game must be positive');
    }
    if (comparisonsPerGame > productSets.length) {
      throw ArgumentError('Comparisons per game exceeds available product sets');
    }
  }

  /// Select random product sets for a game session
  List<ProductSet> selectRandomProductSets() {
    if (!randomSelection) {
      return productSets.take(comparisonsPerGame).toList();
    }

    final random = Random();
    final shuffled = List<ProductSet>.from(productSets)..shuffle(random);
    return shuffled.take(comparisonsPerGame).toList();
  }

  /// Get product sets by category
  List<ProductSet> getProductSetsByCategory(String category) {
    return productSets
        .where((ps) => ps.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get product sets by difficulty
  List<ProductSet> getProductSetsByDifficulty(String difficulty) {
    return productSets
        .where((ps) => ps.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  factory SpotTheOriginalGame.fromJson(Map<String, dynamic> json) {
    return SpotTheOriginalGame(
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
      productSets: (json['productSets'] as List)
          .map((ps) => ProductSet.fromJson(ps as Map<String, dynamic>))
          .toList(),
      comparisonsPerGame: json['comparisonsPerGame'] as int,
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
      'productSets': productSets.map((ps) => ps.toJson()).toList(),
      'comparisonsPerGame': comparisonsPerGame,
      if (timeLimit != null) 'timeLimit': timeLimit,
      'randomSelection': randomSelection,
      'showHintsAfterWrongAnswer': showHintsAfterWrongAnswer,
    };
  }
}
