import 'dart:math';
import 'package:flutter/material.dart';
import 'game_model.dart';

/// Drawing tool model
class DrawingTool {
  final String id;
  final String name;
  final String icon;
  final String type;
  final List<int> strokeWidthRange;
  final int defaultStrokeWidth;
  final bool supportsOpacity;
  final bool supportsColor;
  final bool? supportsFill;
  final int? minSides;
  final int? maxSides;
  final List<int>? fontSizeRange;
  final int? defaultFontSize;
  final bool? supportsBold;
  final bool? supportsItalic;

  DrawingTool({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.strokeWidthRange,
    required this.defaultStrokeWidth,
    required this.supportsOpacity,
    required this.supportsColor,
    this.supportsFill,
    this.minSides,
    this.maxSides,
    this.fontSizeRange,
    this.defaultFontSize,
    this.supportsBold,
    this.supportsItalic,
  });

  factory DrawingTool.fromJson(Map<String, dynamic> json) {
    return DrawingTool(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
      strokeWidthRange: json['strokeWidthRange'] != null ? List<int>.from(json['strokeWidthRange'] as List) : [1, 10],
      defaultStrokeWidth: json['defaultStrokeWidth'] as int? ?? 2,
      supportsOpacity: json['supportsOpacity'] as bool? ?? true,
      supportsColor: json['supportsColor'] as bool? ?? true,
      supportsFill: json['supportsFill'] as bool?,
      minSides: json['minSides'] as int?,
      maxSides: json['maxSides'] as int?,
      fontSizeRange: json['fontSizeRange'] != null
          ? List<int>.from(json['fontSizeRange'] as List)
          : null,
      defaultFontSize: json['defaultFontSize'] as int?,
      supportsBold: json['supportsBold'] as bool?,
      supportsItalic: json['supportsItalic'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'strokeWidthRange': strokeWidthRange,
      'defaultStrokeWidth': defaultStrokeWidth,
      'supportsOpacity': supportsOpacity,
      'supportsColor': supportsColor,
      if (supportsFill != null) 'supportsFill': supportsFill,
      if (minSides != null) 'minSides': minSides,
      if (maxSides != null) 'maxSides': maxSides,
      if (fontSizeRange != null) 'fontSizeRange': fontSizeRange,
      if (defaultFontSize != null) 'defaultFontSize': defaultFontSize,
      if (supportsBold != null) 'supportsBold': supportsBold,
      if (supportsItalic != null) 'supportsItalic': supportsItalic,
    };
  }
}

/// Color palette item
class ColorPaletteItem {
  final String name;
  final String hex;

  ColorPaletteItem({required this.name, required this.hex});

  Color get color {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  factory ColorPaletteItem.fromJson(Map<String, dynamic> json) {
    return ColorPaletteItem(
      name: json['name'] as String,
      hex: json['hex'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'hex': hex};
}

/// Drawing layer model
class DrawingLayer {
  final String id;
  final String name;
  final bool visible;
  final bool locked;
  final double opacity;

  DrawingLayer({
    required this.id,
    required this.name,
    required this.visible,
    required this.locked,
    required this.opacity,
  });

  factory DrawingLayer.fromJson(Map<String, dynamic> json) {
    return DrawingLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      visible: json['visible'] as bool,
      locked: json['locked'] as bool,
      opacity: (json['opacity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'visible': visible,
      'locked': locked,
      'opacity': opacity,
    };
  }
}

/// Template guide model
class TemplateGuide {
  final String type;
  final double? position;
  final double? centerX;
  final double? centerY;
  final double? radius;
  final double? size;
  final double? cornerRadius;
  final double? x;
  final double? y;
  final double? width;
  final double? height;

  TemplateGuide({
    required this.type,
    this.position,
    this.centerX,
    this.centerY,
    this.radius,
    this.size,
    this.cornerRadius,
    this.x,
    this.y,
    this.width,
    this.height,
  });

  factory TemplateGuide.fromJson(Map<String, dynamic> json) {
    return TemplateGuide(
      type: json['type'] as String,
      position: json['position'] != null ? (json['position'] as num).toDouble() : null,
      centerX: json['centerX'] != null ? (json['centerX'] as num).toDouble() : null,
      centerY: json['centerY'] != null ? (json['centerY'] as num).toDouble() : null,
      radius: json['radius'] != null ? (json['radius'] as num).toDouble() : null,
      size: json['size'] != null ? (json['size'] as num).toDouble() : null,
      cornerRadius: json['cornerRadius'] != null ? (json['cornerRadius'] as num).toDouble() : null,
      x: json['x'] != null ? (json['x'] as num).toDouble() : null,
      y: json['y'] != null ? (json['y'] as num).toDouble() : null,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (position != null) 'position': position,
      if (centerX != null) 'centerX': centerX,
      if (centerY != null) 'centerY': centerY,
      if (radius != null) 'radius': radius,
      if (size != null) 'size': size,
      if (cornerRadius != null) 'cornerRadius': cornerRadius,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}

/// Template data model
class TemplateData {
  final bool gridEnabled;
  final int? gridSize;
  final String? gridColor;
  final String backgroundColor;
  final List<DrawingLayer> layers;
  final List<TemplateGuide>? guides;

  TemplateData({
    required this.gridEnabled,
    this.gridSize,
    this.gridColor,
    required this.backgroundColor,
    required this.layers,
    this.guides,
  });

  factory TemplateData.fromJson(Map<String, dynamic> json) {
    return TemplateData(
      gridEnabled: json['gridEnabled'] as bool,
      gridSize: json['gridSize'] as int?,
      gridColor: json['gridColor'] as String?,
      backgroundColor: json['backgroundColor'] as String,
      layers: (json['layers'] as List)
          .map((l) => DrawingLayer.fromJson(l as Map<String, dynamic>))
          .toList(),
      guides: json['guides'] != null
          ? (json['guides'] as List)
              .map((g) => TemplateGuide.fromJson(g as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gridEnabled': gridEnabled,
      if (gridSize != null) 'gridSize': gridSize,
      if (gridColor != null) 'gridColor': gridColor,
      'backgroundColor': backgroundColor,
      'layers': layers.map((l) => l.toJson()).toList(),
      if (guides != null) 'guides': guides!.map((g) => g.toJson()).toList(),
    };
  }
}

/// Design template model
class DesignTemplate {
  final String id;
  final String name;
  final String category;
  final String description;
  final String thumbnailUrl;
  final String difficulty;
  final TemplateData templateData;

  DesignTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.thumbnailUrl,
    required this.difficulty,
    required this.templateData,
  });

  factory DesignTemplate.fromJson(Map<String, dynamic> json) {
    return DesignTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      difficulty: json['difficulty'] as String,
      templateData: TemplateData.fromJson(json['templateData'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'difficulty': difficulty,
      'templateData': templateData.toJson(),
    };
  }
}

/// Educational content for IP questions
class EducationalContent {
  final String title;
  final String content;
  final List<String>? examples;

  EducationalContent({
    required this.title,
    required this.content,
    this.examples,
  });

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      title: json['title'] as String,
      content: json['content'] as String,
      examples: json['examples'] != null
          ? List<String>.from(json['examples'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      if (examples != null) 'examples': examples,
    };
  }
}

/// IP filing question model
class IPQuestion {
  final String id;
  final String question;
  final String context;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final EducationalContent educationalContent;
  final String difficulty;
  final int points;

  IPQuestion({
    required this.id,
    required this.question,
    required this.context,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.educationalContent,
    required this.difficulty,
    required this.points,
  }) {
    _validate();
  }

  void _validate() {
    if (id.isEmpty) throw ArgumentError('Question id cannot be empty');
    if (question.isEmpty) throw ArgumentError('Question cannot be empty');
    if (options.length < 2) throw ArgumentError('Must have at least 2 options');
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw ArgumentError('Correct index out of range');
    }
    if (points < 0) throw ArgumentError('Points cannot be negative');
  }

  factory IPQuestion.fromJson(Map<String, dynamic> json) {
    return IPQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      context: json['context'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      educationalContent: EducationalContent.fromJson(
        json['educationalContent'] as Map<String, dynamic>,
      ),
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'context': context,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'educationalContent': educationalContent.toJson(),
      'difficulty': difficulty,
      'points': points,
    };
  }
}

/// Innovation Lab game model
class InnovationLabGame extends GameModel {
  final List<DrawingTool> drawingTools;
  final List<ColorPaletteItem> colorPalette;
  final List<DesignTemplate> templates;
  final List<IPQuestion> ipQuestions;
  final int questionsPerGame;
  final bool randomSelection;

  InnovationLabGame({
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
    required this.drawingTools,
    required this.colorPalette,
    required this.templates,
    required this.ipQuestions,
    required this.questionsPerGame,
    this.randomSelection = true,
  }) {
    _validate();
  }

  void _validate() {
    if (drawingTools.isEmpty) throw ArgumentError('Drawing tools cannot be empty');
    if (colorPalette.isEmpty) throw ArgumentError('Color palette cannot be empty');
    if (templates.isEmpty) throw ArgumentError('Templates cannot be empty');
    if (ipQuestions.isEmpty) throw ArgumentError('IP questions cannot be empty');
    if (questionsPerGame <= 0) {
      throw ArgumentError('Questions per game must be positive');
    }
    if (questionsPerGame > ipQuestions.length) {
      throw ArgumentError('Questions per game exceeds available questions');
    }
  }

  /// Select random IP questions for quiz
  List<IPQuestion> selectRandomQuestions() {
    if (!randomSelection) {
      return ipQuestions.take(questionsPerGame).toList();
    }

    final random = Random();
    final shuffled = List<IPQuestion>.from(ipQuestions)..shuffle(random);
    return shuffled.take(questionsPerGame).toList();
  }

  /// Get templates by category
  List<DesignTemplate> getTemplatesByCategory(String category) {
    return templates
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get questions by difficulty
  List<IPQuestion> getQuestionsByDifficulty(String difficulty) {
    return ipQuestions
        .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  factory InnovationLabGame.fromJson(Map<String, dynamic> json) {
    return InnovationLabGame(
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
      drawingTools: (json['drawingTools'] as List)
          .map((t) => DrawingTool.fromJson(t as Map<String, dynamic>))
          .toList(),
      colorPalette: (json['colorPalette'] as List)
          .map((c) => ColorPaletteItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      templates: (json['templates'] as List)
          .map((t) => DesignTemplate.fromJson(t as Map<String, dynamic>))
          .toList(),
      ipQuestions: (json['ipQuestions'] as List)
          .map((q) => IPQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      questionsPerGame: json['questionsPerGame'] as int,
      randomSelection: json['randomSelection'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'drawingTools': drawingTools.map((t) => t.toJson()).toList(),
      'colorPalette': colorPalette.map((c) => c.toJson()).toList(),
      'templates': templates.map((t) => t.toJson()).toList(),
      'ipQuestions': ipQuestions.map((q) => q.toJson()).toList(),
      'questionsPerGame': questionsPerGame,
      'randomSelection': randomSelection,
    };
  }
}
