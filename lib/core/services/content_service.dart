import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/realm_model.dart';

/// Service to manage learning content (realms and levels) from local JSON files
class ContentService {
  List<RealmModel>? _cachedRealms;
  Map<String, List<LevelModel>> _cachedLevels = {};
  Map<String, Map<String, dynamic>> _cachedQuizzes = {};

  /// Get all realms from JSON
  Future<List<RealmModel>> getAllRealms() async {
    if (_cachedRealms != null) return _cachedRealms!;
    
    try {
      final jsonString = await rootBundle.loadString('content/realms_v1.0.0.json');
      final jsonData = json.decode(jsonString);
      
      final realms = (jsonData['realms'] as List)
          .map((r) {
            try {
              return RealmModel.fromJson(r as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing realm: $e');
              print('Realm data: $r');
              rethrow;
            }
          })
          .toList();
      
      _cachedRealms = realms;
      return realms;
    } catch (e, stackTrace) {
      print('Error loading realms: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get all realms synchronously (for widgets that need immediate data)
  List<RealmModel> getAllRealmsSync() {
    return _cachedRealms ?? [];
  }

  /// Get a specific realm by ID
  RealmModel? getRealmById(String realmId) {
    return _cachedRealms?.firstWhere(
      (r) => r.id == realmId,
      orElse: () => _cachedRealms!.first,
    );
  }

  /// Get all levels for a specific realm from JSON
  Future<List<LevelModel>> getLevelsForRealm(String realmId) async {
    if (_cachedLevels.containsKey(realmId)) {
      return _cachedLevels[realmId]!;
    }

    try {
      // Load all level files for this realm
      final levels = <LevelModel>[];
      
      // Try to load 10 levels (adjust based on your content)
      for (int i = 1; i <= 10; i++) {
        try {
          final levelId = '${realmId.replaceAll('realm_', '')}_level_$i';
          final level = await getLevelById(levelId);
          if (level != null) {
            levels.add(level);
          } else {
            break;
          }
        } catch (e) {
          // Level doesn't exist, stop loading
          break;
        }
      }
      
      _cachedLevels[realmId] = levels;
      return levels;
    } catch (e) {
      print('Error loading levels for $realmId: $e');
      return [];
    }
  }

  /// Get a specific level by ID from JSON
  /// Note: Does NOT cache to ensure quiz questions are reshuffled on each load
  Future<LevelModel?> getLevelById(String levelId) async {
    try {
      print('📚 Loading level: $levelId');
      
      // Load level content
      final jsonString = await rootBundle.loadString('content/levels/$levelId.json');
      print('✅ Level JSON loaded successfully');
      
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      print('✅ Level JSON parsed. Keys: ${jsonData.keys.join(", ")}');
      
      // Ensure required fields exist with proper defaults
      if (!jsonData.containsKey('content')) {
        jsonData['content'] = jsonData['description'] ?? '';
      }
      
      // Load quiz questions from separate file and randomly select 5
      // This happens on EVERY load so retaking quiz gives different questions
      List<Map<String, dynamic>> quizQuestions = [];
      try {
        print('📝 Loading quiz for: $levelId');
        final quizString = await rootBundle.loadString('content/quizzes/$levelId.json');
        final quizData = json.decode(quizString) as Map<String, dynamic>;
        final questions = quizData['questions'] as List<dynamic>?;
        if (questions != null) {
          print('✅ Found ${questions.length} quiz questions');
          
          // Convert all questions to map format
          final allQuestions = questions.map((q) {
            final question = q as Map<String, dynamic>;
            return {
              'question': question['question'] as String,
              'options': (question['options'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList(),
              'correctIndex': question['correctIndex'] as int,
              'explanation': question['explanation'] as String,
            };
          }).toList();
          
          // Randomly shuffle and select 5 questions (different each time!)
          allQuestions.shuffle();
          quizQuestions = allQuestions.take(5).toList();
          print('✅ Selected 5 random questions for quiz');
        }
      } catch (e) {
        print('⚠️ Error loading quiz for $levelId: $e');
      }
      
      // Merge quiz into level data
      jsonData['quiz'] = quizQuestions;
      
      print('✅ Creating LevelModel with ${quizQuestions.length} quiz questions');
      print('Level data: id=${jsonData['id']}, realmId=${jsonData['realmId']}, levelNumber=${jsonData['levelNumber']}');
      
      final level = LevelModel.fromJson(jsonData);
      print('✅ Level loaded successfully: ${level.name}');
      
      return level;
    } catch (e, stackTrace) {
      print('❌ Error loading level $levelId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Get level content as JSON (for backward compatibility)
  Future<Map<String, dynamic>?> getLevelContent(String levelId) async {
    try {
      final jsonString = await rootBundle.loadString('content/levels/$levelId.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading level content $levelId: $e');
      return null;
    }
  }

  /// Get quiz for a specific level from JSON
  Future<Map<String, dynamic>?> getQuizForLevel(String levelId) async {
    if (_cachedQuizzes.containsKey(levelId)) {
      return _cachedQuizzes[levelId];
    }

    try {
      final jsonString = await rootBundle.loadString('content/quizzes/$levelId.json');
      final jsonData = json.decode(jsonString);
      _cachedQuizzes[levelId] = jsonData;
      return jsonData;
    } catch (e) {
      print('Error loading quiz for $levelId: $e');
      return null;
    }
  }

  /// Search levels by query
  Future<List<LevelModel>> searchLevels(String query) async {
    if (query.isEmpty) return [];

    final allLevels = <LevelModel>[];
    final realms = await getAllRealms();
    for (final realm in realms) {
      final levels = await getLevelsForRealm(realm.id);
      allLevels.addAll(levels);
    }

    final lowerQuery = query.toLowerCase();
    return allLevels.where((level) {
      return level.name.toLowerCase().contains(lowerQuery) ||
          level.description.toLowerCase().contains(lowerQuery) ||
          level.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedRealms = null;
    _cachedLevels.clear();
    _cachedQuizzes.clear();
  }

  /// Preload all content at app startup
  Future<void> preloadContent() async {
    await getAllRealms();
    // Optionally preload first level of each realm
    final realms = _cachedRealms ?? [];
    for (final realm in realms) {
      try {
        await getLevelsForRealm(realm.id);
      } catch (e) {
        print('Error preloading ${realm.id}: $e');
      }
    }
  }
}

