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
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
// TEACHER OVERVIEW TAB
// =================================================================

class _TeacherOverviewTab extends StatefulWidget {
  final Function(int) onNavigate;
  
  const _TeacherOverviewTab({required this.onNavigate});

  @override
  State<_TeacherOverviewTab> createState() => _TeacherOverviewTabState();
}

class _TeacherOverviewTabState extends State<_TeacherOverviewTab> {
  UserModel? _user;
  String? _schoolId; // From Firestore user document
  String? _schoolName;
  
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

      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        _user = UserModel.fromMap(userDoc.data()!);
        // Get schoolId from Firestore document (not in UserModel)
        _schoolId = userDoc.data()!['schoolId'] as String?;
        
        // Get school name
        if (_schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .get();
          _schoolName = schoolDoc.data()?['name'];
        }
      }

      // Load teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();
      
      _totalClassrooms = classroomsSnapshot.docs.length;

      // Load students from teacher's classrooms
      int totalStudentsCount = 0;
      int activeCount = 0;
      double totalXP = 0;
      
      for (var classroomDoc in classroomsSnapshot.docs) {
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classroomId', isEqualTo: classroomDoc.id)
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
      print('Error loading teacher overview: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Teacher Badge
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?.displayName ?? 'Teacher',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.school, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_schoolName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _schoolName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Classrooms',
                            _totalClassrooms.toString(),
                            Icons.class_,
                            const Color(0xFF10B981),
                            const Color(0xFF14B8A6),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard(
                            'Students',
                            _totalStudents.toString(),
                            Icons.people,
                            const Color(0xFF3B82F6),
                            const Color(0xFF06B6D4),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Active (7d)',
                            _activeStudents.toString(),
                            Icons.trending_up,
                            const Color(0xFFF59E0B),
                            const Color(0xFFF97316),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard(
                            'Avg XP',
                            _avgClassXP.toStringAsFixed(0),
                            Icons.stars,
                            const Color(0xFFEC4899),
                            const Color(0xFF8B5CF6),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildQuickAction(
                            'View Leaderboards',
                            Icons.leaderboard,
                            const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                            () async {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get();
                                
                                if (userDoc.exists) {
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
                                print('Error navigating to leaderboards: $e');
                              }
                            },
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildQuickAction(
                            'Announcements',
                            Icons.campaign,
                            const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]),
                            () {
                              if (_totalClassrooms == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Create a classroom first!')),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Select a classroom to view announcements')),
                              );
                            },
                          )),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // My Classrooms Preview
                if (_totalClassrooms > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Classrooms',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate(1),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildClassroomsPreview(),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color1, Color color2) {
    return CleanCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1.withValues(alpha: 0.1), color2.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color1, color2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CleanCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient.colors.length == 2 
                ? LinearGradient(
                    colors: [
                      gradient.colors[0].withValues(alpha: 0.1),
                      gradient.colors[1].withValues(alpha: 0.05)
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildClassroomsPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classrooms = snapshot.data!.docs;

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final classroom = classrooms[index].data() as Map<String, dynamic>;
              final classroomId = classrooms[index].id;
              
              return GestureDetector(
                onTap: () {
                  // Convert to ClassroomModel
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
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: CleanCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.class_, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            classroom['name'] ?? 'Unnamed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${classroom['grade']} ${classroom['section']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(classroom['studentIds'] as List?)?.length ?? 0} students',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =================================================================
// TEACHER CLASSROOMS TAB (will continue in next part)
// =================================================================

class _TeacherClassroomsTab extends StatefulWidget {
  const _TeacherClassroomsTab();

  @override
  State<_TeacherClassroomsTab> createState() => _TeacherClassroomsTabState();
}

class _TeacherClassroomsTabState extends State<_TeacherClassroomsTab> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Gradient Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    return const Center(child: CircularProgressIndicator());
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
                              backgroundColor: const Color(0xFF10B981),
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
                                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
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
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Convert to ClassroomModel
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
// TEACHER ANALYTICS TAB (Placeholder - similar to principal)
// =================================================================

class _TeacherAnalyticsTab extends StatelessWidget {
  const _TeacherAnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Gradient Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Analytics Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track student progress and performance',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// TEACHER PROFILE TAB (Similar to principal)
// =================================================================

class _TeacherProfileTab extends StatefulWidget {
  const _TeacherProfileTab();

  @override
  State<_TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<_TeacherProfileTab> {
  UserModel? _user;
  String? _schoolName;
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
        
        // Get schoolId from Firestore document (not in UserModel)
        final schoolId = userDoc.data()!['schoolId'] as String?;
        
        // Get school name
        if (schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
          _schoolName = schoolDoc.data()?['name'];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with gradient
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Center(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
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
                    const SizedBox(height: 16),
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
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
                            size: 60,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.displayName ?? 'Teacher',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_schoolName != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _schoolName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Teacher',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
            
            // Quick Links - same as principal but teacher-specific
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildQuickLinkCard(
                        'View\nAnnouncements',
                        Icons.campaign,
                        const Color(0xFFEC4899),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select a classroom to view announcements')),
                          );
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildQuickLinkCard(
                        'View\nLeaderboard',
                        Icons.leaderboard,
                        const Color(0xFFF59E0B),
                        () async {
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();
                            
                            if (userDoc.exists) {
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
                            print('Error: $e');
                          }
                        },
                      )),
                    ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
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
}

