import 'package:cloud_firestore/cloud_firestore.dart';

/// Badge model based on complete badge system from documentation
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Asset path for badge icon
  final String category; // milestone, streak, mastery, social, special
  final int xpBonus; // XP awarded when badge is unlocked
  final String rarity; // common, rare, epic, legendary
  final String criteriaType; // xp_threshold, levels_completed, streak, etc.
  final dynamic criteriaValue; // int, string, or null depending on criteriaType
  final int order; // Display order
  final bool isActive; // Can be disabled by admins

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    String? iconPath,
    String? icon, // Backward compatibility
    String? iconEmoji, // Backward compatibility
    required this.category,
    required this.xpBonus,
    required this.rarity,
    String? criteriaType,
    dynamic criteriaValue,
    Map<String, dynamic>? condition, // Backward compatibility
    int? order,
    int? displayOrder, // Backward compatibility
    this.isActive = true,
  }) : iconPath = iconPath ?? icon ?? iconEmoji ?? 'assets/badges/default_badge.png',
       criteriaType = criteriaType ?? (condition?['type'] as String?) ?? 'manual',
       criteriaValue = criteriaValue ?? condition?['value'],
       order = order ?? displayOrder ?? 0;
  
  // Aliases for backward compatibility
  String get icon => iconPath;
  String get iconEmoji => iconPath;
  int get displayOrder => order;

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'category': category,
      'xpBonus': xpBonus,
      'rarity': rarity,
      'criteriaType': criteriaType,
      'criteriaValue': criteriaValue,
      'order': order,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory BadgeModel.fromFirestore(Map<String, dynamic> data) {
    return BadgeModel(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      iconPath: (data['iconPath'] ?? data['icon'] ?? data['iconEmoji']) as String?, // Support all field names
      category: data['category'] as String,
      xpBonus: data['xpBonus'] as int? ?? 0,
      rarity: data['rarity'] as String,
      criteriaType: data['criteriaType'] as String,
      criteriaValue: data['criteriaValue'],
      order: (data['order'] ?? data['displayOrder']) as int, // Support both field names
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Legacy: toMap for backward compatibility
  Map<String, dynamic> toMap() => toFirestore();

  /// Legacy: fromMap for backward compatibility
  factory BadgeModel.fromMap(Map<String, dynamic> map) => BadgeModel.fromFirestore(map);
}

class UserBadge {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;

  UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      userId: map['userId'] ?? '',
      badgeId: map['badgeId'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp).toDate(),
    );
  }
}

