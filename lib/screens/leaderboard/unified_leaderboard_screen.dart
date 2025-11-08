import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/loading_skeleton.dart';

/// Unified Leaderboard Screen - Handles ALL roles (Student, Teacher, Principal)
/// Dynamically shows appropriate tabs and data based on user role and permissions
class UnifiedLeaderboardScreen extends StatefulWidget {
  const UnifiedLeaderboardScreen({super.key});

  @override
  State<UnifiedLeaderboardScreen> createState() => _UnifiedLeaderboardScreenState();
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
    _tabController.dispose();
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
        }
        
        // For teachers, get all their classrooms
        if (_userRole == 'teacher') {
          final classroomsSnapshot = await FirebaseFirestore.instance
              .collection('classrooms')
              .where('teacherId', isEqualTo: _currentUserId)
              .get();
          _teacherClassroomIds = classroomsSnapshot.docs.map((doc) => doc.id).toList();
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
      
      setState(() => _isLoading = false);
    } catch (e) {
      // print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
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
    if (_tabs.isEmpty) return;
    
    setState(() => _isLoading = true);
    
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
      
      setState(() => _isLoading = false);
    } catch (e) {
      // print('Error loading leaderboard data: $e');
      setState(() => _isLoading = false);
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
        .orderBy('totalXP', descending: true)
        .limit(100)
        .get();
    
    _students = studentsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> _loadTeacherAllStudents() async {
    if (_teacherClassroomIds.isEmpty) return;
    
    // Get all students from teacher's classrooms
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('totalXP', descending: true)
        .limit(200)
        .get();
    
    // Filter students who are in teacher's classrooms
    _students = studentsSnapshot.docs
        .where((doc) {
          final studentClassrooms = doc.data()['classroomIds'] as List?;
          return studentClassrooms?.any((id) => _teacherClassroomIds.contains(id)) ?? false;
        })
        .map((doc) => {
          'id': doc.id,
          ...doc.data(),
        })
        .toList();
  }

  Future<void> _loadSchoolLeaderboard() async {
    if (_userSchoolId == null) return;
    
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('schoolId', isEqualTo: _userSchoolId)
        .where('role', isEqualTo: 'student')
        .orderBy('totalXP', descending: true)
        .limit(100)
        .get();
    
    _students = studentsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> _loadStateLeaderboard() async {
    if (_userState == null) return;
    
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('state', isEqualTo: _userState)
        .where('role', isEqualTo: 'student')
        .orderBy('totalXP', descending: true)
        .limit(100)
        .get();
    
    _students = studentsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> _loadNationalLeaderboard() async {
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('totalXP', descending: true)
        .limit(100)
        .get();
    
    _students = studentsSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppDesignSystem.backgroundWhite,
        elevation: 0,
        bottom: _tabs.length > 1
            ? TabBar(
                controller: _tabController,
                labelColor: AppDesignSystem.primaryIndigo,
                unselectedLabelColor: AppDesignSystem.textSecondary,
                indicatorColor: AppDesignSystem.primaryIndigo,
                isScrollable: _tabs.length > 4,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              )
            : null,
      ),
      body: _isLoading
          ? const ListSkeleton(itemCount: 5)
          : _tabs.length > 1
              ? TabBarView(
                  controller: _tabController,
                  children: _tabs.map((_) => _buildLeaderboardList()).toList(),
                )
              : _buildLeaderboardList(),
    );
  }

  Widget _buildLeaderboardList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: AppDesignSystem.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No students yet',
              style: AppDesignSystem.h3.copyWith(color: AppDesignSystem.textSecondary),
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
            margin: const EdgeInsets.only(bottom: 12),
            child: CleanCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: AppDesignSystem.h4.copyWith(
                            color: _getRankColor(rank),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Avatar
                    AvatarWidget(
                      imageUrl: student['avatarUrl'],
                      initials: _getInitials(student['displayName']),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    
                    // Name and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['displayName'] ?? 'Student',
                            style: AppDesignSystem.bodyLarge.copyWith(
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                              color: isCurrentUser ? AppDesignSystem.primaryIndigo : AppDesignSystem.textPrimary,
                            ),
                          ),
                          if (student['schoolName'] != null)
                            Text(
                              student['schoolName'],
                              style: AppDesignSystem.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    
                    // XP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${student['totalXP'] ?? 0}',
                            style: AppDesignSystem.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppDesignSystem.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
