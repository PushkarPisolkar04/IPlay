import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/top_bar_with_avatar.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';
import '../announcements/announcements_screen.dart';
import '../student/student_progress_screen.dart';

/// Home Screen - Loads real user data from Firebase
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
        print('Loading user data for: ${currentUser.uid}');
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && mounted) {
          final userData = doc.data()!;
          print('User data loaded: ${userData['displayName']}');
          print('Total XP: ${userData['totalXP']}');
          print('Current Streak: ${userData['currentStreak']}');
          print('Badges: ${userData['badges']?.length ?? 0}');
          
          setState(() {
            _user = UserModel.fromMap(userData);
          });
          
          // Load classroom info if student is in a classroom
          await _loadClassroomInfo(userData);
          
          setState(() => _isLoading = false);
        } else {
          print('User document does not exist!');
        }
      } else {
        print('No current user!');
      }
    } catch (e) {
      print('Error loading user data: $e');
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
        
        print('Loading classroom info: $classroomId');
        
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (classroomDoc.exists) {
          _classroomInfo = classroomDoc.data()!;
          print('Classroom loaded: ${_classroomInfo!['name']}');
          
          // Load school info if classroom has schoolId
          final schoolId = _classroomInfo!['schoolId'];
          if (schoolId != null) {
            final schoolDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .get();
            
            if (schoolDoc.exists) {
              _schoolInfo = schoolDoc.data()!;
              print('School loaded: ${_schoolInfo!['name']}');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading classroom info: $e');
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
    return Scaffold(
      backgroundColor: AppColors.background,
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
            
            // Scrollable content with pull-to-refresh
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // Greeting (real user name)
                          Text(
                            '$_greeting!',
                            style: AppTextStyles.h1,
                          ),
                          Text(
                            _user?.displayName ?? 'Student',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // XP & Level Card with gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total XP',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_user?.totalXP ?? 0}',
                                      style: AppTextStyles.h1.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Streak',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department,
                                          color: Color(0xFFF59E0B),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_user?.currentStreak ?? 0} days',
                                          style: AppTextStyles.h2.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                            'Continue',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Learning',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'IPR',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Logo
                                    Image.asset(
                                      'assets/logos/logo.png',
                                      width: 100,
                                      height: 100,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to learn tab (index 1)
                                      DefaultTabController.of(context).animateTo(1);
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
                                      builder: (_) => const AnnouncementsScreen(canEdit: false),
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
                                      builder: (_) => const StudentProgressScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
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
                                    color: AppColors.secondary,
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
                                  padding: const EdgeInsets.all(16),
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
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events,
                                          size: 28,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_user?.badges.length ?? 0}',
                                        style: AppTextStyles.h2.copyWith(
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Badges',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
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
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.workspace_premium,
                                          size: 28,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}',
                                        style: AppTextStyles.h2.copyWith(
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Realms Done',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
              color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
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
                color: AppColors.textPrimary,
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
    Key? key,
    required this.color,
    required this.child,
  }) : super(key: key);
  
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
