import '../models/realm_model.dart';
import '../data/realms_data.dart';
import '../data/copyright_levels_data.dart';

/// Service to manage learning content (realms and levels)
class ContentService {
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
}

