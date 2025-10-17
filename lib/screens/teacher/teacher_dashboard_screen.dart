import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../settings/settings_screen.dart';
import 'teacher_comprehensive_leaderboard_screen.dart';
import 'create_classroom_screen.dart';
import 'classroom_detail_screen.dart';
import 'all_students_screen.dart';
import 'student_progress_screen.dart';
import 'quiz_performance_screen.dart';
import 'generate_report_screen.dart';
import 'teacher_all_announcements_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _TeacherOverviewTab(onNavigate: (index) => setState(() => _selectedIndex = index)),
    const _TeacherClassroomsTab(),
    const _TeacherAnalyticsTab(),
    const _TeacherProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
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
      onTap: () => setState(() => _selectedIndex = index),
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

      setState(() => _isLoading = false);
    } catch (e) {
        setState(() => _isLoading = false);
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
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
                // Compact Header - Red Theme
              Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?.displayName ?? 'Teacher',
                      style: const TextStyle(
                                  fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Teacher',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
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
                      style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                      
                      const Text(
                        'Teaching Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: [
                          _buildStatCard(
                            icon: Icons.class_,
                            title: 'My Classes',
                            value: _totalClassrooms.toString(),
                            color: const Color(0xFFEF4444),
                            subtitle: 'Active classrooms',
                          ),
                          _buildStatCard(
                            icon: Icons.people,
                            title: 'Students',
                            value: _totalStudents.toString(),
                            color: const Color(0xFF3B82F6),
                            subtitle: '$_activeStudents active',
                          ),
                          _buildStatCard(
                            icon: Icons.trending_up,
                            title: 'Active Rate',
                            value: _totalStudents > 0 
                                ? '${((_activeStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                                : '0%',
                            color: const Color(0xFFF59E0B),
                            subtitle: 'Last 7 days',
                          ),
                          _buildStatCard(
                            icon: Icons.stars,
                            title: 'Avg XP',
                            value: _avgClassXP.toStringAsFixed(0),
                            color: const Color(0xFF8B5CF6),
                            subtitle: 'Per student',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions - Compact Cards Like Principal
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Create Classroom
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
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
                        ),
                              child: const Icon(Icons.add_box, color: Color(0xFFEF4444), size: 20),
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
                              builder: (context) => const TeacherAllAnnouncementsScreen(),
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
                            
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            
                            if (userDoc.exists && mounted) {
                              final userData = userDoc.data()!;
                              final schoolId = userData['schoolId'];
                              
                              final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
                                  .where('teacherId', isEqualTo: user.uid)
            .get();
        
                              final classroomIds = classroomsSnapshot.docs.map((doc) => doc.id).toList();
                              
                              if (schoolId != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeacherComprehensiveLeaderboardScreen(
                                      schoolId: schoolId,
                                      classroomIds: classroomIds,
                                    ),
                                  ),
                                );
        }
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
                                print('Error navigating to classroom: $e');
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

          setState(() => _isLoading = false);
    } catch (e) {
        setState(() => _isLoading = false);
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
      print('Error loading top performers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
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
                      }).toList(),
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

      setState(() => _isLoading = false);
    } catch (e) {
        setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)));
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

