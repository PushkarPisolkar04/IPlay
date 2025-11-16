import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/design/app_design_system.dart';
import '../../core/models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/notification_bell_icon.dart';
import '../../widgets/top_bar_with_avatar.dart';
import '../settings/settings_screen.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import 'create_classroom_screen.dart';
import 'classroom_detail_screen.dart';
import 'all_students_screen.dart';
import 'generate_report_screen.dart';
import '../announcements/unified_announcements_screen.dart';
import 'create_announcement_screen.dart';
// import '../assignment/create_assignment_screen.dart'; // Removed - file uploads not needed
import '../../core/services/join_request_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/join_request_model.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
    _TeacherOverviewTab(onNavigate: (index) {
      setState(() => _selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }),
    const _TeacherClassroomsTab(),
    const _TeacherAnalyticsTab(),
    const _TeacherProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.class_rounded,
                  label: 'Classes',
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Navigation Item Widget with Colored Semi-Circle Bubble
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with colored bubble background for selected item
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TEACHER OVERVIEW TAB - Matches Principal Structure
// =================================================================

class _TeacherOverviewTab extends StatefulWidget {
  final Function(int) onNavigate;
  
  const _TeacherOverviewTab({required this.onNavigate});

  @override
  State<_TeacherOverviewTab> createState() => _TeacherOverviewTabState();
}

class _TeacherOverviewTabState extends State<_TeacherOverviewTab> {
  UserModel? _user;
  String? _schoolId;
  String? _schoolName;
  Map<String, dynamic>? _schoolData;
  List<Map<String, dynamic>> _classrooms = [];
  
  int _totalClassrooms = 0;
  int _totalStudents = 0;
  int _activeStudents = 0;
  double _avgClassXP = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data()!);
        _schoolId = userDoc.data()!['schoolId'] as String?;
        
        if (_schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .get();
          if (schoolDoc.exists) {
            _schoolData = schoolDoc.data();
            _schoolData!['id'] = schoolDoc.id;
            _schoolName = _schoolData?['name'];
          }
        }
      }

        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        
        _totalClassrooms = classroomsSnapshot.docs.length;
        
        // Populate classrooms list for assignment creation
        _classrooms = classroomsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Classroom',
            'studentCount': data['studentIds']?.length ?? 0,
          };
        }).toList();
        
      int totalStudentsCount = 0;
      int activeCount = 0;
      double totalXP = 0;
      
      for (var classroomDoc in classroomsSnapshot.docs) {
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classroomIds', arrayContains: classroomDoc.id)
            .get();
        
        totalStudentsCount += studentsSnapshot.docs.length;
        
        for (var studentDoc in studentsSnapshot.docs) {
          final lastActive = studentDoc.data()['lastActiveDate'] as Timestamp?;
          if (lastActive != null) {
            final daysSinceActive = DateTime.now().difference(lastActive.toDate()).inDays;
            if (daysSinceActive <= 7) activeCount++;
          }
          totalXP += (studentDoc.data()['totalXP'] ?? 0).toDouble();
        }
      }
      
      _totalStudents = totalStudentsCount;
      _activeStudents = activeCount;
      _avgClassXP = _totalStudents > 0 ? totalXP / _totalStudents : 0;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String _getInitials() {
    if (_user == null) return 'T';
    final names = _user!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _user!.displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header skeleton
                Row(
                  children: [
                    LoadingSkeleton(
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeleton(
                            width: 150,
                            height: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          LoadingSkeleton(
                            width: 100,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats skeleton
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 6,
                          right: index == 3 ? 0 : 6,
                        ),
                        child: LoadingSkeleton(
                          height: 80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Cards skeleton
                const ListSkeleton(itemCount: 3),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with avatar, messages, and notifications
              TopBarWithAvatar(
                avatarUrl: _user?.avatarUrl,
                initials: _getInitials(),
                showOnlineBadge: true,
                onAvatarTap: () => widget.onNavigate(3), // Navigate to profile tab
              ),
              
              // Scrollable content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Greeting card with teacher gradient - matching student style
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEF4444), // Red
                            Color(0xFFF87171), // Light Red
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.displayName ?? 'Teacher',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // School icon with gradient background
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Teacher',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // School info card if available
                    if (_schoolName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _schoolName!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_schoolData != null && _schoolData!['city'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_schoolData!['city']}, ${_schoolData!['state'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              
              // Overview Section - Matching Principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Teaching Overview
                      Text(
                        'Teaching Overview',
                        style: AppDesignSystem.h4.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Grid with white cards and colored icons
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.class_,
                              value: _totalClassrooms.toString(),
                              title: 'Classes',
                              subtitle: 'Total classrooms',
                              color: const Color(0xFFEC4899),
                              onTap: () => widget.onNavigate(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people,
                              value: _totalStudents.toString(),
                              title: 'Students',
                              subtitle: 'Total students',
                              color: const Color(0xFF6366F1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllStudentsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.trending_up,
                              value: _totalStudents > 0 
                                  ? '${((_activeStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              title: 'Active Rate',
                              subtitle: 'Last 7 days',
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.stars,
                              value: _avgClassXP.toStringAsFixed(0),
                              title: 'Avg XP',
                              subtitle: 'Per student',
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: AppDesignSystem.h4.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Row 1: Create Class & Reports
                      Row(
                        children: [
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Create Class',
                              icon: Icons.add_box,
                              color: const Color(0xFF6366F1),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateClassroomScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Reports',
                              icon: Icons.assessment,
                              color: const Color(0xFFEF4444),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GenerateReportScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 2: Announcement & Students
                      Row(
                        children: [
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Announcement',
                              icon: Icons.campaign,
                              color: const Color(0xFF8B5CF6),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UnifiedAnnouncementsScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Students',
                              icon: Icons.people,
                              color: const Color(0xFF3B82F6),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AllStudentsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 3: Leaderboard (full width)
                      _buildColoredActionButton(
                        context: context,
                        text: 'Leaderboard',
                        icon: Icons.leaderboard,
                        color: const Color(0xFFF59E0B),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UnifiedLeaderboardScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Pending Join Requests Section - Only show if there are requests
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('join_requests')
                            .where('status', isEqualTo: 'pending')
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Don't show anything while loading
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          // Don't show anything on error
                          if (snapshot.hasError) {
                            return const SizedBox.shrink();
                          }

                          var requests = snapshot.data?.docs ?? [];

                          // Don't show section if no requests
                          if (requests.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Sort by requestedAt in memory (newest first)
                          requests.sort((a, b) {
                            try {
                              final aData = a.data() as Map<String, dynamic>;
                              final bData = b.data() as Map<String, dynamic>;
                              final aTime = aData['requestedAt'] as Timestamp?;
                              final bTime = bData['requestedAt'] as Timestamp?;
                              if (aTime == null || bTime == null) return 0;
                              return bTime.compareTo(aTime);
                            } catch (e) {
                              return 0;
                            }
                          });

                          // Take only first 5
                          final displayRequests = requests.take(5).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Join Requests',
                                style: AppDesignSystem.h4.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...displayRequests.map((doc) {
                                try {
                                  final request = JoinRequestModel.fromFirestore(
                                    doc.data() as Map<String, dynamic>,
                                  );
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _PendingRequestCard(
                                      request: request,
                                      onApproved: _loadData,
                                      onRejected: _loadData,
                                    ),
                                  );
                                } catch (e) {
                                  return const SizedBox.shrink();
                                }
                              }).toList(),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColoredActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    // Create a lighter shade for gradient
    final lightColor = Color.lerp(color, Colors.white, 0.2)!;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, lightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, lightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TEACHER CLASSROOMS TAB
// =================================================================

class _TeacherClassroomsTab extends StatelessWidget {
  const _TeacherClassroomsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // App bar matching student style
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 48), // Balance for symmetry
                    const Expanded(
                      child: Center(
                        child: Text(
                          'My Classes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateClassroomScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Classrooms List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classrooms')
                    .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                          Icon(Icons.class_, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No classes yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
          const SizedBox(height: 8),
                          Text(
                            'Create your first class to get started',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateClassroomScreen()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Class'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
        ],
      ),
    );
  }
  
                  final classrooms = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: classrooms.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final classroom = classrooms[index].data() as Map<String, dynamic>;
                      final classroomId = classrooms[index].id;
                      final studentIds = (classroom['studentIds'] as List?)?.cast<String>() ?? [];

                      return FutureBuilder<int>(
                        future: _getActiveStudentCountForCard(studentIds),
                        builder: (context, countSnapshot) {
                          final studentCount = countSnapshot.data ?? 0;
                          
                          return CleanCard(
                        child: InkWell(
                          onTap: () {
                            try {
                              final classroomModel = ClassroomModel.fromMap({
                                'id': classroomId,
                                ...classroom,
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClassroomDetailScreen(
                                    classroom: classroomModel,
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error opening classroom: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Class icon with purple gradient
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.class_,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Class info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Grade and number in one row
                                      Row(
                                        children: [
                                          Text(
                                            'Grade ',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Color(0xFF1F2937),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            classroom['grade'] ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Color(0xFF1F2937),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Class name
                                      Text(
                                        classroom['name'] ?? 'Unnamed Class',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Student count
                                      Row(
                                        children: [
                                          const Icon(Icons.people, size: 18, color: Color(0xFF6B7280)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                                            style: const TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow icon
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static Future<int> _getActiveStudentCountForCard(List<String> studentIds) async {
    int count = 0;
    for (String studentId in studentIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final isDeleted = data['isDeleted'] == true;
          if (!isDeleted) {
            count++;
          }
        }
      } catch (e) {
        continue;
      }
    }
    return count;
  }
}

// =================================================================
// TEACHER ANALYTICS TAB - Now Functional
// =================================================================

class _TeacherAnalyticsTab extends StatefulWidget {
  const _TeacherAnalyticsTab();

  @override
  State<_TeacherAnalyticsTab> createState() => _TeacherAnalyticsTabState();
}

class _TeacherAnalyticsTabState extends State<_TeacherAnalyticsTab> {
  bool _isLoading = true;
  int _totalStudents = 0;
  int _activeStudents = 0;
  int _totalClasses = 0;
  double _avgCompletion = 0.0;
  List<Map<String, dynamic>> _topPerformers = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
              .get();
          
      _totalClasses = classroomsSnapshot.docs.length;

      int totalStudentsCount = 0;
      int activeCount = 0;
      double totalCompletion = 0;

      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final studentIds = List<String>.from(classroomData['studentIds'] ?? []);
        
        for (String studentId in studentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (!studentDoc.exists) continue;
          
          final studentData = studentDoc.data()!;
          
          // Skip deleted users
          final isDeleted = studentData['isDeleted'] == true;
          if (isDeleted) continue;
          
          // Count only active students
          totalStudentsCount++;
          
          final lastActive = studentData['lastActiveDate'] as Timestamp?;
          if (lastActive != null) {
            final daysSinceActive = DateTime.now().difference(lastActive.toDate()).inDays;
            if (daysSinceActive <= 7) activeCount++;
          }

          // Calculate average completion
          final progressSummary = studentData['progressSummary'] as Map<String, dynamic>?;
          if (progressSummary != null) {
            int completed = 0;
            int total = progressSummary.length;
            progressSummary.forEach((key, value) {
              if (value['completed'] == true) completed++;
            });
            if (total > 0) {
              totalCompletion += (completed / total) * 100;
            }
          }
        }
      }

      _totalStudents = totalStudentsCount;
      _activeStudents = activeCount;
      _avgCompletion = _totalStudents > 0 ? totalCompletion / _totalStudents : 0;

      // Load top performers
      await _loadTopPerformers(currentUser.uid);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTopPerformers(String teacherId) async {
    try {
      // Get all students from teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      List<Map<String, dynamic>> allStudents = [];

      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final studentIds = List<String>.from(classroomData['studentIds'] ?? []);
        
        for (String studentId in studentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (!studentDoc.exists) continue;
          
          final studentData = studentDoc.data()!;
          allStudents.add({
            'id': studentDoc.id,
            'name': studentData['displayName'] ?? 'Unknown',
            'totalXP': studentData['totalXP'] ?? 0,
            'avatarUrl': studentData['avatarUrl'],
          });
        }
      }

      // Sort by XP and take top 5
      allStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
      _topPerformers = allStudents.take(5).toList();
    } catch (e) {
      // print('Error loading top performers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats skeleton
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 6,
                          right: index == 2 ? 0 : 6,
                        ),
                        child: LoadingSkeleton(
                          height: 100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Chart skeleton
                LoadingSkeleton(
                  height: 200,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 24),
                // List skeleton
                const ListSkeleton(itemCount: 5),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Gradient Header
            Container(
                  decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                    borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: const Center(
                child: Text(
                  'Analytics',
                            style: TextStyle(
                    fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                          fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Analytics Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _buildAnalyticsCard(
                          'Total Students',
                          _totalStudents.toString(),
                          Icons.people,
                          const Color(0xFF3B82F6),
                        ),
                        _buildAnalyticsCard(
                          'Active (7d)',
                          _activeStudents.toString(),
                          Icons.trending_up,
                          const Color(0xFFEF4444),
                        ),
                        _buildAnalyticsCard(
                          'Total Classes',
                          _totalClasses.toString(),
                          Icons.class_,
                          const Color(0xFF8B5CF6),
                        ),
                        _buildAnalyticsCard(
                          'Avg Completion',
                          '${_avgCompletion.toStringAsFixed(1)}%',
                          Icons.check_circle,
                          const Color(0xFFF59E0B),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Engagement Metrics',
                          style: TextStyle(
                        fontSize: 20,
                            fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    CleanCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                              'Active Students Rate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                              Row(
                                children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: _totalStudents > 0 ? _activeStudents / _totalStudents : 0,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  ),
                                  const SizedBox(width: 12),
                                        Text(
                                  _totalStudents > 0
                                      ? '${((_activeStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                          ),
                                        ),
                              ],
                            ),
                            const SizedBox(height: 8),
                                        Text(
                              '$_activeStudents out of $_totalStudents students active in last 7 days',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                    ),

                    const SizedBox(height: 24),

                    // Performance Chart
                    const Text(
                      'Student Progress Distribution',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),

                    CleanCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 200,
                          child: _buildProgressChart(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top Performers Section
                    const Text(
                      'Top Performers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                              ),
                              const SizedBox(height: 16),

                    if (_topPerformers.isEmpty)
                      CleanCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No student data yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._topPerformers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CleanCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Rank
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: index == 0
                                            ? const Color(0xFFFFD700)
                                            : index == 1
                                                ? const Color(0xFFC0C0C0)
                                                : index == 2
                                                    ? const Color(0xFFCD7F32)
                                                    : Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Avatar
                                  AvatarWidget(
                                    imageUrl: student['avatarUrl'],
                                    initials: (student['name'] as String).substring(0, 1).toUpperCase(),
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  // Name
                                  Expanded(
                                    child: Text(
                                      student['name'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // XP
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${student['totalXP']} XP',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                  ),
                ),
              ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, lightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    // Sample data - in real implementation, fetch from Firestore
    final data = [
      _ChartData('0-25%', _totalStudents > 0 ? (_totalStudents * 0.1).round() : 0, const Color(0xFFEF4444)),
      _ChartData('26-50%', _totalStudents > 0 ? (_totalStudents * 0.2).round() : 0, const Color(0xFFF59E0B)),
      _ChartData('51-75%', _totalStudents > 0 ? (_totalStudents * 0.3).round() : 0, const Color(0xFF3B82F6)),
      _ChartData('76-100%', _totalStudents > 0 ? (_totalStudents * 0.4).round() : 0, const Color(0xFF10B981)),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x.toInt()].label}\n${rod.toY.round()} students',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()].label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: entry.value.color,
                width: 40,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}

// =================================================================
// TEACHER PROFILE TAB - Matches Principal with Data
// =================================================================

class _TeacherProfileTab extends StatefulWidget {
  const _TeacherProfileTab();

  @override
  State<_TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<_TeacherProfileTab> {
  UserModel? _user;
  String? _schoolId;
  String? _schoolName;
  Map<String, dynamic>? _schoolData;
  int _totalClassrooms = 0;
  int _totalStudents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!);
        _schoolId = userDoc.data()!['schoolId'] as String?;

        if (_schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .get();
          if (schoolDoc.exists) {
            _schoolData = schoolDoc.data();
            _schoolData!['id'] = schoolDoc.id;
            _schoolName = _schoolData?['name'];
          }
        }
      }

      // Get classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();
      
      _totalClassrooms = classroomsSnapshot.docs.length;
      
      // Count unique students across all classrooms
      Set<String> uniqueStudentIds = {};
      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final studentIds = (classroomData['studentIds'] as List?)?.cast<String>() ?? [];
        uniqueStudentIds.addAll(studentIds);
      }
      
      // Verify students exist and are not deleted
      int validStudentCount = 0;
      for (String studentId in uniqueStudentIds) {
        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>;
            final role = studentData['role'] as String?;
            final isDeleted = studentData['isDeleted'] == true;
            
            if (role == 'student' && !isDeleted) {
              validStudentCount++;
            }
          }
        } catch (e) {
          continue;
        }
      }
      _totalStudents = validStudentCount;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading teacher profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String _getInitials() {
    if (_user == null) return 'T';
    final names = _user!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _user!.displayName[0].toUpperCase();
  }

    @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LoadingSkeleton(
                  height: 200,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 8,
                          right: index == 2 ? 0 : 8,
                        ),
                        child: LoadingSkeleton(
                          height: 100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const ListSkeleton(itemCount: 2),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 24),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ).then((_) => _loadData());
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: AvatarWidget(
                      initials: _getInitials(),
                      size: 90,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      imageUrl: _user?.avatarUrl,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user?.displayName ?? 'Teacher',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Teacher',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.class_,
                    value: _totalClassrooms.toString(),
                    label: 'Classes',
                    color: const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    value: _totalStudents.toString(),
                    label: 'Students',
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // School Information (Only once!)
            if (_schoolData != null) ...[
              const Text(
                'School Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              CleanCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.school, 'School Name', _schoolData!['name'] ?? 'N/A'),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        '${_schoolData!['city'] ?? 'N/A'}, ${_schoolData!['state'] ?? 'N/A'}',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.qr_code, 'School Code', _schoolData!['schoolCode'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Stat Card
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEF4444), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
        ),
      ],
    );
  }
}

  Widget _buildQuickLinkCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
          onTap: onTap,
      child: CleanCard(
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
                      Text(
                        title,
                textAlign: TextAlign.center,
                        style: const TextStyle(
                  fontSize: 12,
                          fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
              children: [
        Icon(icon, color: const Color(0xFFEF4444), size: 20),
        const SizedBox(width: 12),
                Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                    style: const TextStyle(
                  fontSize: 15,
                      fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                ),
              ],
            ),
          ),
      ],
    );
  }


// =================================================================
// HELPER WIDGETS
// =================================================================

/// Widget for displaying pending join request with quick approve/reject actions
class _PendingRequestCard extends StatefulWidget {
  final JoinRequestModel request;
  final VoidCallback onApproved;
  final VoidCallback onRejected;

  const _PendingRequestCard({
    required this.request,
    required this.onApproved,
    required this.onRejected,
  });

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard> {
  final JoinRequestService _joinRequestService = JoinRequestService();
  final NotificationService _notificationService = NotificationService();
  bool _isProcessing = false;

  Future<void> _approveRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser!.uid;

      await _joinRequestService.approveRequest(
        requestId: widget.request.id,
        teacherId: teacherId,
      );

      await _notificationService.sendToUser(
        userId: widget.request.studentId,
        title: 'Join Request Approved',
        body: 'Your request to join the classroom has been approved!',
        data: {
          'type': 'join_request_approved',
          'classroomId': widget.request.classroomId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onApproved();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser!.uid;

      await _joinRequestService.rejectRequest(
        requestId: widget.request.id,
        teacherId: teacherId,
        reason: 'Rejected by teacher',
      );

      await _notificationService.sendToUser(
        userId: widget.request.studentId,
        title: 'Join Request Rejected',
        body: 'Your request to join the classroom was not approved.',
        data: {
          'type': 'join_request_rejected',
          'classroomId': widget.request.classroomId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      widget.onRejected();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppDesignSystem.warning.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_add,
                color: AppDesignSystem.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.studentName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested to join',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                children: [
                  IconButton(
                    onPressed: _approveRequest,
                    icon: const Icon(Icons.check_circle),
                    color: AppDesignSystem.success,
                    iconSize: 28,
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: _rejectRequest,
                    icon: const Icon(Icons.cancel),
                    color: AppDesignSystem.error,
                    iconSize: 28,
                    tooltip: 'Reject',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying recent activity items
class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final userId = activity['userId'] as String?;
    final levelId = activity['levelId'] as String?;
    final completedAt = activity['completedAt'] as Timestamp?;

    if (userId == null || levelId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String userName = 'Student';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          userName = userData['displayName'] ?? 'Student';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
            child: Icon(
              Icons.check_circle,
              color: AppDesignSystem.primaryIndigo,
              size: 20,
            ),
          ),
          title: Text(
            userName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Completed $levelId',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: completedAt != null
              ? Text(
                  _formatTimestamp(completedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                )
              : null,
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
