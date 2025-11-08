import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/realm_model.dart';
import '../data/realms_data.dart';
import '../data/copyright_levels_data.dart';
import '../database/content_database_helper.dart';

/// Service to manage learning content (realms and levels)
class ContentService {
  final ContentDatabaseHelper _dbHelper = ContentDatabaseHelper.instance;
  /// Get all realms
  List<RealmModel> getAllRealms() {
    return RealmsData.getAllRealms();
  }

  /// Get a specific realm by ID
  RealmModel? getRealmById(String realmId) {
    return RealmsData.getRealmById(realmId);
  }

  /// Get all levels for a specific realm
  List<LevelModel> getLevelsForRealm(String realmId) {
    switch (realmId) {
      case 'realm_copyright':
        return CopyrightLevelsData.getAllLevels();
      // TODO: Add other realms when content is ready
      case 'realm_trademark':
      case 'realm_patent':
      case 'realm_design':
      case 'realm_gi':
      case 'realm_trade_secrets':
        return _generatePlaceholderLevels(realmId);
      default:
        return [];
    }
  }

  /// Get a specific level by ID
  LevelModel? getLevelById(String levelId) {
    // Check Copyright realm
    final copyrightLevel = CopyrightLevelsData.getLevelById(levelId);
    if (copyrightLevel != null) return copyrightLevel;

    // TODO: Check other realms when content is ready

    return null;
  }

  /// Generate placeholder levels for realms without content yet
  List<LevelModel> _generatePlaceholderLevels(String realmId) {
    final realm = getRealmById(realmId);
    if (realm == null) return [];

    return List.generate(realm.totalLevels, (index) {
      final levelNumber = index + 1;
      return LevelModel(
        id: '${realmId}_level_$levelNumber',
        realmId: realmId,
        levelNumber: levelNumber,
        name: 'Level $levelNumber (Coming Soon)',
        description: 'This level is under development',
        content: '''
# Coming Soon!

This level is currently being developed. Check back soon for complete content on ${realm.name}.

## What to expect:
- Comprehensive video lessons
- Detailed text content
- Interactive quizzes
- Practical examples

Stay tuned! 🚀
''',
        keyPoints: [
          'Content coming soon',
          'Check back for updates',
        ],
        quiz: [
          QuizQuestion(
            question: 'This level is under development. Ready to explore other realms?',
            options: ['Yes, let\'s go!', 'I\'ll wait', 'Show me more', 'Take me back'],
            correctIndex: 0,
            explanation: 'Great! More content is being added regularly. Check back soon!',
          ),
        ],
        xpReward: 50,
        estimatedMinutes: 5,
      );
    });
  }

  /// Search levels by query
  List<LevelModel> searchLevels(String query) {
    if (query.isEmpty) return [];

    final allLevels = <LevelModel>[];
    for (final realm in getAllRealms()) {
      allLevels.addAll(getLevelsForRealm(realm.id));
    }

    final lowerQuery = query.toLowerCase();
    return allLevels.where((level) {
      return level.name.toLowerCase().contains(lowerQuery) ||
          level.description.toLowerCase().contains(lowerQuery) ||
          level.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Load level content from JSON assets
  Future<Map<String, dynamic>?> loadLevelFromAssets(String levelId) async {
    try {
      // Try to load from assets
      final jsonString = await rootBundle.loadString('assets/content/$levelId.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // print('Error loading level $levelId from assets: $e');
      return null;
    }
  }

  /// Get level content with caching
  Future<Map<String, dynamic>?> getLevelContent(String levelId) async {
    // First, check cache
    final cached = await _dbHelper.getCachedLevel(levelId);
    if (cached != null) {
      // Check if cache is still valid (less than 24 hours old)
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cached['cached_at'] as int);
      final now = DateTime.now();
      if (now.difference(cachedAt).inHours < 24) {
        return json.decode(cached['content_json'] as String) as Map<String, dynamic>;
      }
    }

    // Load from assets
    final content = await loadLevelFromAssets(levelId);
    if (content != null) {
      // Cache the content
      await _dbHelper.cacheLevelContent(
        levelId: levelId,
        realmId: content['realmId'] as String,
        contentJson: json.encode(content),
        version: content['version'] as String,
        updatedAt: content['updatedAt'] as String,
      );
    }

    return content;
  }

  /// Check if content version needs update
  Future<bool> needsContentUpdate(String realmId, String currentVersion) async {
    final versionInfo = await _dbHelper.getContentVersion(realmId);
    if (versionInfo == null) return true;

    final cachedVersion = versionInfo['version'] as String;
    return _compareVersions(currentVersion, cachedVersion) > 0;
  }

  /// Compare semantic versions (returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Download realm for offline access
  Future<bool> downloadRealmForOffline(String realmId) async {
    try {
      final realm = getRealmById(realmId);
      if (realm == null) return false;

      int totalSize = 0;
      int levelsCount = 0;

      // Load and cache all levels for this realm
      for (int i = 1; i <= realm.totalLevels; i++) {
        final levelId = '${realmId.replaceAll('realm_', '')}_level_$i';
        final content = await getLevelContent(levelId);
        
        if (content != null) {
          levelsCount++;
          totalSize += json.encode(content).length;
        }
      }

      // Mark realm as downloaded
      await _dbHelper.markRealmDownloaded(
        realmId: realmId,
        totalSize: totalSize,
        levelsCount: levelsCount,
      );

      return true;
    } catch (e) {
      // print('Error downloading realm $realmId: $e');
      return false;
    }
  }

  /// Check if realm is available offline
  Future<bool> isRealmAvailableOffline(String realmId) async {
    return await _dbHelper.isRealmDownloaded(realmId);
  }

  /// Get all downloaded realms
  Future<List<String>> getDownloadedRealmIds() async {
    final downloaded = await _dbHelper.getDownloadedRealms();
    return downloaded.map((r) => r['realm_id'] as String).toList();
  }

  /// Delete offline realm data
  Future<void> deleteOfflineRealm(String realmId) async {
    await _dbHelper.deleteRealmCache(realmId);
  }

  /// Clear all cached content
  Future<void> clearAllCache() async {
    await _dbHelper.clearAllCache();
  }

  /// Update content version for a realm
  Future<void> updateRealmVersion(String realmId, String version) async {
    await _dbHelper.updateContentVersion(
      realmId: realmId,
      version: version,
    );
  }

  /// Get cached levels count for a realm
  Future<int> getCachedLevelsCount(String realmId) async {
    final levels = await _dbHelper.getCachedLevelsForRealm(realmId);
    return levels.length;
  }
}

