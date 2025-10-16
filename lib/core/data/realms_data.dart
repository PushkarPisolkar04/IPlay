import '../models/realm_model.dart';

/// Static realm data - All 6 IPR realms
class RealmsData {
  static List<RealmModel> getAllRealms() {
    return [
      RealmModel(
        id: 'realm_copyright',
        name: 'Copyright Realm',
        description: 'Master copyright protection from basics to legal filing',
        iconEmoji: '©️',
        color: 0xFFFF6B35, // Orange
        totalLevels: 8,
        totalXP: 1370,
        levelIds: [
          'copyright_level_1',
          'copyright_level_2',
          'copyright_level_3',
          'copyright_level_4',
          'copyright_level_5',
          'copyright_level_6',
          'copyright_level_7',
          'copyright_level_8',
        ],
        estimatedMinutes: 90,
      ),
      
      RealmModel(
        id: 'realm_trademark',
        name: 'Trademark Realm',
        description: 'Learn brand protection from basics to registration',
        iconEmoji: '™️',
        color: 0xFF2196F3, // Blue
        totalLevels: 8,
        totalXP: 1370,
        levelIds: [
          'trademark_level_1',
          'trademark_level_2',
          'trademark_level_3',
          'trademark_level_4',
          'trademark_level_5',
          'trademark_level_6',
          'trademark_level_7',
          'trademark_level_8',
        ],
        estimatedMinutes: 95,
      ),
      
      RealmModel(
        id: 'realm_patent',
        name: 'Patent Realm',
        description: 'Understand invention protection and filing process',
        iconEmoji: '🔬',
        color: 0xFF4CAF50, // Green
        totalLevels: 9,
        totalXP: 1700,
        levelIds: [
          'patent_level_1',
          'patent_level_2',
          'patent_level_3',
          'patent_level_4',
          'patent_level_5',
          'patent_level_6',
          'patent_level_7',
          'patent_level_8',
          'patent_level_9',
        ],
        estimatedMinutes: 110,
      ),
      
      RealmModel(
        id: 'realm_design',
        name: 'Industrial Design Realm',
        description: 'Protect product designs and aesthetics',
        iconEmoji: '🎨',
        color: 0xFFE91E63, // Pink
        totalLevels: 7,
        totalXP: 1150,
        levelIds: [
          'design_level_1',
          'design_level_2',
          'design_level_3',
          'design_level_4',
          'design_level_5',
          'design_level_6',
          'design_level_7',
        ],
        estimatedMinutes: 75,
      ),
      
      RealmModel(
        id: 'realm_gi',
        name: 'Geographical Indication',
        description: 'Learn about GI protection for regional products',
        iconEmoji: '🗺️',
        color: 0xFFFFC107, // Yellow
        totalLevels: 6,
        totalXP: 910,
        levelIds: [
          'gi_level_1',
          'gi_level_2',
          'gi_level_3',
          'gi_level_4',
          'gi_level_5',
          'gi_level_6',
        ],
        estimatedMinutes: 60,
      ),
      
      RealmModel(
        id: 'realm_trade_secrets',
        name: 'Trade Secrets Realm',
        description: 'Protect confidential business information',
        iconEmoji: '🤫',
        color: 0xFF9C27B0, // Purple
        totalLevels: 6,
        totalXP: 900,
        levelIds: [
          'trade_secrets_level_1',
          'trade_secrets_level_2',
          'trade_secrets_level_3',
          'trade_secrets_level_4',
          'trade_secrets_level_5',
          'trade_secrets_level_6',
        ],
        estimatedMinutes: 55,
      ),
    ];
  }

  /// Get realm by ID
  static RealmModel? getRealmById(String id) {
    try {
      return getAllRealms().firstWhere((realm) => realm.id == id);
    } catch (e) {
      return null;
    }
  }
}

