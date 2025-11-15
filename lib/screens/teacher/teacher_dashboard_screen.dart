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
import '../settings/settings_screen.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import 'create_classroom_screen.dart';
import 'classroom_detail_screen.dart';
import 'all_students_screen.dart';
import 'student_progress_screen.dart';
import 'quiz_performance_screen.dart';
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
          gradient: const LinearGradient(
            colors: [Color(0xFFF9FAFB), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.class_rounded, 'Classes'),
                _buildNavItem(2, Icons.analytics_rounded, 'Analytics'),
                _buildNavItem(3, Icons.person_rounded, 'Profile'),
                  ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header with gradient
              Container(
                  decoration: BoxDecoration(
                    gradient: AppDesignSystem.getRoleGradient('teacher'),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                    Text(
                      _getGreeting(),
                                style: AppDesignSystem.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?.displayName ?? 'Teacher',
                                style: AppDesignSystem.h2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                            ],
                          ),
                          ),
                          Row(
                            children: [
                              // Notification bell icon
                              const NotificationBellIcon(),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppDesignSystem.shadowSM,
                                ),
                                child: Text(
                                  'Teacher',
                                  style: AppDesignSystem.bodySmall.copyWith(
                                    color: AppDesignSystem.primaryPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      if (_schoolName != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.school, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _schoolName!,
                                  style: AppDesignSystem.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
              ),
              
                const SizedBox(height: 24),
              
                // Overview Section - Matching Principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // School Information Card (if teacher is part of a school)
                      if (_schoolData != null) ...[
                        CleanCard(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    Row(
                      children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.school, color: Colors.white, size: 24),
                                    ),
                        const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _schoolData!['name'] ?? 'School',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                  Row(
                    children: [
                                              const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${_schoolData!['city'] ?? ''}, ${_schoolData!['state'] ?? ''}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      Text(
                        'Teaching Overview',
                        style: AppDesignSystem.h4,
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Grid with new StatCard widgets
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Classes',
                              value: _totalClassrooms.toString(),
                              icon: Icons.class_,
                              color: AppDesignSystem.primaryPink,
                              subtitle: 'Active',
                              onTap: () => widget.onNavigate(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Students',
                              value: _totalStudents.toString(),
                              icon: Icons.people,
                              color: AppDesignSystem.primaryIndigo,
                              subtitle: '$_activeStudents active',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Active Rate',
                              value: _totalStudents > 0 
                                  ? '${((_activeStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              icon: Icons.trending_up,
                              color: AppDesignSystem.primaryAmber,
                              subtitle: 'Last 7 days',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Avg XP',
                              value: _avgClassXP.toStringAsFixed(0),
                              icon: Icons.stars,
                              color: AppDesignSystem.secondaryPurple,
                              subtitle: 'Per student',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions with new AppButton widgets
                      Text(
                        'Quick Actions',
                        style: AppDesignSystem.h4,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: AppButton.primary(
                              text: 'Create Class',
                              icon: Icons.add_box,
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
                            child: AppButton.secondary(
                              text: 'Announce',
                              icon: Icons.campaign,
                              onPressed: () {
                                // Navigate to create announcement with optional classroom selection
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateAnnouncementScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.accent(
                              text: 'Assignment',
                              icon: Icons.assignment,
                              onPressed: () {
                                // Assignment creation removed - file uploads not needed
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Assignment creation feature has been removed'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.outline(
                              text: 'Reports',
                              icon: Icons.assessment,
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
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              text: 'Messages',
                              icon: Icons.chat_bubble_outline,
                              onPressed: () {
                                Navigator.pushNamed(context, '/chat-list');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pending Join Requests Section with Quick Actions
                      Text(
                        'Pending Join Requests',
                        style: AppDesignSystem.h4,
                      ),
                      const SizedBox(height: 16),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('join_requests')
                            .where('status', isEqualTo: 'pending')
                            .orderBy('requestedAt', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final requests = snapshot.data!.docs;

                          if (requests.isEmpty) {
                            return CleanCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No pending requests',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: requests.map((doc) {
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
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Recent Activity Feed
                      Text(
                        'Recent Activity',
                        style: AppDesignSystem.h4,
                      ),
                      const SizedBox(height: 16),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('progress')
                            .orderBy('completedAt', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final activities = snapshot.data!.docs;

                          if (activities.isEmpty) {
                            return CleanCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No recent activity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return CleanCard(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length > 5 ? 5 : activities.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final activity = activities[index].data() as Map<String, dynamic>;
                                return _ActivityTile(activity: activity);
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Performance Insights placeholder
                      Text(
                        'Performance Insights',
                        style: AppDesignSystem.h4,
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppDesignSystem.gradientPrimary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppDesignSystem.shadowMD,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.insights,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Coming Soon',
                              style: AppDesignSystem.h4.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Detailed analytics and insights',
                              style: AppDesignSystem.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Legacy action - keeping for compatibility
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateClassroomScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                                color: AppDesignSystem.primaryPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
                        ),
                              child: Icon(Icons.add_box, color: AppDesignSystem.primaryPink, size: 20),
                      ),
                      const SizedBox(width: 12),
                            const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
              children: [
                                  Text(
                                    'Create Classroom',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Set up a new class',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
              ],
            ),
          ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // View All Announcements
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UnifiedAnnouncementsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.campaign, color: Color(0xFF8B5CF6), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Announcements',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'View & create announcements',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // All Students
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllStudentsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people, color: Color(0xFF3B82F6), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
      child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
        children: [
                                  Text(
                                    'All Students',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'View all student summary',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
                      const SizedBox(height: 10),

                      // View Leaderboards
                      CleanCard(
                        onTap: () async {
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            
                            if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UnifiedLeaderboardScreen(),
                                  ),
                                );
        }
    } catch (e) {
                            // Error handling
                          }
                        },
                        child: Row(
          children: [
            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.leaderboard, color: Color(0xFFF59E0B), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
              children: [
                                  Text(
                                    'View Leaderboards',
                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'School, Class, State & Country',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Student Progress
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                              builder: (context) => const StudentProgressScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.trending_up, color: Color(0xFF06B6D4), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                                    'Student Progress',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Track student progress',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
                      const SizedBox(height: 10),

                      // Quiz Performance
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizPerformanceScreen(),
                            ),
                          );
                        },
                        child: Row(
                        children: [
                        Container(
                              padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.quiz, color: Color(0xFFEC4899), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                        Text(
                                    'Quiz Performance',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'View quiz results',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Generate Report
                      CleanCard(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (context) => const GenerateReportScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                              padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                    ),
                              child: const Icon(Icons.description, color: Color(0xFFEF4444), size: 20),
                                  ),
                            const SizedBox(width: 12),
                            const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                      children: [
                                            Text(
                                    'Generate Report',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                              Text(
                                    'Create PDF reports',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),

                      const SizedBox(height: 24),
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return CleanCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Container(
                  padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                  Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  ),
                ],
              ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(vertical: 14), // Reduced from 16
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      'My Classes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateClassroomScreen()),
                          );
                        },
                      ),
              ),
            ),
          ],
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

                  return ListView.builder(
      padding: const EdgeInsets.all(16),
                    itemCount: classrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = classrooms[index].data() as Map<String, dynamic>;
                      final classroomId = classrooms[index].id;
                      final studentCount = (classroom['studentIds'] as List?)?.length ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CleanCard(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                ),
              borderRadius: BorderRadius.circular(12),
            ),
                              child: const Icon(Icons.class_, color: Colors.white, size: 24),
                            ),
                            title: Text(
                              classroom['name'] ?? 'Unnamed Class',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                                Text('${classroom['grade']} ${classroom['section']}'),
                                const SizedBox(height: 4),
                                Text(
                                  '$studentCount students',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              try {
                                final classroomModel = ClassroomModel.fromMap({
                                  'id': classroomId,
                                  ...classroom,
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassroomDetailScreen(classroom: classroomModel),
                                  ),
                                );
                              } catch (e) {
                                // print('Error navigating to classroom: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error opening classroom: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
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
        
        totalStudentsCount += studentIds.length;
        
        for (String studentId in studentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (!studentDoc.exists) continue;
          
          final studentData = studentDoc.data()!;
          
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
    return CleanCard(
      child: Container(
                          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
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

      // Get stats
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        
        _totalClassrooms = classroomsSnapshot.docs.length;
        
      int totalStudentsCount = 0;
      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final studentIds = List<String>.from(classroomData['studentIds'] ?? []);
        totalStudentsCount += studentIds.length;
      }
      _totalStudents = totalStudentsCount;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                // Header skeleton
                LoadingSkeleton(
                  height: 120,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 24),
                // Stats skeleton
                Row(
                  children: List.generate(
                    2,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 6,
                          right: index == 1 ? 0 : 6,
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
                // List skeleton
                const ListSkeleton(itemCount: 3),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Compact Header with gradient
            SliverToBoxAdapter(
              child: Container(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18), // Reduced padding
          child: Column(
            children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 22, // Reduced from 24
                              fontWeight: FontWeight.bold,
                  color: Colors.white,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
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
                    const SizedBox(height: 14), // Reduced from 16
                    // Profile Card
                  Container(
                      padding: const EdgeInsets.all(14), // Reduced from 16
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                  ),
                ],
              ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            imageUrl: _user?.avatarUrl,
                            initials: (_user?.displayName != null && _user!.displayName.isNotEmpty)
                                ? _user!.displayName.substring(0, 1).toUpperCase()
                                : 'T',
                            size: 56, // Reduced from 60
                          ),
                          const SizedBox(width: 12),
                          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                Text(
                                  _user?.displayName ?? 'Teacher',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_schoolName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _schoolName!,
                        style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Teacher',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
                  ],
                ),
              ),
            ),

            // Stats Overview
            SliverPadding(
      padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Teaching Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CleanCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
      child: Column(
        children: [
                                const Icon(Icons.class_, color: Color(0xFFEF4444), size: 28),
                                const SizedBox(height: 8),
          Text(
                                  _totalClassrooms.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
              fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
                                  'Classes',
                                  style: TextStyle(
              fontSize: 13,
                                    color: Colors.grey[600],
            ),
          ),
        ],
      ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                Expanded(
                        child: CleanCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                                const Icon(Icons.people, color: Color(0xFF3B82F6), size: 28),
                                const SizedBox(height: 8),
                      Text(
                                  _totalStudents.toString(),
                        style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                                  'Students',
                                  style: TextStyle(
                          fontSize: 13,
                                    color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                        ),
                ),
              ],
            ),

                  const SizedBox(height: 24),

                  // School Information (if teacher is part of a school)
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
                            _buildInfoRow(Icons.location_on, 'Location', 
                                '${_schoolData!['city'] ?? 'N/A'}, ${_schoolData!['state'] ?? 'N/A'}'),
                            const Divider(height: 24),
                            _buildInfoRow(Icons.qr_code, 'School Code', _schoolData!['schoolCode'] ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Logout'),
          ),
        ],
      ),
    );

                      if (confirm == true && mounted) {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
                          ),
                        ),
                    ],
        ),
      ),
    );
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
