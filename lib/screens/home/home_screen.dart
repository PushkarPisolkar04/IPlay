import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/top_bar_with_avatar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/streak_indicator.dart';
import '../../widgets/xp_counter.dart';
import '../../widgets/loading_skeleton.dart';
import '../announcements/unified_announcements_screen.dart';
import '../student/my_progress_screen.dart';
import '../learn/learn_screen.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import '../teacher/classroom_detail_screen.dart';

/// Home Screen - Loads real user data from Firebase
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String _greeting = 'Good Morning';
  Map<String, dynamic>? _classroomInfo;
  Map<String, dynamic>? _schoolInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // print('Loading user data for: ${currentUser.uid}');
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && mounted) {
          final userData = doc.data()!;
          // print('User data loaded: ${userData['displayName']}');
          // print('Total XP: ${userData['totalXP']}');
          // print('Current Streak: ${userData['currentStreak']}');
          // print('Badges: ${userData['badges']?.length ?? 0}');
          
          setState(() {
            _user = UserModel.fromMap(userData);
          });
          
          // Load classroom info if student is in a classroom
          await _loadClassroomInfo(userData);
          
          setState(() => _isLoading = false);
        } else {
          // print('User document does not exist!');
        }
      } else {
        // print('No current user!');
      }
    } catch (e) {
      // print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadClassroomInfo(Map<String, dynamic> userData) async {
    try {
      // Check if user has classroomIds
      final classroomIds = userData['classroomIds'] as List?;
      if (classroomIds != null && classroomIds.isNotEmpty) {
        final classroomId = classroomIds.first;
        
        // print('Loading classroom info: $classroomId');
        
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (classroomDoc.exists) {
          _classroomInfo = classroomDoc.data()!;
          // print('Classroom loaded: ${_classroomInfo!['name']}');
          
          // Load school info if classroom has schoolId
          final schoolId = _classroomInfo!['schoolId'];
          if (schoolId != null) {
            final schoolDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .get();
            
            if (schoolDoc.exists) {
              _schoolInfo = schoolDoc.data()!;
              // print('School loaded: ${_schoolInfo!['name']}');
            }
          }
        }
      }
    } catch (e) {
      // print('Error loading classroom info: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
  }

  String _getInitials() {
    if (_user == null) return 'U';
    final names = _user!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _user!.displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with avatar (navigates to profile)
            TopBarWithAvatar(
              avatarUrl: _user?.avatarUrl,
              initials: _getInitials(),
              showOnlineBadge: true,
              onAvatarTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            
            // Scrollable content with pull-to-refresh and real-time updates
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LoadingSkeleton(height: 120, borderRadius: BorderRadius.all(Radius.circular(12))),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                              SizedBox(width: 12),
                              Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                            ],
                          ),
                          SizedBox(height: 16),
                          LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
                        ],
                      ),
                    )
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // Use cached data while waiting for stream
                        UserModel? streamUser = _user;
                        
                        if (snapshot.hasData && snapshot.data!.exists) {
                          streamUser = UserModel.fromMap(
                            snapshot.data!.data() as Map<String, dynamic>,
                          );
                        }
                        
                        return RefreshIndicator(
                          onRefresh: _refreshData,
                          color: AppDesignSystem.primaryIndigo,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenHorizontal,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                
                                // Greeting with avatar and streak (real-time)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_greeting!',
                                            style: AppTextStyles.h1,
                                          ),
                                          Text(
                                            streamUser?.displayName ?? 'Student',
                                            style: AppTextStyles.h3.copyWith(
                                              color: AppDesignSystem.primaryPink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StreakIndicator(
                                      currentStreak: streamUser?.currentStreak ?? 0,
                                      maxStreak: streamUser?.currentStreak ?? 0,
                                      isActive: true,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppSpacing.lg),
                                
                                // Quick Stats Row with animated XP
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: AppDesignSystem.primaryAmber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          border: Border.all(
                                            color: AppDesignSystem.primaryAmber.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () => Navigator.pushNamed(context, '/profile'),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.stars,
                                                color: AppDesignSystem.primaryAmber,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              XPCounter(
                                                xp: streamUser?.totalXP ?? 0,
                                              ),
                                              Text(
                                                'Total XP',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppDesignSystem.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.cardSpacing),
                                    Expanded(
                                      child: StatCard(
                                        title: 'Badges',
                                        value: '${streamUser?.badges.length ?? 0}',
                                        icon: Icons.emoji_events,
                                        color: AppDesignSystem.primaryPink,
                                        onTap: () => Navigator.pushNamed(context, '/badges'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.cardSpacing),
                                    Expanded(
                                      child: StatCard(
                                        title: 'Rank',
                                        value: '-',
                                        icon: Icons.leaderboard,
                                        color: AppDesignSystem.primaryIndigo,
                                        subtitle: 'Coming soon',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const UnifiedLeaderboardScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Daily Challenge Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: AppDesignSystem.gradientWarning,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: AppDesignSystem.shadowMD,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Daily Challenge',
                                            style: AppTextStyles.h4.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Complete today\'s challenge for bonus XP!',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/daily-challenge');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppDesignSystem.primaryAmber,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Challenge',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Classroom & School Info Card (if exists)
                          if (_classroomInfo != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.school,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _classroomInfo!['name'] ?? 'Classroom',
                                              style: AppTextStyles.h3.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_schoolInfo != null)
                                              Text(
                                                _schoolInfo!['name'] ?? '',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Grade',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                              Text(
                                                '${_classroomInfo!['grade'] ?? '-'}',
                                                style: AppTextStyles.h3.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Students',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                              Text(
                                                '${(_classroomInfo!['studentIds'] as List?)?.length ?? 0}',
                                                style: AppTextStyles.h3.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          
                          // Continue Learning Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Continue Learning',
                                style: AppTextStyles.sectionHeader,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LearnScreen(),
                                    ),
                                  );
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
                          
                          // Featured card (Continue Learning) with gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Your',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'IPR Journey',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '6 Realms • 40+ Levels',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Logo
                                    Image.asset(
                                      'assets/logos/logo.png',
                                      width: 80,
                                      height: 80,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LearnScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF10B981),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Learning →',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Recommended for You Section
                          Text(
                            'Recommended for You',
                            style: AppTextStyles.sectionHeader,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          
                          CleanCard(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('©️', style: TextStyle(fontSize: 24)),
                                  ),
                                  title: const Text('Copyright Basics'),
                                  subtitle: const Text('Start with the fundamentals'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LearnScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('™️', style: TextStyle(fontSize: 24)),
                                  ),
                                  title: const Text('Trademark Essentials'),
                                  subtitle: const Text('Protect your brand'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LearnScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Quick Actions Section
                          Text(
                            'Quick Actions',
                            style: AppTextStyles.sectionHeader,
                          ),
                          
                          const SizedBox(height: AppSpacing.sm),
                          
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.cardSpacing,
                            mainAxisSpacing: AppSpacing.cardSpacing,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.3,
                            children: [
                              // Join Classroom
                              _buildActionCard(
                                context,
                                icon: Icons.add_circle_outline,
                                title: 'Join\nClassroom',
                                color: const Color(0xFF10B981),
                                onTap: () {
                                  Navigator.pushNamed(context, '/join-classroom');
                                },
                              ),
                              // View Announcements (opens dedicated screen)
                              _buildActionCard(
                                context,
                                icon: Icons.campaign_outlined,
                                title: 'View\nAnnouncements',
                                color: const Color(0xFFF59E0B),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UnifiedAnnouncementsScreen(),
                                    ),
                                  );
                                },
                              ),
                              // My Badges
                              _buildActionCard(
                                context,
                                icon: Icons.emoji_events_outlined,
                                title: 'My\nBadges',
                                color: const Color(0xFF8B5CF6),
                                onTap: () {
                                  Navigator.pushNamed(context, '/badges');
                                },
                              ),
                              // Progress Report
                              _buildActionCard(
                                context,
                                icon: Icons.assessment_outlined,
                                title: 'My\nProgress',
                                color: const Color(0xFFEC4899),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyProgressScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Recent Activity Feed (if in classroom)
                          if (_classroomInfo != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Activity',
                                  style: AppTextStyles.sectionHeader,
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (_classroomInfo != null) {
                                      final classroom = ClassroomModel.fromMap(_classroomInfo!);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ClassroomDetailScreen(classroom: classroom),
                                        ),
                                      );
                                    }
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
                            
                            CleanCard(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppDesignSystem.success.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.emoji_events,
                                        color: AppDesignSystem.success,
                                        size: 20,
                                      ),
                                    ),
                                    title: const Text('New badge unlocked!'),
                                    subtitle: const Text('First Steps - Complete your first level'),
                                    trailing: const Text('2h ago', style: TextStyle(fontSize: 12)),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppDesignSystem.info.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.announcement,
                                        color: AppDesignSystem.info,
                                        size: 20,
                                      ),
                                    ),
                                    title: const Text('New announcement'),
                                    subtitle: const Text('Check the latest updates from your teacher'),
                                    trailing: const Text('1d ago', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          
                          // My Stats section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Stats',
                                style: AppTextStyles.sectionHeader,
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to profile
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: Text(
                                  'View Profile',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppDesignSystem.primaryPink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.sm),
                          
                          // Stats cards with improved styling
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                        Icons.emoji_events,
                                          size: 26,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${_user?.badges.length ?? 0}',
                                        style: AppTextStyles.h2.copyWith(
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Badges',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppDesignSystem.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                        Icons.workspace_premium,
                                          size: 26,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}',
                                        style: AppTextStyles.h2.copyWith(
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Realms Done',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppDesignSystem.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total XP: ${_user?.totalXP ?? 0}'),
            const SizedBox(height: 8),
            Text('Current Streak: ${_user?.currentStreak ?? 0} days'),
            const SizedBox(height: 8),
            Text('Badges Earned: ${_user?.badges.length ?? 0}'),
            const SizedBox(height: 8),
            Text('Realms Completed: ${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}'),
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
  }

  // Helper method to build action cards
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppDesignSystem.textPrimary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored card widget
class ColoredCard extends StatelessWidget {
  final Color color;
  final Widget child;
  
  const ColoredCard({
    super.key,
    required this.color,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: child,
    );
  }
}
