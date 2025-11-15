import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to seed badges into Firestore with asset paths
/// Run this once to populate your badges collection
Future<void> seedBadges() async {
  final firestore = FirebaseFirestore.instance;
  final badges = [
    // Milestone Badges
    {
      'id': 'first_steps',
      'name': 'First Steps',
      'description': 'Complete your first level',
      'iconPath': 'assets/badges/first_steps.png',
      'category': 'milestone',
      'xpBonus': 50,
      'rarity': 'common',
      'criteriaType': 'levels_completed',
      'criteriaValue': 1,
      'order': 1,
      'isActive': true,
    },
    {
      'id': 'knowledge_seeker',
      'name': 'Knowledge Seeker',
      'description': 'Complete 10 levels',
      'iconPath': 'assets/badges/knowledge_seeker.png',
      'category': 'milestone',
      'xpBonus': 100,
      'rarity': 'common',
      'criteriaType': 'levels_completed',
      'criteriaValue': 10,
      'order': 2,
      'isActive': true,
    },
    {
      'id': 'ip_scholar',
      'name': 'IP Scholar',
      'description': 'Complete 25 levels',
      'iconPath': 'assets/badges/ip_scholar.png',
      'category': 'milestone',
      'xpBonus': 250,
      'rarity': 'rare',
      'criteriaType': 'levels_completed',
      'criteriaValue': 25,
      'order': 3,
      'isActive': true,
    },
    {
      'id': 'ip_master',
      'name': 'IP Master',
      'description': 'Complete all 60 levels',
      'iconPath': 'assets/badges/ip_master.png',
      'category': 'milestone',
      'xpBonus': 500,
      'rarity': 'legendary',
      'criteriaType': 'levels_completed',
      'criteriaValue': 60,
      'order': 4,
      'isActive': true,
    },
    
    // Streak Badges
    {
      'id': 'consistent_learner',
      'name': 'Consistent Learner',
      'description': 'Maintain a 7-day learning streak',
      'iconPath': 'assets/badges/consistent_learner.png',
      'category': 'streak',
      'xpBonus': 100,
      'rarity': 'common',
      'criteriaType': 'streak',
      'criteriaValue': 7,
      'order': 10,
      'isActive': true,
    },
    {
      'id': 'dedicated_student',
      'name': 'Dedicated Student',
      'description': 'Maintain a 30-day learning streak',
      'iconPath': 'assets/badges/dedicated_student.png',
      'category': 'streak',
      'xpBonus': 300,
      'rarity': 'rare',
      'criteriaType': 'streak',
      'criteriaValue': 30,
      'order': 11,
      'isActive': true,
    },
    {
      'id': 'unstoppable',
      'name': 'Unstoppable',
      'description': 'Maintain a 100-day learning streak',
      'iconPath': 'assets/badges/unstoppable.png',
      'category': 'streak',
      'xpBonus': 1000,
      'rarity': 'legendary',
      'criteriaType': 'streak',
      'criteriaValue': 100,
      'order': 12,
      'isActive': true,
    },
    
    // Mastery Badges
    {
      'id': 'copyright_expert',
      'name': 'Copyright Expert',
      'description': 'Complete all Copyright Realm levels',
      'iconPath': 'assets/badges/copyright_expert.png',
      'category': 'mastery',
      'xpBonus': 200,
      'rarity': 'rare',
      'criteriaType': 'realm_completed',
      'criteriaValue': 'realm_copyright',
      'order': 20,
      'isActive': true,
    },
    {
      'id': 'trademark_expert',
      'name': 'Trademark Expert',
      'description': 'Complete all Trademark Realm levels',
      'iconPath': 'assets/badges/trademark_expert.png',
      'category': 'mastery',
      'xpBonus': 200,
      'rarity': 'rare',
      'criteriaType': 'realm_completed',
      'criteriaValue': 'realm_trademark',
      'order': 21,
      'isActive': true,
    },
    {
      'id': 'patent_expert',
      'name': 'Patent Expert',
      'description': 'Complete all Patent Realm levels',
      'iconPath': 'assets/badges/patent_expert.png',
      'category': 'mastery',
      'xpBonus': 200,
      'rarity': 'rare',
      'criteriaType': 'realm_completed',
      'criteriaValue': 'realm_patent',
      'order': 22,
      'isActive': true,
    },
    
    // XP Badges
    {
      'id': 'rising_star',
      'name': 'Rising Star',
      'description': 'Earn 1,000 XP',
      'iconPath': 'assets/badges/rising_star.png',
      'category': 'milestone',
      'xpBonus': 100,
      'rarity': 'common',
      'criteriaType': 'xp_threshold',
      'criteriaValue': 1000,
      'order': 30,
      'isActive': true,
    },
    {
      'id': 'xp_champion',
      'name': 'XP Champion',
      'description': 'Earn 5,000 XP',
      'iconPath': 'assets/badges/xp_champion.png',
      'category': 'milestone',
      'xpBonus': 500,
      'rarity': 'epic',
      'criteriaType': 'xp_threshold',
      'criteriaValue': 5000,
      'order': 31,
      'isActive': true,
    },
    
    // Social Badges
    {
      'id': 'team_player',
      'name': 'Team Player',
      'description': 'Join a classroom',
      'iconPath': 'assets/badges/team_player.png',
      'category': 'social',
      'xpBonus': 50,
      'rarity': 'common',
      'criteriaType': 'classroom_joined',
      'criteriaValue': 1,
      'order': 40,
      'isActive': true,
    },
  ];

  // Add badges to Firestore
  final batch = firestore.batch();
  for (var badge in badges) {
    final docRef = firestore.collection('badges').doc(badge['id'] as String);
    batch.set(docRef, badge);
  }
  
  await batch.commit();
  print('✅ Successfully seeded ${badges.length} badges!');
}

/// Required badge assets (add these to assets/badges/):
/// 
/// Milestone Badges:
/// - first_steps.png
/// - knowledge_seeker.png
/// - ip_scholar.png
/// - ip_master.png
/// - rising_star.png
/// - xp_champion.png
/// 
/// Streak Badges:
/// - consistent_learner.png
/// - dedicated_student.png
/// - unstoppable.png
/// 
/// Mastery Badges:
/// - copyright_expert.png
/// - trademark_expert.png
/// - patent_expert.png
/// 
/// Social Badges:
/// - team_player.png
/// 
/// Default:
/// - default_badge.png
