import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/services/certificate_service.dart';
import '../../core/services/badge_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/realm_model.dart';
import '../../core/models/certificate_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/progress_bar.dart';
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
      _bookmarkSubscription = BookmarkService().getBookmarksStream().listen((
        snapshot,
      ) {
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
      _certificateSubscription = _certificateService
          .watchUserCertificates(currentUser.uid)
          .listen((certificates) {
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

  // ---------- Level / XP helpers ----------
  int _getUserLevel() {
    if (_user == null) return 1;
    return (_user!.totalXP / 100).floor() + 1;
  }

  int _getXPToNextLevel() {
    if (_user == null) return 100;
    final currentLevel = _getUserLevel();
    final xpForNextLevel = currentLevel * 100;
    return xpForNextLevel - _user!.totalXP;
  }

  double _getLevelProgress() {
    if (_user == null) return 0.0;
    final currentLevel = _getUserLevel();
    final xpForCurrentLevel = (currentLevel - 1) * 100;
    final xpInCurrentLevel = _user!.totalXP - xpForCurrentLevel;
    return (xpInCurrentLevel / 100).clamp(0.0, 1.0);
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
        body: const Center(child: Text('User not found')),
      );
    }

    final userLevel = _getUserLevel();
    final xpToNext = _getXPToNextLevel();
    final levelProgress = _getLevelProgress();
    final String initials = _user!.displayName
        .split(' ')
        .where((n) => n.isNotEmpty)
        .take(2)
        .map((n) => n[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            color: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // ---------- Profile Header ----------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: AvatarWidget(
                      initials: initials,
                      size: 90,
                      backgroundColor: AppDesignSystem.primaryPink,
                      imageUrl: _user!.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    _user!.displayName,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // State badge
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _user!.state,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Level & XP
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level $userLevel',
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                                    color: Colors.amber,
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
                        const SizedBox(height: 8),
                        ProgressBar(
                          progress: levelProgress,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          height: 6,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$xpToNext XP to Level ${userLevel + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Stats Row ----------
            Row(
              children: [
                // Streak
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(
                          '${_user!.currentStreak}',
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Streak',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Badges
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/badges'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEC4899,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏅', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            '${_user!.badges.length}',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Badges',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Certificates
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/certificates'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            '$_certificateCount',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Certificates',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Bookmarks
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/bookmarks'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔖', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            '$_bookmarkCount',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Bookmarks',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Classroom & School ----------
            if (_classroomInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryIndigo.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: AppDesignSystem.primaryIndigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Classroom',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _classroomInfo!['name'] ?? '-',
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_schoolInfo != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: AppDesignSystem.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'School',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _schoolInfo!['name'] ?? '-',
                                  style: AppTextStyles.h4.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
              const SizedBox(height: AppSpacing.md),
            ],

            // ---------- My Realms ----------
            Align(
              alignment: Alignment.centerLeft,
              child: Text('My Realms', style: AppTextStyles.sectionHeader),
            ),
            const SizedBox(height: AppSpacing.sm),

            FutureBuilder<List<RealmModel>>(
              future: _contentService.getAllRealms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppDesignSystem.primaryIndigo.withValues(
                          alpha: 0.2,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final realms = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppDesignSystem.primaryIndigo.withValues(
                        alpha: 0.2,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: realms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final realm = entry.value;
                      final realmProgress = _progressSummary[realm.id];
                      final progress =
                          realmProgress != null && realmProgress is Map
                          ? (realmProgress['levelsCompleted'] ?? 0) /
                                (realmProgress['totalLevels'] ?? 1)
                          : 0.0;

                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 24),
                          _RealmProgress(
                            icon: realm.iconPath,
                            title: realm.name,
                            progress: progress,
                            color: Color(realm.color),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            if (_user!.role == 'teacher') ...[
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/main'),
                child: CleanCard(
                  color: AppDesignSystem.primaryGreen.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.dashboard,
                              size: 32,
                              color: AppDesignSystem.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teacher Dashboard',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                  color: AppDesignSystem.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage classrooms and students',
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

            if (_user!.role == 'principal') ...[
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/main'),
                child: CleanCard(
                  color: AppDesignSystem.secondaryPurple.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.secondaryPurple.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 32,
                              color: AppDesignSystem.secondaryPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Principal Dashboard',
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                  color: AppDesignSystem.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage school and analytics',
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

            // ---------- Badges ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges (${_user!.badges.length})',
                  style: AppTextStyles.sectionHeader,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/badges'),
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

            _BadgeGridWidget(userId: _user!.uid, unlockedBadges: _user!.badges),

            const SizedBox(height: AppSpacing.lg),

            // ---------- Certificates ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Certificates ($_certificateCount)',
                  style: AppTextStyles.sectionHeader,
                ),
                if (_certificateCount > 0)
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/certificates'),
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

            if (_certificateCount > 0)
              _CertificatePreviewWidget(userId: _user!.uid)
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'No certificates yet. Complete realms to earn certificates!',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
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

// ---------------------------------------------------------------------
// Realm progress item
// ---------------------------------------------------------------------
class _RealmProgress extends StatelessWidget {
  final String icon;
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
        Image.asset(
          icon,
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 24),
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
              ProgressBar(progress: progress, color: color, height: 6),
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

// ---------------------------------------------------------------------
// Badge Grid Widget
// ---------------------------------------------------------------------
class _BadgeGridWidget extends StatefulWidget {
  final String userId;
  final List<String> unlockedBadges;

  const _BadgeGridWidget({required this.userId, required this.unlockedBadges});

  @override
  State<_BadgeGridWidget> createState() => _BadgeGridWidgetState();
}

class _BadgeGridWidgetState extends State<_BadgeGridWidget> {
  final BadgeService _badgeService = BadgeService();
  List<BadgeModel> _allBadges = [];
  final Map<String, DateTime> _badgeUnlockDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      // Get all badges from JSON using BadgeService
      final allBadgesFromService = await _badgeService.getAllBadges();

      // Get unlock dates
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

      // Filter to only show badges that user has unlocked
      _allBadges = allBadgesFromService
          .where((badge) => widget.unlockedBadges.contains(badge.id))
          .toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading badges: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return const Color(0xFF9333EA);
      case 'rare':
        return const Color(0xFF3B82F6);
      case 'uncommon':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'No badges yet. Complete levels to earn badges!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show max 6 badges for preview (3 per row)
    final badgesToShow = _allBadges.take(6).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.9,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badgesToShow.length,
      itemBuilder: (context, index) {
        final badge = badgesToShow[index];
        final unlockDate = _badgeUnlockDates[badge.id];

        return _BadgeItem(
          icon: badge.iconPath,
          name: badge.name,
          isUnlocked: true,
          unlockDate: unlockDate,
          rarity: badge.rarity,
          description: badge.description,
          rarityColor: _getRarityColor(badge.rarity),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Badge Item
// ---------------------------------------------------------------------
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                icon,
                fit: BoxFit.contain,
                color: isUnlocked ? null : Colors.grey,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.emoji_events, size: 48, color: rarityColor),
              ),
            ),
          ),
          if (unlockDate != null && isUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formatDate(unlockDate!),
                style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Certificate Preview Widget
// ---------------------------------------------------------------------
class _CertificatePreviewWidget extends StatefulWidget {
  final String userId;

  const _CertificatePreviewWidget({required this.userId});

  @override
  State<_CertificatePreviewWidget> createState() =>
      _CertificatePreviewWidgetState();
}

class _CertificatePreviewWidgetState extends State<_CertificatePreviewWidget> {
  final CertificateService _certificateService = CertificateService();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final certificates = await _certificateService.getUserCertificates(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRealmLogo(String realmId) {
    switch (realmId) {
      case 'realm_copyright':
        return 'assets/logos/copyright_logo.png';
      case 'realm_trademark':
        return 'assets/logos/trademark_logo.png';
      case 'realm_patent':
        return 'assets/logos/patent_logo.png';
      case 'realm_design':
        return 'assets/logos/design_logo.png';
      case 'realm_gi':
        return 'assets/logos/gi_logo.png';
      case 'realm_trade_secrets':
        return 'assets/logos/trade_secrets_logo.png';
      default:
        return 'assets/logos/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show max 3 certificates
    final certsToShow = _certificates.take(3).toList();

    return Column(
      children: [
        ...certsToShow.map(
          (cert) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/certificates'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Realm logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          _getRealmLogo(cert.realmId),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.workspace_premium,
                            size: 24,
                            color: AppDesignSystem.primaryIndigo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.realmName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cert.certificateNumber,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppDesignSystem.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppDesignSystem.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_certificates.length > 3)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/certificates'),
            child: Text(
              'View All ${_certificates.length} Certificates',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
