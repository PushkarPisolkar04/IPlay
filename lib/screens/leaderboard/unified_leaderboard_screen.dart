import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/loading_skeleton.dart';

/// Unified Leaderboard Screen - Handles ALL roles (Student, Teacher, Principal)
/// Dynamically shows appropriate tabs and data based on user role and permissions
class UnifiedLeaderboardScreen extends StatefulWidget {
  const UnifiedLeaderboardScreen({super.key});

  @override
  State<UnifiedLeaderboardScreen> createState() =>
      _UnifiedLeaderboardScreenState();
}

class _UnifiedLeaderboardScreenState extends State<UnifiedLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // User info
  String? _currentUserId;
  String? _userRole;
  bool _isPrincipal = false;
  String? _userClassroomId;
  String? _userSchoolId;
  String? _userState;
  List<String> _teacherClassroomIds = [];

  // Data
  List<Map<String, dynamic>> _students = [];
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserInfoAndData();
  }

  @override
  void dispose() {
    if (_tabs.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserInfoAndData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _userRole = userData['role'];
        _isPrincipal = userData['isPrincipal'] ?? false;
        _userState = userData['state'];
        _userSchoolId = userData['schoolId'];

        // Get user's classroom(s)
        final classroomIds = userData['classroomIds'] as List?;
        if (classroomIds != null && classroomIds.isNotEmpty) {
          _userClassroomId = classroomIds.first;

          // If student doesn't have schoolId, get it from their classroom
          if (_userSchoolId == null && _userRole == 'student') {
            final classroomDoc = await FirebaseFirestore.instance
                .collection('classrooms')
                .doc(_userClassroomId)
                .get();

            if (classroomDoc.exists) {
              _userSchoolId = classroomDoc.data()?['schoolId'];
            }
          }
        }

        // For teachers, get all their classrooms
        if (_userRole == 'teacher') {
          final classroomsSnapshot = await FirebaseFirestore.instance
              .collection('classrooms')
              .where('teacherId', isEqualTo: _currentUserId)
              .get();
          _teacherClassroomIds = classroomsSnapshot.docs
              .map((doc) => doc.id)
              .toList();
        }

        // Determine tabs based on role
        _determineTabs();

        // Initialize tab controller
        _tabController = TabController(length: _tabs.length, vsync: this);
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            _loadLeaderboardData();
          }
        });

        // Load initial data
        await _loadLeaderboardData();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading leaderboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _determineTabs() {
    _tabs = [];

    if (_userRole == 'student') {
      // STUDENT: Show classroom, school, state, national
      if (_userClassroomId != null) _tabs.add('Classroom');
      if (_userSchoolId != null) _tabs.add('School');
      if (_userState != null) _tabs.add('State');
      _tabs.add('National');
    } else if (_userRole == 'teacher') {
      // TEACHER: Show their classrooms and school
      if (_teacherClassroomIds.isNotEmpty) {
        if (_teacherClassroomIds.length == 1) {
          _tabs.add('My Classroom');
        } else {
          _tabs.add('All My Students');
        }
      }
      if (_userSchoolId != null) _tabs.add('School');
    } else if (_isPrincipal) {
      // PRINCIPAL: Show school-wide and state/national
      _tabs.add('School');
      if (_userState != null) _tabs.add('State');
      _tabs.add('National');
    }
  }

  Future<void> _loadLeaderboardData() async {
    if (_tabs.isEmpty || !mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final currentTab = _tabs[_tabController.index];

      // Route to appropriate loader based on tab and role
      if (currentTab == 'Classroom' || currentTab == 'My Classroom') {
        await _loadClassroomLeaderboard();
      } else if (currentTab == 'All My Students') {
        await _loadTeacherAllStudents();
      } else if (currentTab == 'School') {
        await _loadSchoolLeaderboard();
      } else if (currentTab == 'State') {
        await _loadStateLeaderboard();
      } else if (currentTab == 'National') {
        await _loadNationalLeaderboard();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading leaderboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadClassroomLeaderboard() async {
    final classroomId = _teacherClassroomIds.isNotEmpty
        ? _teacherClassroomIds.first
        : _userClassroomId;

    if (classroomId == null) return;

    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('classroomIds', arrayContains: classroomId)
        .where('role', isEqualTo: 'student')
        .get();

    // Filter out deleted users and sort by totalXP in descending order
    final studentsList = studentsSnapshot.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    studentsList.sort(
      (a, b) =>
          ((b['totalXP'] ?? 0) as num).compareTo((a['totalXP'] ?? 0) as num),
    );

    _students = studentsList.take(100).toList();
  }

  Future<void> _loadTeacherAllStudents() async {
    if (_teacherClassroomIds.isEmpty) return;

    // Get all students from teacher's classrooms
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    // Filter students who are in teacher's classrooms, not deleted, and sort by XP
    final studentsList = studentsSnapshot.docs
        .where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] == true;
          if (isDeleted) return false;

          final studentClassrooms = data['classroomIds'] as List?;
          return studentClassrooms?.any(
                (id) => _teacherClassroomIds.contains(id),
              ) ??
              false;
        })
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    studentsList.sort(
      (a, b) =>
          ((b['totalXP'] ?? 0) as num).compareTo((a['totalXP'] ?? 0) as num),
    );

    _students = studentsList.take(200).toList();
  }

  Future<void> _loadSchoolLeaderboard() async {
    if (_userSchoolId == null) return;

    // First, get all classrooms in this school
    final classroomsSnapshot = await FirebaseFirestore.instance
        .collection('classrooms')
        .where('schoolId', isEqualTo: _userSchoolId)
        .get();

    final schoolClassroomIds = classroomsSnapshot.docs
        .map((doc) => doc.id)
        .toList();

    if (schoolClassroomIds.isEmpty) {
      _students = [];
      return;
    }

    // Get all students
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    // Filter students who are in school classrooms or have schoolId, not deleted, and sort by XP
    final studentsList = studentsSnapshot.docs
        .where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] == true;
          if (isDeleted) return false;

          // Check if student has schoolId directly
          if (data['schoolId'] == _userSchoolId) return true;

          // Check if student is in any classroom of this school
          final studentClassrooms = data['classroomIds'] as List?;
          return studentClassrooms?.any(
                (id) => schoolClassroomIds.contains(id),
              ) ??
              false;
        })
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    studentsList.sort(
      (a, b) =>
          ((b['totalXP'] ?? 0) as num).compareTo((a['totalXP'] ?? 0) as num),
    );

    _students = studentsList.take(100).toList();
  }

  Future<void> _loadStateLeaderboard() async {
    if (_userState == null) return;

    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('state', isEqualTo: _userState)
        .where('role', isEqualTo: 'student')
        .get();

    // Filter out deleted users and sort by totalXP in descending order
    final studentsList = studentsSnapshot.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    studentsList.sort(
      (a, b) =>
          ((b['totalXP'] ?? 0) as num).compareTo((a['totalXP'] ?? 0) as num),
    );

    _students = studentsList.take(100).toList();
  }

  Future<void> _loadNationalLeaderboard() async {
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    // Filter out deleted users and sort by totalXP in descending order
    final studentsList = studentsSnapshot.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    studentsList.sort(
      (a, b) =>
          ((b['totalXP'] ?? 0) as num).compareTo((a['totalXP'] ?? 0) as num),
    );

    _students = studentsList.take(100).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient App Bar
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Show back button only if this screen was pushed (not in bottom nav)
                        if (ModalRoute.of(context)?.canPop ?? false)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Leaderboard',
                              style: AppDesignSystem.h2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  if (_tabs.length > 1)
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      isScrollable: _tabs.length > 4,
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                    ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const ListSkeleton(itemCount: 5)
                  : _tabs.length > 1
                  ? TabBarView(
                      controller: _tabController,
                      children: _tabs
                          .map((_) => _buildLeaderboardList())
                          .toList(),
                    )
                  : _buildLeaderboardList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    if (_students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLeaderboardData,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: AppDesignSystem.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No students found',
                      style: AppDesignSystem.h3.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final rank = index + 1;
          final isCurrentUser = student['id'] == _currentUserId;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: isCurrentUser
                  ? AppDesignSystem.gradientSuccess
                  : LinearGradient(
                      colors: [Colors.white, AppDesignSystem.backgroundLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentUser
                    ? Colors.transparent
                    : AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrentUser
                      ? AppDesignSystem.primaryGreen.withValues(alpha: 0.3)
                      : AppDesignSystem.primaryIndigo.withValues(alpha: 0.08),
                  blurRadius: isCurrentUser ? 12 : 8,
                  offset: Offset(0, isCurrentUser ? 4 : 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Rank with medal for top 3
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: rank <= 3
                          ? Text(
                              _getRankMedal(rank),
                              style: const TextStyle(fontSize: 28),
                            )
                          : Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : AppDesignSystem.backgroundGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentUser
                                        ? Colors.white
                                        : AppDesignSystem.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AvatarWidget(
                      imageUrl: student['avatarUrl'],
                      initials: _getInitials(student['displayName']),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['displayName'] ?? 'Student',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser
                                ? Colors.white
                                : AppDesignSystem.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (student['schoolName'] != null)
                          Text(
                            student['schoolName'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentUser
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppDesignSystem.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // You badge
                  if (isCurrentUser) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // XP
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppDesignSystem.primaryAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⭐',
                          style: TextStyle(
                            fontSize: 16,
                            color: isCurrentUser ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatXP(student['totalXP'] ?? 0),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser
                                ? Colors.white
                                : AppDesignSystem.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000000) {
      final value = xp / 1000000;
      return value >= 10
          ? '${value.toStringAsFixed(0)}M'
          : '${value.toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      final value = xp / 1000;
      return value >= 10
          ? '${value.toStringAsFixed(0)}K'
          : '${value.toStringAsFixed(1)}K';
    }
    return xp.toString();
  }

  String _getRankMedal(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '';
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppDesignSystem.textSecondary;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
