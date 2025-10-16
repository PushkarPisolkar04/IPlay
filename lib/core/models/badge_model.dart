import 'package:cloud_firestore/cloud_firestore.dart';

/// Badge model for gamification
/// Collection: /badges
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'milestone' | 'streak' | 'mastery' | 'social' | 'special'
  final String rarity; // 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
  final String iconEmoji;
  final int xpBonus; // Bonus XP awarded when badge is unlocked
  final Map<String, dynamic> condition; // Badge unlock condition
  final int displayOrder;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.iconEmoji,
    this.xpBonus = 0,
    required this.condition,
    required this.displayOrder,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rarity': rarity,
      'iconEmoji': iconEmoji,
      'xpBonus': xpBonus,
      'condition': condition,
      'displayOrder': displayOrder,
    };
  }

  /// Create from Firestore document
  factory BadgeModel.fromFirestore(Map<String, dynamic> data) {
    return BadgeModel(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      rarity: data['rarity'] as String,
      iconEmoji: data['iconEmoji'] as String,
      xpBonus: data['xpBonus'] as int? ?? 0,
      condition: Map<String, dynamic>.from(data['condition'] ?? {}),
      displayOrder: data['displayOrder'] as int,
    );
  }
}

