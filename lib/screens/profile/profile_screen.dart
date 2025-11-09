import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/services/certificate_service.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/loading_skeleton.dart';
import '../../services/bookmark_service.dart';

/// Profile Screen - User profile with stats and progress
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ContentService _contentService = ContentService();
  final CertificateService _certificateService = CertificateService();
  UserModel? _user;
  Map<String, dynamic> _progressSummary = {};
  Map<String, dynamic>? _classroomInfo;
  Map<String, dynamic>? _schoolInfo;
  int _certificateCount = 0;
  int _bookmarkCount = 0;
  bool _isLoading = true;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<QuerySnapshot>? _bookmarkSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<List<dynamic>>? _certificateSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRealtimeListener();
    _setupCertificateListener();
    _setupBookmarkListener();
  }

  void _setupBookmarkListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Listen to bookmark changes in real-time
      _bookmarkSubscription = BookmarkService().getBookmarksStream().listen((snapshot) {
        if (mounted) {
          setState(() {
            _bookmarkCount = snapshot.docs.length;
          });
        }
      });
    }
  }

  void _setupRealtimeListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final userData = snapshot.data()!;
          setState(() {
            _user = UserModel.fromMap(userData);
            _progressSummary = userData['progressSummary'] ?? {};
          });
        }
      });
    }
  }

  void _setupCertificateListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Listen to certificate changes in real-time
      _certificateSubscription = _certificateService.watchUserCertificates(currentUser.uid).listen((certificates) {
        if (mounted) {
          setState(() {
            _certificateCount = certificates.length;
          });
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists) {
          final userData = doc.data()!;
          setState(() {
            _user = UserModel.fromMap(userData);
            _progressSummary = userData['progressSummary'] ?? {};
          });
          
          // Load classroom and school info
          await _loadClassroomInfo(userData);
        }
      }
    } catch (e) {
      // print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassroomInfo(Map<String, dynamic> userData) async {
    try {
      final classroomIds = userData['classroomIds'] as List?;
      if (classroomIds != null && classroomIds.isNotEmpty) {
        final classroomId = classroomIds.first;
        
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (classroomDoc.exists) {
          _classroomInfo = classroomDoc.data()!;
          
          // Load school info if classroom has schoolId
          final schoolId = _classroomInfo!['schoolId'];
          if (schoolId != null) {
            final schoolDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .get();
            
            if (schoolDoc.exists) {
              _schoolInfo = schoolDoc.data()!;
            }
          }
        }
      }
    } catch (e) {
      // print('Error loading classroom info: $e');
    }
  }
  
  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    _userSubscription?.cancel();
    _certificateSubscription?.cancel();
    super.dispose();
  }

  // Calculate user level from total XP
  int _getUserLevel() {
    if (_user == null) return 1;
    // Formula: level = floor(XP / 200) + 1
    // E.g., 0-199 XP = Level 1, 200-399 = Level 2, etc.
    return (_user!.totalXP / 200).floor() + 1;
  }

  // Calculate XP needed for next level
  int _getXPToNextLevel() {
    if (_user == null) return 200;
    final currentLevel = _getUserLevel();
    final xpForNextLevel = currentLevel * 200;
    return xpForNextLevel - _user!.totalXP;
  }

  // Calculate progress towards next level
  double _getLevelProgress() {
    if (_user == null) return 0.0;
    final currentLevel = _getUserLevel();
    final xpForCurrentLevel = (currentLevel - 1) * 200;
    final xpInCurrentLevel = _user!.totalXP - xpForCurrentLevel;
    return (xpInCurrentLevel / 200).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const ProfileSkeleton(),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    final userLevel = _getUserLevel();
    final xpToNext = _getXPToNextLevel();
    final levelProgress = _getLevelProgress();
    final realms = _contentService.getAllRealms();
    final String initials = _user!.displayName.split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Notification bell
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('toUserId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          children: [
            // Large avatar
            AvatarWidget(
              initials: initials,
              size: 120,
              backgroundColor: AppDesignSystem.primaryPink,
              imageUrl: _user!.avatarUrl,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Name
            Text(
              _user!.displayName,
              style: AppTextStyles.h1,
            ),
            
            const SizedBox(height: 4),
            
            // Details
            Text(
              _user!.state,
              style: AppTextStyles.caption,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Classroom & School Info Card
            if (_classroomInfo != null) ...[
              CleanCard(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classroom',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                              Text(
                                _classroomInfo!['name'] ?? '-',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_schoolInfo != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'School',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                ),
                                Text(
                                  _schoolInfo!['name'] ?? '-',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // Sync Status Widget
            const SyncStatusWidget(),
            
            // Stats cards row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: '🔥',
                    value: '${_user!.currentStreak}',
                    label: 'Streak',
                  ),
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: _StatCard(
                    icon: '🏅',
                    value: '${_user!.badges.length}',
                    label: 'Badges',
                  ),
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: _StatCard(
                    icon: '⭐',
                    value: '$_certificateCount',
                    label: 'Certs',
                    onTap: () {
                      Navigator.pushNamed(context, '/certificates');
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.cardSpacing),
            
            // Second row of stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: '🔖',
                    value: '$_bookmarkCount',
                    label: 'Bookmarks',
                    onTap: () {
                      Navigator.pushNamed(context, '/bookmarks');
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: Container(), // Empty placeholder for symmetry
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Level card
            ColoredCard(
              color: AppDesignSystem.primaryIndigo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level $userLevel',
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_user!.totalXP} XP',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(
                    progress: levelProgress,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$xpToNext XP to Level ${userLevel + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // My Realms
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Realms',
                style: AppTextStyles.sectionHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            CleanCard(
              child: Column(
                children: realms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final realm = entry.value;
                  final realmProgress = _progressSummary[realm.id];
                  final progress = realmProgress != null && realmProgress is Map
                      ? (realmProgress['levelsCompleted'] ?? 0) / (realmProgress['totalLevels'] ?? 1)
                      : 0.0;
                  
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 24),
                      _RealmProgress(
                        icon: realm.iconEmoji,
                        title: realm.name,
                        progress: progress,
                        color: Color(realm.color),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Learning Insights Button
            if (_user!.role == 'student') ...[
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/insights');
                },
                child: CleanCard(
                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.insights,
                              size: 32,
                              color: AppDesignSystem.primaryIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learning Insights',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View your detailed analytics',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppDesignSystem.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // My Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges (${_user!.badges.length})',
                  style: AppTextStyles.sectionHeader,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/badges');
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppDesignSystem.primaryIndigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Badge grid with unlock dates
            _BadgeGridWidget(userId: _user!.uid, unlockedBadges: _user!.badges),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Certificates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Certificates ($_certificateCount)',
                  style: AppTextStyles.sectionHeader,
                ),
                if (_certificateCount > 0)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/certificates');
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Certificate preview or empty state
            if (_certificateCount > 0)
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/certificates');
                },
                child: CleanCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.workspace_premium,
                              size: 32,
                              color: AppDesignSystem.primaryIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Your Certificates',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view, download, or share',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppDesignSystem.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              CleanCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No certificates yet. Complete realms to earn certificates!',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Stat card
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final card = CleanCard(
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2,
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}

/// Realm progress item
class _RealmProgress extends StatelessWidget {
  final String icon; // Emoji string
  final String title;
  final double progress;
  final Color color;
  
  const _RealmProgress({
    required this.icon,
    required this.title,
    required this.progress,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ProgressBar(
                progress: progress,
                color: color,
                height: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).toInt()}%',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Badge Grid Widget - Shows unlocked and locked badges
class _BadgeGridWidget extends StatefulWidget {
  final String userId;
  final List<String> unlockedBadges;
  
  const _BadgeGridWidget({
    required this.userId,
    required this.unlockedBadges,
  });
  
  @override
  State<_BadgeGridWidget> createState() => _BadgeGridWidgetState();
}

class _BadgeGridWidgetState extends State<_BadgeGridWidget> {
  List<Map<String, dynamic>> _allBadges = [];
  final Map<String, DateTime> _badgeUnlockDates = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadBadges();
  }
  
  Future<void> _loadBadges() async {
    try {
      // Load all badge definitions
      final badgesSnapshot = await FirebaseFirestore.instance
          .collection('badges')
          .orderBy('displayOrder')
          .limit(12) // Show first 12 badges
          .get();
      
      _allBadges = badgesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Badge',
          'iconEmoji': data['iconEmoji'] ?? '🏅',
          'description': data['description'] ?? '',
          'rarity': data['rarity'] ?? 'common',
        };
      }).toList();
      
      // Load unlock dates from user's badge_unlocks subcollection
      final unlocksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('badge_unlocks')
          .get();
      
      for (var doc in unlocksSnapshot.docs) {
        final data = doc.data();
        final badgeId = data['badgeId'] as String?;
        final unlockedAt = (data['unlockedAt'] as Timestamp?)?.toDate();
        if (badgeId != null && unlockedAt != null) {
          _badgeUnlockDates[badgeId] = unlockedAt;
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading badges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFF9333EA); // Purple
      case 'rare':
        return const Color(0xFF3B82F6); // Blue
      case 'uncommon':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_allBadges.isEmpty) {
      return CleanCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'No badges yet. Complete levels to earn badges!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allBadges.length,
      itemBuilder: (context, index) {
        final badge = _allBadges[index];
        final badgeId = badge['id'];
        final isUnlocked = widget.unlockedBadges.contains(badgeId);
        final unlockDate = _badgeUnlockDates[badgeId];
        
        return _BadgeItem(
          icon: badge['iconEmoji'],
          name: badge['name'],
          isUnlocked: isUnlocked,
          unlockDate: unlockDate,
          rarity: badge['rarity'],
          description: badge['description'],
          rarityColor: _getRarityColor(badge['rarity']),
        );
      },
    );
  }
}

/// Badge item with unlock status
class _BadgeItem extends StatelessWidget {
  final String icon;
  final String name;
  final bool isUnlocked;
  final DateTime? unlockDate;
  final String rarity;
  final String description;
  final Color rarityColor;
  
  const _BadgeItem({
    required this.icon,
    required this.name,
    required this.isUnlocked,
    this.unlockDate,
    required this.rarity,
    required this.description,
    required this.rarityColor,
  });
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show badge details dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 64,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(description),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rarity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rarityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isUnlocked && unlockDate != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Unlocked: ${_formatDate(unlockDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (!isUnlocked) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '🔒 Locked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: CleanCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (unlockDate != null && isUnlocked)
              Text(
                _formatDate(unlockDate!),
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (!isUnlocked)
              const Icon(
                Icons.lock,
                size: 12,
                color: Color(0xFF9CA3AF),
              ),
          ],
        ),
      ),
    );
  }
}
