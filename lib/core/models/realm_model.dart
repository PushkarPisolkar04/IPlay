/// Realm model representing an IPR learning realm
class RealmModel {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Asset path for icon image
  final int color; // Color value
  final int totalLevels;
  final int totalXP;
  final List<String> levelIds;
  final int estimatedMinutes;
  
  RealmModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.color,
    required this.totalLevels,
    required this.totalXP,
    required this.levelIds,
    required this.estimatedMinutes,
  });

  factory RealmModel.fromMap(Map<String, dynamic> map) {
    // Parse color - handle both String hex and int
    int colorValue = 0xFFFF6B35;
    if (map['color'] != null) {
      if (map['color'] is String) {
        colorValue = int.parse((map['color'] as String).replaceFirst('0x', ''), radix: 16);
      } else if (map['color'] is int) {
        colorValue = map['color'];
      }
    }
    
    return RealmModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconPath: map['iconPath'] ?? 'assets/logos/default_logo.png',
      color: colorValue,
      totalLevels: map['totalLevels'] ?? 0,
      totalXP: map['totalXP'] ?? 0,
      levelIds: List<String>.from(map['levelIds'] ?? []),
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
    );
  }

  // Alias for fromMap
  factory RealmModel.fromJson(Map<String, dynamic> json) => RealmModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realmId': id, // For compatibility with RealmDetailScreen
      'name': name,
      'title': name, // For compatibility with RealmDetailScreen
      'description': description,
      'iconPath': iconPath,
      'color': color,
      'totalLevels': totalLevels,
      'totalXP': totalXP,
      'levelIds': levelIds,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}

/// Level model representing a single level within a realm
class LevelModel {
  final String id;
  final String realmId;
  final int levelNumber;
  final String name;
  final String description;
  final String? videoUrl;
  final String content; // HTML or markdown content
  final List<String> keyPoints; // Summary points
  final List<QuizQuestion> quiz;
  final int xpReward;
  final int estimatedMinutes;
  
  LevelModel({
    required this.id,
    required this.realmId,
    required this.levelNumber,
    required this.name,
    required this.description,
    this.videoUrl,
    required this.content,
    required this.keyPoints,
    required this.quiz,
    required this.xpReward,
    required this.estimatedMinutes,
  });

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    return LevelModel(
      id: map['id'] ?? '',
      realmId: map['realmId'] ?? '',
      levelNumber: map['levelNumber'] ?? 1,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'],
      content: map['content'] ?? '',
      keyPoints: List<String>.from(map['keyPoints'] ?? []),
      quiz: (map['quiz'] as List?)?.map((q) => QuizQuestion.fromMap(q)).toList() ?? [],
      xpReward: map['xpReward'] ?? 0,
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
    );
  }

  // Alias for fromMap
  factory LevelModel.fromJson(Map<String, dynamic> json) => LevelModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'realmId': realmId,
      'levelNumber': levelNumber,
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
      'content': content,
      'keyPoints': keyPoints,
      'quiz': quiz.map((q) => q.toMap()).toList(),
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}

/// Quiz question model
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

