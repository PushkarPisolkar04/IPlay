import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../profile/profile_screen.dart';
import 'create_classroom_screen.dart';
import 'classroom_detail_screen.dart';
import 'student_progress_screen.dart';
import 'all_students_screen.dart';
import 'quiz_performance_screen.dart';
import 'generate_report_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;
  bool _isPrincipal = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPrincipalStatus();
  }

  Future<void> _checkPrincipalStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _isPrincipal = userDoc.data()?['isPrincipal'] ?? false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking principal status: $e');
      setState(() => _isLoading = false);
    }
  }

  // Don't use const - widgets need to access Firebase
  List<Widget> get _screens => _isPrincipal 
    ? [
        _DashboardOverview(),
        _ClassroomsTab(),
        const _SchoolManagementTab(), // Principal-only
        _ReportsTab(),
        _ProfileTab(),
      ]
    : [
        _DashboardOverview(),
        _ClassroomsTab(),
        _ReportsTab(),
        _ProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _isPrincipal
                ? [
                    _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                    _buildNavItem(1, Icons.class_, 'Classes'),
                    _buildNavItem(2, Icons.school, 'School'),
                    _buildNavItem(3, Icons.assessment, 'Reports'),
                    _buildNavItem(4, Icons.person, 'Profile'),
                  ]
                : [
                    _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                    _buildNavItem(1, Icons.class_, 'Classes'),
                    _buildNavItem(2, Icons.assessment, 'Reports'),
                    _buildNavItem(3, Icons.person, 'Profile'),
                  ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardOverview extends StatefulWidget {
  _DashboardOverview();

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview> {
  UserModel? _user;
  int _totalClassrooms = 0;
  int _totalStudents = 0;
  int _pendingApprovals = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data()!);
        }

        // Load classrooms stats
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        
        _totalClassrooms = classroomsSnapshot.docs.length;
        
        int studentCount = 0;
        int pendingCount = 0;
        
        for (var doc in classroomsSnapshot.docs) {
          final data = doc.data();
          studentCount += (data['studentIds'] as List?)?.length ?? 0;
          pendingCount += (data['pendingStudentIds'] as List?)?.length ?? 0;
        }
        
        if (mounted) {
          setState(() {
            _totalStudents = studentCount;
            _pendingApprovals = pendingCount;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Logo and Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/logos/logo.png', height: 60),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school, color: AppColors.primary, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats - 2 Cards
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Classrooms', '$_totalClassrooms', Icons.class_, AppColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Total Students', '$_totalStudents', Icons.people, AppColors.success)),
                      ],
                    ),
                    
                    if (_pendingApprovals > 0) ...[
                      const SizedBox(height: 12),
                      _buildPendingAlert(),
                    ],
              
                    const SizedBox(height: 24),
                    
                    // Quick Actions Grid
                    Text('Quick Actions', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                        Expanded(child: _buildActionButton('Create\nClassroom', Icons.add_circle, const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]), () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassroomScreen()));
                          if (result != null) _loadData();
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Post\nAnnouncement', Icons.campaign, const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]), () async {
                          if (_totalClassrooms == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a classroom first!')));
                            return;
                          }
                          await Navigator.pushNamed(context, '/create-announcement');
                          _loadData();
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('View\nStudents', Icons.people, const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)]), () {
                          if (_totalClassrooms == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a classroom first!')));
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Go to Classes tab to view students')));
                        })),
                      ],
                    ),
              
                    const SizedBox(height: 24),
                    
                    // Classrooms Quick View
                    if (_totalClassrooms > 0) ...[
                      Text('My Classrooms', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 12),
                      _buildClassroomsPreview(),
                      const SizedBox(height: 24),
                    ],
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPendingAlert() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning.withOpacity(0.1), AppColors.warning.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                          color: AppColors.warning,
              borderRadius: BorderRadius.circular(10),
                        ),
            child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_pendingApprovals Student${_pendingApprovals > 1 ? 's' : ''} Waiting', 
                  style: AppTextStyles.cardTitle.copyWith(color: AppColors.warning)),
                Text('Review join requests in Classes tab', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.warning),
        ],
      ),
    );
  }
  
  Widget _buildClassroomsPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                    color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_totalClassrooms Active Classroom${_totalClassrooms > 1 ? 's' : ''}', style: AppTextStyles.cardTitle),
                Text('$_totalStudents total students enrolled', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
                  const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Gradient gradient, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), 
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassroomsTab extends StatefulWidget {
  _ClassroomsTab();

  @override
  State<_ClassroomsTab> createState() => _ClassroomsTabState();
}

class _ClassroomsTabState extends State<_ClassroomsTab> {
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        
        if (mounted) {
          setState(() {
            _classrooms = snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  // Ensure id is included
                  data['id'] = doc.id;
                  return data;
                })
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading classrooms: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
          // Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                      'My Classrooms',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                      onPressed: () async {
                        final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateClassroomScreen(),
                        ),
                      );
                        if (result != null) _loadClassrooms();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.class_, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_classrooms.length} ${_classrooms.length == 1 ? 'Classroom' : 'Classrooms'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                  ),
                ],
              ),
            ),

            // Classrooms List
            Expanded(
            child: _classrooms.isEmpty
                ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.class_, size: 80, color: AppColors.primary.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 24),
                        Text('No classrooms yet', style: AppTextStyles.h2),
                          const SizedBox(height: 8),
                        Text(
                            'Create your first classroom to get started',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateClassroomScreen(),
                              ),
                            );
                            if (result != null) _loadClassrooms();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Classroom'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadClassrooms,
                    child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                      itemCount: _classrooms.length,
                    itemBuilder: (context, index) {
                        final classroomData = _classrooms[index];
                        final classroom = ClassroomModel.fromMap(classroomData);
                        final studentCount = (classroomData['studentIds'] as List?)?.length ?? 0;
                        final pendingCount = (classroomData['pendingStudentIds'] as List?)?.length ?? 0;
                        
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withOpacity(0.05), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                            ),
                            child: CleanCard(
                              color: Colors.transparent,
                              onTap: () async {
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                    builder: (context) => ClassroomDetailScreen(classroom: classroom),
                                  ),
                                );
                                _loadClassrooms();
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.class_, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(classroom.name, style: AppTextStyles.cardTitle),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.people, size: 16, color: AppColors.success),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                                            ),
                                            if (pendingCount > 0) ...[
                                              const SizedBox(width: 12),
                                              Icon(Icons.pending, size: 16, color: AppColors.warning),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$pendingCount pending',
                                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filter feature coming soon!')));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coming Soon Message
            Container(
      decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.analytics, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Advanced Analytics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detailed reports and analytics will be available here',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Detailed Reports
            Text('Detailed Reports', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 12),
            
            _buildReportCard(
              'Student Progress Tracking',
              'Track individual student learning journey',
              Icons.person_outlined,
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentProgressScreen()),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildReportCard(
              'View All Students',
              'Complete student list with grades & completion',
              Icons.people,
              AppColors.success,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllStudentsScreen()),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildReportCard(
              'Quiz & Module Performance',
              'Detailed quiz scores and module completion',
              Icons.quiz,
              AppColors.accent,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPerformanceScreen()),
                );
              },
            ),
            
                  const SizedBox(height: 12),
            
            _buildReportCard(
              'Generate Student Report',
              'Create PDF reports for individual students',
              Icons.description,
              AppColors.secondary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GenerateReportScreen()),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Export Options
            Text('Export Options', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
            
            CleanCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export to CSV coming soon!')));
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.file_download, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export to CSV', style: AppTextStyles.cardTitle),
                        Text('Download student data as spreadsheet', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            
                  const SizedBox(height: 12),
            
            CleanCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export to PDF coming soon!')));
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate PDF Report', style: AppTextStyles.cardTitle),
                        Text('Create printable performance reports', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
  
  static Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// School Management Tab - Principal Only
class _SchoolManagementTab extends StatefulWidget {
  const _SchoolManagementTab();

  @override
  State<_SchoolManagementTab> createState() => _SchoolManagementTabState();
}

class _SchoolManagementTabState extends State<_SchoolManagementTab> {
  String? _schoolId;
  Map<String, dynamic>? _schoolData;
  List<Map<String, dynamic>> _pendingTeachers = [];
  List<Map<String, dynamic>> _approvedTeachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get user's principal school
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        _schoolId = userDoc.data()?['principalOfSchool'];
        
        if (_schoolId != null) {
          // Load school data
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(_schoolId)
              .get();
          
          if (schoolDoc.exists) {
            _schoolData = schoolDoc.data();
            
            // Load pending teachers
            final pendingIds = List<String>.from(_schoolData?['pendingTeacherIds'] ?? []);
            _pendingTeachers = [];
            for (var teacherId in pendingIds) {
              final teacherDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(teacherId)
                  .get();
              if (teacherDoc.exists) {
                _pendingTeachers.add({
                  'id': teacherId,
                  ...teacherDoc.data()!,
                });
              }
            }
            
            // Load approved teachers
            final approvedIds = List<String>.from(_schoolData?['teacherIds'] ?? []);
            _approvedTeachers = [];
            for (var teacherId in approvedIds) {
              if (teacherId == currentUser.uid) continue; // Skip principal
              final teacherDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(teacherId)
                  .get();
              if (teacherDoc.exists) {
                _approvedTeachers.add({
                  'id': teacherId,
                  ...teacherDoc.data()!,
                });
              }
            }
          }
        }
        
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading school data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveTeacher(String teacherId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .update({
        'pendingTeacherIds': FieldValue.arrayRemove([teacherId]),
        'teacherIds': FieldValue.arrayUnion([teacherId]),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadSchoolData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectTeacher(String teacherId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .update({
        'pendingTeacherIds': FieldValue.arrayRemove([teacherId]),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      
      _loadSchoolData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSchoolData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school, color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'School Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _schoolData?['name'] ?? 'School Name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Code: ${_schoolData?['schoolCode'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pending Teacher Approvals
              if (_pendingTeachers.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions, color: AppColors.warning, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Pending Teacher Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final teacher = _pendingTeachers[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: AppColors.warning, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teacher['displayName'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          teacher['email'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approveTeacher(teacher['id']),
                                      icon: const Icon(Icons.check, size: 20),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _rejectTeacher(teacher['id']),
                                      icon: const Icon(Icons.close, size: 20),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error, width: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _pendingTeachers.length,
                  ),
                ),
              ],

              // Approved Teachers
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'School Teachers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final teacher = _approvedTeachers[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        title: Text(
                          teacher['displayName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(teacher['email'] ?? ''),
                      ),
                    );
                  },
                  childCount: _approvedTeachers.length,
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  UserModel? _user;
  int _totalClassrooms = 0;
  int _totalStudents = 0;
  int _totalAnnouncements = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          _user = UserModel.fromMap(userDoc.data()!);
        }

        // Load teaching stats
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        
        _totalClassrooms = classroomsSnapshot.docs.length;
        
        int studentCount = 0;
        for (var doc in classroomsSnapshot.docs) {
          final data = doc.data();
          studentCount += (data['studentIds'] as List?)?.length ?? 0;
        }
        _totalStudents = studentCount;

        // Load announcements count
        final announcementsSnapshot = await FirebaseFirestore.instance
            .collection('announcements')
            .where('teacherId', isEqualTo: currentUser.uid)
            .get();
        _totalAnnouncements = announcementsSnapshot.docs.length;
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
      decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
      ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
          child: Column(
            children: [
              // Avatar
              Container(
                    width: 100,
                    height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                    child: const Icon(Icons.school, size: 50, color: AppColors.primary),
                ),
                  const SizedBox(height: 16),
              Text(
                    _user?.displayName ?? 'Teacher',
                style: const TextStyle(
                      fontSize: 24,
                  fontWeight: FontWeight.bold,
                      color: Colors.white,
                ),
              ),
                  const SizedBox(height: 4),
              Text(
                    _user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user?.isPrincipal == true ? '👑 Principal' : '👨‍🏫 Teacher',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Teaching Stats
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teaching Statistics', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Classrooms', '$_totalClassrooms', Icons.class_, AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Students', '$_totalStudents', Icons.people, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Announcements', '$_totalAnnouncements', Icons.campaign, AppColors.secondary)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('State', _user?.state ?? 'N/A', Icons.location_on, AppColors.accent)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Settings Options
                  Text('Settings', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 12),
              
                  _buildSettingItem(
                    'Account Settings',
                    Icons.person_outlined,
                    () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    'Notifications',
                    Icons.notifications_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    'Help & Support',
                    Icons.help_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help center coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    'About IPlay',
                    Icons.info_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('IPlay - IPR Learning Platform v1.0')),
                      );
                    },
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
                  children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: AppTextStyles.cardTitle),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/auth');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// Helper Widgets
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;

  const _ActivityCard({
    required this.title,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final dynamic classroom;
  final VoidCallback onTap;

  const _ClassroomCard({
    required this.classroom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${classroom.studentIds.length} students • ${classroom.classCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (classroom.pendingStudentIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${classroom.pendingStudentIds.length} pending approvals',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

