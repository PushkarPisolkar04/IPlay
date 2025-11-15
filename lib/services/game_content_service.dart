import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../models/quiz_master_model.dart';
import '../models/trademark_match_model.dart';
import '../models/ip_defender_model.dart';
import '../models/spot_the_original_model.dart';
import '../models/gi_mapper_model.dart';
import '../models/patent_detective_model.dart';
import '../models/innovation_lab_model.dart';
import 'game_error_handler.dart';

/// Service for loading and caching game content from local JSON files
/// Includes error handling, retry mechanisms, and offline support
class GameContentService {
  // Singleton instance
  static final GameContentService _instance = GameContentService._internal();
  factory GameContentService() => _instance;
  GameContentService._internal();

  // Cache for loaded game content (in-memory)
  final Map<String, dynamic> _cache = {};
  
  // Cache expiration tracking
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (1 hour for in-memory, indefinite for persistent)
  static const Duration _cacheDuration = Duration(hours: 1);
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  // Persistent cache keys
  static const String _persistentCachePrefix = 'game_content_';
  static const String _cacheVersionKey = 'game_content_version';
  static const String _currentCacheVersion = '1.0.0';

  /// Load Quiz Master game content with retry and offline support
  Future<QuizMasterGame> loadQuizMaster() async {
    const cacheKey = 'quiz_master';
    
    // Check in-memory cache first
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as QuizMasterGame;
    }

    try {
      // Try to load with retry mechanism
      final game = await GameErrorHandler.retryWithBackoff<QuizMasterGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/quiz_master.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return QuizMasterGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      // Cache the loaded game (in-memory and persistent)
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      // Log error
      GameErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Loading Quiz Master',
        gameId: cacheKey,
      );
      
      // Try to load from persistent cache
      final cachedGame = await _loadFromPersistentCache<QuizMasterGame>(
        cacheKey,
        (json) => QuizMasterGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      // Return fallback content as last resort
      return _getFallbackQuizMaster(e);
    }
  }

  /// Load Trademark Match game content with retry and offline support
  Future<TrademarkMatchGame> loadTrademarkMatch() async {
    const cacheKey = 'trademark_match';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as TrademarkMatchGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<TrademarkMatchGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/trademark_match.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return TrademarkMatchGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading Trademark Match', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<TrademarkMatchGame>(
        cacheKey,
        (json) => TrademarkMatchGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackTrademarkMatch(e);
    }
  }

  /// Load IP Defender game content with retry and offline support
  Future<IPDefenderGame> loadIPDefender() async {
    const cacheKey = 'ip_defender';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as IPDefenderGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<IPDefenderGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/ip_defender.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return IPDefenderGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading IP Defender', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<IPDefenderGame>(
        cacheKey,
        (json) => IPDefenderGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackIPDefender(e);
    }
  }

  /// Load Spot the Original game content with retry and offline support
  Future<SpotTheOriginalGame> loadSpotTheOriginal() async {
    const cacheKey = 'spot_the_original';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as SpotTheOriginalGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<SpotTheOriginalGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/spot_the_original.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return SpotTheOriginalGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading Spot the Original', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<SpotTheOriginalGame>(
        cacheKey,
        (json) => SpotTheOriginalGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackSpotTheOriginal(e);
    }
  }

  /// Load GI Mapper game content with retry and offline support
  Future<GIMapperGame> loadGIMapper() async {
    const cacheKey = 'gi_mapper';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as GIMapperGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<GIMapperGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/gi_mapper.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return GIMapperGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading GI Mapper', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<GIMapperGame>(
        cacheKey,
        (json) => GIMapperGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackGIMapper(e);
    }
  }

  /// Load Patent Detective game content with retry and offline support
  Future<PatentDetectiveGame> loadPatentDetective() async {
    const cacheKey = 'patent_detective';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as PatentDetectiveGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<PatentDetectiveGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/patent_detective.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return PatentDetectiveGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading Patent Detective', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<PatentDetectiveGame>(
        cacheKey,
        (json) => PatentDetectiveGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackPatentDetective(e);
    }
  }

  /// Load Innovation Lab game content with retry and offline support
  Future<InnovationLabGame> loadInnovationLab() async {
    const cacheKey = 'innovation_lab';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as InnovationLabGame;
    }

    try {
      final game = await GameErrorHandler.retryWithBackoff<InnovationLabGame>(
        operation: () async {
          final jsonString = await rootBundle.loadString('content/games/innovation_lab.json');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          return InnovationLabGame.fromJson(jsonData);
        },
        maxAttempts: _maxRetries,
        initialDelay: _retryDelay,
      );
      
      _cache[cacheKey] = game;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _saveToPersistentCache(cacheKey, game.toJson());
      
      return game;
    } catch (e, stackTrace) {
      GameErrorHandler.logError(e, stackTrace: stackTrace, context: 'Loading Innovation Lab', gameId: cacheKey);
      
      final cachedGame = await _loadFromPersistentCache<InnovationLabGame>(
        cacheKey,
        (json) => InnovationLabGame.fromJson(json),
      );
      
      if (cachedGame != null) {
        _cache[cacheKey] = cachedGame;
        return cachedGame;
      }
      
      return _getFallbackInnovationLab(e);
    }
  }

  /// Load all games at once with error handling
  /// Returns successfully loaded games even if some fail
  Future<Map<String, dynamic>> loadAllGames() async {
    final games = <String, dynamic>{};
    final errors = <String, dynamic>{};
    
    // Load each game individually to handle errors gracefully
    try {
      games['quiz_master'] = await loadQuizMaster();
    } catch (e) {
      errors['quiz_master'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - Quiz Master');
    }
    
    try {
      games['trademark_match'] = await loadTrademarkMatch();
    } catch (e) {
      errors['trademark_match'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - Trademark Match');
    }
    
    try {
      games['ip_defender'] = await loadIPDefender();
    } catch (e) {
      errors['ip_defender'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - IP Defender');
    }
    
    try {
      games['spot_the_original'] = await loadSpotTheOriginal();
    } catch (e) {
      errors['spot_the_original'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - Spot the Original');
    }
    
    try {
      games['gi_mapper'] = await loadGIMapper();
    } catch (e) {
      errors['gi_mapper'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - GI Mapper');
    }
    
    try {
      games['patent_detective'] = await loadPatentDetective();
    } catch (e) {
      errors['patent_detective'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - Patent Detective');
    }
    
    try {
      games['innovation_lab'] = await loadInnovationLab();
    } catch (e) {
      errors['innovation_lab'] = e;
      GameErrorHandler.logError(e, context: 'Loading all games - Innovation Lab');
    }
    
    // If no games loaded successfully, throw exception
    if (games.isEmpty) {
      throw GameContentException(
        'Failed to load all games. Errors: ${errors.keys.join(", ")}'
      );
    }
    
    // Log if some games failed to load
    if (errors.isNotEmpty) {
      print('Warning: Some games failed to load: ${errors.keys.join(", ")}');
    }
    
    return games;
  }

  /// Check if cached content is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    final age = DateTime.now().difference(timestamp);
    return age < _cacheDuration;
  }

  /// Save game content to persistent cache (SharedPreferences)
  Future<void> _saveToPersistentCache(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString('$_persistentCachePrefix$key', jsonString);
      await prefs.setString(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      GameErrorHandler.logError(
        e,
        context: 'Saving to persistent cache',
        gameId: key,
      );
    }
  }

  /// Load game content from persistent cache
  Future<T?> _loadFromPersistentCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final cacheVersion = prefs.getString(_cacheVersionKey);
      if (cacheVersion != _currentCacheVersion) {
        // Cache version mismatch, clear old cache
        await clearPersistentCache();
        return null;
      }
      
      final jsonString = prefs.getString('$_persistentCachePrefix$key');
      if (jsonString == null) return null;
      
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonData);
    } catch (e) {
      GameErrorHandler.logError(
        e,
        context: 'Loading from persistent cache',
        gameId: key,
      );
      return null;
    }
  }

  /// Clear cache for a specific game (both in-memory and persistent)
  Future<void> clearCache(String gameId) async {
    _cache.remove(gameId);
    _cacheTimestamps.remove(gameId);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_persistentCachePrefix$gameId');
    } catch (e) {
      GameErrorHandler.logError(
        e,
        context: 'Clearing cache',
        gameId: gameId,
      );
    }
  }

  /// Clear all cached content (both in-memory and persistent)
  Future<void> clearAllCache() async {
    _cache.clear();
    _cacheTimestamps.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_persistentCachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      GameErrorHandler.logError(e, context: 'Clearing all cache');
    }
  }

  /// Clear persistent cache only
  Future<void> clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_persistentCachePrefix) || key == _cacheVersionKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      GameErrorHandler.logError(e, context: 'Clearing persistent cache');
    }
  }

  /// Preload all games into cache
  Future<void> preloadAllGames() async {
    try {
      await loadAllGames();
    } catch (e) {
      GameErrorHandler.logError(e, context: 'Preloading all games');
    }
  }

  /// Check if offline mode is available (has cached content)
  Future<bool> isOfflineModeAvailable(String gameId) async {
    // Check in-memory cache
    if (_cache.containsKey(gameId)) return true;
    
    // Check persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_persistentCachePrefix$gameId');
    } catch (e) {
      return false;
    }
  }

  /// Get cache status for all games
  Future<Map<String, bool>> getCacheStatus() async {
    final status = <String, bool>{};
    final gameIds = [
      'quiz_master',
      'trademark_match',
      'ip_defender',
      'spot_the_original',
      'gi_mapper',
      'patent_detective',
      'innovation_lab',
    ];
    
    for (final gameId in gameIds) {
      status[gameId] = await isOfflineModeAvailable(gameId);
    }
    
    return status;
  }

  // Fallback content methods for offline mode

  QuizMasterGame _getFallbackQuizMaster(dynamic error) {
    print('Error loading Quiz Master: $error. Using fallback content.');
    
    return QuizMasterGame(
      id: 'quiz_master',
      name: 'Quiz Master',
      description: 'Test your IPR knowledge',
      summary: 'Quiz game about intellectual property',
      iconPath: 'assets/games/quiz_master.png',
      color: const Color(0xFF6366F1),
      difficulty: 'mixed',
      gameType: 'quiz',
      xpReward: 75,
      estimatedMinutes: 10,
      rewards: GameRewards(
        completion: 50,
        perfectScore: 100,
        firstTime: 25,
        highScore: 75,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      questionPool: [
        QuizQuestion(
          id: 'fallback_001',
          question: 'What does IPR stand for?',
          options: [
            'International Property Rights',
            'Intellectual Property Rights',
            'Indian Patent Registry',
            'Industrial Protection Rules',
          ],
          correctIndex: 1,
          explanation: 'IPR stands for Intellectual Property Rights.',
          difficulty: 'easy',
          realm: 'general',
          points: 10,
        ),
      ],
      questionsPerGame: 10,
      passingScore: 70,
    );
  }

  TrademarkMatchGame _getFallbackTrademarkMatch(dynamic error) {
    print('Error loading Trademark Match: $error. Using fallback content.');
    
    return TrademarkMatchGame(
      id: 'trademark_match',
      name: 'Trademark Match',
      description: 'Match logos with companies',
      summary: 'Logo matching game',
      iconPath: 'assets/games/trademark_match.png',
      color: const Color(0xFF2196F3),
      difficulty: 'medium',
      gameType: 'matching',
      xpReward: 60,
      estimatedMinutes: 8,
      rewards: GameRewards(
        completion: 40,
        perfectScore: 80,
        firstTime: 20,
        highScore: 60,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      matchPairs: [
        TrademarkPair(
          id: 'fallback_tm_001',
          trademark: 'Golden Arches',
          company: "McDonald's",
          imageUrl: 'assets/trademarks/mcdonalds.png',
          hint: 'Fast food chain',
          difficulty: 'easy',
          points: 10,
          category: 'food',
          region: 'international',
        ),
      ],
      pairsPerGame: 5,
    );
  }

  IPDefenderGame _getFallbackIPDefender(dynamic error) {
    print('Error loading IP Defender: $error. Using fallback content.');
    
    return IPDefenderGame(
      id: 'ip_defender',
      name: 'IP Defender',
      description: 'Defend IP assets from threats',
      summary: 'Tower defense game',
      iconPath: 'assets/games/ip_defender.png',
      color: const Color(0xFFE91E63),
      difficulty: 'hard',
      gameType: 'tower_defense',
      xpReward: 100,
      estimatedMinutes: 15,
      rewards: GameRewards(
        completion: 60,
        perfectScore: 120,
        firstTime: 30,
        highScore: 90,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      levels: [],
      towers: [],
      enemies: [],
    );
  }

  SpotTheOriginalGame _getFallbackSpotTheOriginal(dynamic error) {
    print('Error loading Spot the Original: $error. Using fallback content.');
    
    return SpotTheOriginalGame(
      id: 'spot_the_original',
      name: 'Spot the Original',
      description: 'Identify authentic brands',
      summary: 'Visual discrimination game',
      iconPath: 'assets/games/spot_the_original.png',
      color: const Color(0xFFFF6B35),
      difficulty: 'medium',
      gameType: 'visual',
      xpReward: 70,
      estimatedMinutes: 10,
      rewards: GameRewards(
        completion: 45,
        perfectScore: 90,
        firstTime: 25,
        highScore: 70,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      productSets: [],
      comparisonsPerGame: 5,
    );
  }

  GIMapperGame _getFallbackGIMapper(dynamic error) {
    print('Error loading GI Mapper: $error. Using fallback content.');
    
    // Create a minimal fallback with at least one product to pass validation
    final fallbackProduct = GIProduct(
      id: 'fallback_gi_001',
      name: 'Darjeeling Tea',
      state: 'West Bengal',
      stateCode: 'WB',
      coordinates: GeoCoordinates(lat: 27.0, lng: 88.0),
      category: 'beverage',
      imageUrl: 'assets/gi/darjeeling_tea.png',
      description: 'Famous tea from Darjeeling',
      registrationYear: 2003,
      uniqueCharacteristics: ['Muscatel flavor'],
      hint: 'Famous hill station tea',
      difficulty: 'easy',
      points: 10,
    );
    
    final fallbackState = StateData(
      code: 'WB',
      name: 'West Bengal',
      svgPath: 'M 0 0',
      color: const Color(0xFFFF6B6B),
    );
    
    return GIMapperGame(
      id: 'gi_mapper',
      name: 'GI Mapper',
      description: 'Map GI products to states',
      summary: 'Interactive geography game',
      iconPath: 'assets/games/gi_mapper.png',
      color: const Color(0xFFFFC107),
      difficulty: 'medium',
      gameType: 'geography',
      xpReward: 80,
      estimatedMinutes: 12,
      rewards: GameRewards(
        completion: 50,
        perfectScore: 100,
        firstTime: 25,
        highScore: 75,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      giProducts: [fallbackProduct],
      mapData: IndiaMapData(states: [fallbackState]),
      pairsPerGame: 1,
    );
  }

  PatentDetectiveGame _getFallbackPatentDetective(dynamic error) {
    print('Error loading Patent Detective: $error. Using fallback content.');
    
    return PatentDetectiveGame(
      id: 'patent_detective',
      name: 'Patent Detective',
      description: 'Solve patent mysteries',
      summary: 'Detective deduction game',
      iconPath: 'assets/games/patent_detective.png',
      color: const Color(0xFF00BCD4),
      difficulty: 'medium',
      gameType: 'detective',
      xpReward: 85,
      estimatedMinutes: 12,
      rewards: GameRewards(
        completion: 55,
        perfectScore: 110,
        firstTime: 30,
        highScore: 85,
      ),
      leaderboard: LeaderboardConfig(
        enabled: true,
        scope: ['classroom', 'school', 'global'],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      cases: [],
      casesPerGame: 5,
    );
  }

  InnovationLabGame _getFallbackInnovationLab(dynamic error) {
    print('Error loading Innovation Lab: $error. Using fallback content.');
    
    // Create minimal fallback data to pass validation
    final fallbackTool = DrawingTool(
      id: 'pencil',
      name: 'Pencil',
      icon: 'edit',
      type: 'freehand',
      strokeWidthRange: [1, 5],
      defaultStrokeWidth: 2,
      supportsOpacity: true,
      supportsColor: true,
    );
    
    final fallbackColor = ColorPaletteItem(name: 'Black', hex: '#000000');
    
    final fallbackTemplate = DesignTemplate(
      id: 'fallback_template',
      name: 'Blank Canvas',
      category: 'general',
      description: 'Empty canvas',
      thumbnailUrl: 'assets/templates/blank.png',
      difficulty: 'easy',
      templateData: TemplateData(
        gridEnabled: false,
        backgroundColor: '#FFFFFF',
        layers: [
          DrawingLayer(
            id: 'layer_1',
            name: 'Layer 1',
            visible: true,
            locked: false,
            opacity: 1.0,
          ),
        ],
      ),
    );
    
    final fallbackQuestion = IPQuestion(
      id: 'fallback_ip_001',
      question: 'What type of IP protection is this?',
      context: 'Based on your design',
      options: ['Patent', 'Copyright', 'Trademark', 'Trade Secret'],
      correctIndex: 0,
      explanation: 'This is a patent.',
      educationalContent: EducationalContent(
        title: 'IP Protection',
        content: 'Learn about IP types',
      ),
      difficulty: 'easy',
      points: 10,
    );
    
    return InnovationLabGame(
      id: 'innovation_lab',
      name: 'Innovation Lab',
      description: 'Design and learn about IP filing',
      summary: 'Creative canvas tool',
      iconPath: 'assets/games/innovation_lab.png',
      color: const Color(0xFF4CAF50),
      difficulty: 'easy',
      gameType: 'creative',
      xpReward: 90,
      estimatedMinutes: 20,
      rewards: GameRewards(
        completion: 60,
        perfectScore: 120,
        firstTime: 35,
        highScore: 90,
      ),
      leaderboard: LeaderboardConfig(
        enabled: false,
        scope: [],
      ),
      version: '1.0.0',
      updatedAt: DateTime.now(),
      templates: [fallbackTemplate],
      ipQuestions: [fallbackQuestion],
      drawingTools: [fallbackTool],
      colorPalette: [fallbackColor],
      questionsPerGame: 1,
    );
  }
}

/// Custom exception for game content loading errors
class GameContentException implements Exception {
  final String message;
  GameContentException(this.message);

  @override
  String toString() => 'GameContentException: $message';
}
