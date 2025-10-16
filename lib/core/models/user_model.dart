import 'package:cloud_firestore/cloud_firestore.dart';

/// User model based on Firestore schema
class UserModel {
  final String uid;
  final String email;
  final String role; // 'student' | 'teacher' | 'admin'
  
  // Profile
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final String state;
  final String? schoolTag;
  
  // Role-specific
  final bool isPrincipal;
  final String? principalOfSchool;
  
  // Classroom memberships
  final List<String> classroomIds;
  final List<String> pendingClassroomRequests;
  
  // Gamification
  final int totalXP;
  final int currentStreak;
  final DateTime lastActiveDate;
  final List<String> badges;
  
  // Progress summary
  final Map<String, RealmProgress> progressSummary;
  
  // Settings
  final bool hideFromPublicLeaderboard;
  final NotificationSettings notificationSettings;
  
  // Storage (for teachers)
  final double storageUsedMB;
  
  // Metadata
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    this.username,
    this.avatarUrl,
    required this.state,
    this.schoolTag,
    this.isPrincipal = false,
    this.principalOfSchool,
    this.classroomIds = const [],
    this.pendingClassroomRequests = const [],
    this.totalXP = 0,
    this.currentStreak = 0,
    required this.lastActiveDate,
    this.badges = const [],
    this.progressSummary = const {},
    this.hideFromPublicLeaderboard = false,
    required this.notificationSettings,
    this.storageUsedMB = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'state': state,
      'schoolTag': schoolTag,
      'isPrincipal': isPrincipal,
      'principalOfSchool': principalOfSchool,
      'classroomIds': classroomIds,
      'pendingClassroomRequests': pendingClassroomRequests,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'badges': badges,
      'progressSummary': progressSummary.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'hideFromPublicLeaderboard': hideFromPublicLeaderboard,
      'notificationSettings': notificationSettings.toMap(),
      'storageUsedMB': storageUsedMB,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSyncedAt': lastSyncedAt != null ? Timestamp.fromDate(lastSyncedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      avatarUrl: data['avatarUrl'],
      state: data['state'] ?? '',
      schoolTag: data['schoolTag'],
      isPrincipal: data['isPrincipal'] ?? false,
      principalOfSchool: data['principalOfSchool'],
      classroomIds: List<String>.from(data['classroomIds'] ?? []),
      pendingClassroomRequests: List<String>.from(data['pendingClassroomRequests'] ?? []),
      totalXP: data['totalXP'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badges: List<String>.from(data['badges'] ?? []),
      progressSummary: (data['progressSummary'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, RealmProgress.fromMap(value as Map<String, dynamic>)),
          ) ?? {},
      hideFromPublicLeaderboard: data['hideFromPublicLeaderboard'] ?? false,
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] as Map<String, dynamic>? ?? {},
      ),
      storageUsedMB: (data['storageUsedMB'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncedAt: (data['lastSyncedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Alias for compatibility with old code
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      avatarUrl: data['avatarUrl'],
      state: data['state'] ?? '',
      schoolTag: data['schoolTag'],
      isPrincipal: data['isPrincipal'] ?? false,
      principalOfSchool: data['principalOfSchool'],
      classroomIds: List<String>.from(data['classroomIds'] ?? []),
      pendingClassroomRequests: List<String>.from(data['pendingClassroomRequests'] ?? []),
      totalXP: data['totalXP'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badges: List<String>.from(data['badges'] ?? []),
      progressSummary: (data['progressSummary'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, RealmProgress.fromMap(value as Map<String, dynamic>)),
          ) ?? {},
      hideFromPublicLeaderboard: data['hideFromPublicLeaderboard'] ?? false,
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] as Map<String, dynamic>? ?? {},
      ),
      storageUsedMB: (data['storageUsedMB'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncedAt: (data['lastSyncedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Copy with
  UserModel copyWith({
    String? email,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? state,
    String? schoolTag,
    int? totalXP,
    int? currentStreak,
    DateTime? lastActiveDate,
    List<String>? badges,
    List<String>? classroomIds,
    bool? hideFromPublicLeaderboard,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      role: role,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      state: state ?? this.state,
      schoolTag: schoolTag ?? this.schoolTag,
      isPrincipal: isPrincipal,
      principalOfSchool: principalOfSchool,
      classroomIds: classroomIds ?? this.classroomIds,
      pendingClassroomRequests: pendingClassroomRequests,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      badges: badges ?? this.badges,
      progressSummary: progressSummary,
      hideFromPublicLeaderboard: hideFromPublicLeaderboard ?? this.hideFromPublicLeaderboard,
      notificationSettings: notificationSettings,
      storageUsedMB: storageUsedMB,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastSyncedAt: lastSyncedAt,
    );
  }
}

/// Realm progress
class RealmProgress {
  final bool completed;
  final int levelsCompleted;
  final int totalLevels;
  final int xpEarned;
  final DateTime? lastAccessedAt;

  RealmProgress({
    this.completed = false,
    this.levelsCompleted = 0,
    required this.totalLevels,
    this.xpEarned = 0,
    this.lastAccessedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'levelsCompleted': levelsCompleted,
      'totalLevels': totalLevels,
      'xpEarned': xpEarned,
      'lastAccessedAt': lastAccessedAt != null ? Timestamp.fromDate(lastAccessedAt!) : null,
    };
  }

  factory RealmProgress.fromMap(Map<String, dynamic> map) {
    return RealmProgress(
      completed: map['completed'] ?? false,
      levelsCompleted: map['levelsCompleted'] ?? 0,
      totalLevels: map['totalLevels'] ?? 6,
      xpEarned: map['xpEarned'] ?? 0,
      lastAccessedAt: (map['lastAccessedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Notification settings
class NotificationSettings {
  final bool announcements;
  final bool badges;
  final bool joinRequests;

  const NotificationSettings({
    this.announcements = true,
    this.badges = true,
    this.joinRequests = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcements': announcements,
      'badges': badges,
      'joinRequests': joinRequests,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      announcements: map['announcements'] ?? true,
      badges: map['badges'] ?? true,
      joinRequests: map['joinRequests'] ?? true,
    );
  }
}

