import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/qr_code_widget.dart';
import '../../widgets/notification_bell_icon.dart';
import '../settings/settings_screen.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import 'school_settings_screen.dart';
import '../announcements/unified_announcements_screen.dart';
import 'principal_generate_report_screen.dart';
import 'all_students_screen.dart';

class PrincipalDashboardScreen extends StatefulWidget {
  const PrincipalDashboardScreen({super.key});
  @override
  State<PrincipalDashboardScreen> createState() =>
      _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
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
    _PrincipalOverviewTab(
      onNavigate: (index) {
        setState(() => _selectedIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    ),
    const _SchoolClassroomsTab(),
    const _SchoolAnalyticsTab(),
    const _SchoolTeachersTab(),
    const _PrincipalProfileTab(),
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
                _buildNavItem(3, Icons.people_rounded, 'Teachers'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
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
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// PRINCIPAL OVERVIEW TAB - School-wide statistics
// =================================================================
class _PrincipalOverviewTab extends StatefulWidget {
  final Function(int) onNavigate;

  const _PrincipalOverviewTab({required this.onNavigate});

  @override
  State<_PrincipalOverviewTab> createState() => _PrincipalOverviewTabState();
}

class _PrincipalOverviewTabState extends State<_PrincipalOverviewTab> {
  UserModel? _user;
  Map<String, dynamic>? _schoolData;
  String? _schoolId;

  int _totalTeachers = 0;
  int _totalClassrooms = 0;
  int _totalStudents = 0;
  int _pendingTeachers = 0;
  int _activeStudents = 0;
  double _avgSchoolXP = 0;

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
        _schoolId = _user?.principalOfSchool;
      }

      if (_schoolId != null) {
        final schoolDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(_schoolId)
            .get();

        if (schoolDoc.exists) {
          _schoolData = schoolDoc.data();

          final teacherIdsCount =
              ((_schoolData?['teacherIds'] as List?)?.length ?? 0);
          _totalTeachers = teacherIdsCount > 0 ? teacherIdsCount - 1 : 0;

          final pendingRequestsSnapshot = await FirebaseFirestore.instance
              .collection('teacher_join_requests')
              .where('schoolId', isEqualTo: _schoolId)
              .where('status', isEqualTo: 'pending')
              .get();
          _pendingTeachers = pendingRequestsSnapshot.docs.length;

          final classroomsSnapshot = await FirebaseFirestore.instance
              .collection('classrooms')
              .where('schoolId', isEqualTo: _schoolId)
              .get();

          _totalClassrooms = classroomsSnapshot.docs.length;

          Set<String> uniqueStudents = {};
          int totalXP = 0;

          for (var classroomDoc in classroomsSnapshot.docs) {
            final data = classroomDoc.data();
            final studentIds = List<String>.from(data['studentIds'] ?? []);
            uniqueStudents.addAll(studentIds);
          }

          // Filter out deleted students and count only existing ones
          Set<String> existingStudents = {};
          if (uniqueStudents.isNotEmpty) {
            for (var studentId in uniqueStudents) {
              final studentDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentId)
                  .get();
              if (studentDoc.exists) {
                existingStudents.add(studentId);
                totalXP += (studentDoc.data()?['totalXP'] ?? 0) as int;
                final lastActive =
                    studentDoc.data()?['lastActiveDate'] as Timestamp?;
                if (lastActive != null) {
                  final daysSince = DateTime.now()
                      .difference(lastActive.toDate())
                      .inDays;
                  if (daysSince <= 7) {
                    _activeStudents++;
                  }
                }
              }
            }
          }

          _totalStudents = existingStudents.length;
          if (existingStudents.isNotEmpty) {
            _avgSchoolXP = totalXP / existingStudents.length;
          }
        }
      }

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
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingSkeleton(
                height: 100,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LoadingSkeleton(
                      height: 80,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: LoadingSkeleton(
                      height: 80,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ListSkeleton(itemCount: 3),
            ],
          ),
        ),
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
                // Header with Principal Badge
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                          Expanded(
                            child: Column(
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
                                  _user?.displayName ?? 'Principal',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const NotificationBellIcon(color: Colors.white),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Principal',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _schoolData?['name'] ?? 'School Name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Code: ${_schoolData?['schoolCode'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_schoolData?['state'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // School Statistics Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          _buildStatCard(
                            icon: Icons.people,
                            title: 'Total Students',
                            value: _totalStudents.toString(),
                            color: const Color(0xFF3B82F6),
                            subtitle: '$_activeStudents active this week',
                          ),
                          _buildStatCard(
                            icon: Icons.person_outline,
                            title: 'Teachers',
                            value: _totalTeachers.toString(),
                            color: const Color(0xFF10B981),
                            subtitle: _pendingTeachers > 0
                                ? '$_pendingTeachers pending'
                                : 'All approved',
                          ),
                          _buildStatCard(
                            icon: Icons.class_,
                            title: 'Classrooms',
                            value: _totalClassrooms.toString(),
                            color: const Color(0xFF8B5CF6),
                            subtitle: 'Across all teachers',
                          ),
                          _buildStatCard(
                            icon: Icons.stars,
                            title: 'Avg XP',
                            value: _avgSchoolXP.toStringAsFixed(0),
                            color: const Color(0xFFF59E0B),
                            subtitle: 'Per student',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_pendingTeachers > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => widget.onNavigate(3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_add_alt,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pending Teacher Requests',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '$_pendingTeachers waiting for approval',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Announcements',
                              icon: Icons.campaign,
                              color: const Color(0xFF8B5CF6),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UnifiedAnnouncementsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Reports',
                              icon: Icons.description,
                              color: const Color(0xFFEF4444),
                              onPressed: () {
                                if (_schoolId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PrincipalGenerateReportScreen(
                                            schoolId: _schoolId!,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('School ID not found'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Leaderboard',
                              icon: Icons.leaderboard,
                              color: const Color(0xFFF59E0B),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UnifiedLeaderboardScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'Teachers',
                              icon: Icons.people,
                              color: const Color(0xFF10B981),
                              onPressed: () => widget.onNavigate(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'All Students',
                              icon: Icons.groups,
                              color: const Color(0xFF3B82F6),
                              onPressed: () {
                                if (_schoolId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllStudentsScreen(
                                        schoolId: _schoolId!,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('School ID not found'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildColoredActionButton(
                              context: context,
                              text: 'School Settings',
                              icon: Icons.settings,
                              color: const Color(0xFF6366F1),
                              onPressed: () {
                                if (_schoolId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SchoolSettingsScreen(
                                            schoolId: _schoolId!,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('School ID not found'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
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
    String? subtitle,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;

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
}

// =================================================================
// REST OF THE TABS (UNCHANGED)
// =================================================================

// _SchoolTeachersTab, _SchoolClassroomsTab, _SchoolAnalyticsTab, _PrincipalProfileTab
// (All remain the same as in your original code — no changes needed)

class _SchoolTeachersTab extends StatefulWidget {
  const _SchoolTeachersTab();
  @override
  State<_SchoolTeachersTab> createState() => _SchoolTeachersTabState();
}

class _SchoolTeachersTabState extends State<_SchoolTeachersTab> {
  String? _schoolId;
  List<Map<String, dynamic>> _pendingTeachers = [];
  List<Map<String, dynamic>> _approvedTeachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      _schoolId = userDoc.data()?['principalOfSchool'];

      if (_schoolId != null) {
        final schoolDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(_schoolId)
            .get();

        if (schoolDoc.exists) {
          final schoolData = schoolDoc.data();

          final pendingRequestsSnapshot = await FirebaseFirestore.instance
              .collection('teacher_join_requests')
              .where('schoolId', isEqualTo: _schoolId)
              .where('status', isEqualTo: 'pending')
              .get();

          _pendingTeachers = [];
          for (var requestDoc in pendingRequestsSnapshot.docs) {
            final requestData = requestDoc.data();
            _pendingTeachers.add({
              'id': requestData['teacherId'],
              'requestId': requestDoc.id,
              'displayName': requestData['teacherName'],
              'email': requestData['teacherEmail'],
              'createdAt': requestData['createdAt'],
            });
          }

          final approvedIds = List<String>.from(
            schoolData?['teacherIds'] ?? [],
          );
          _approvedTeachers = [];
          for (var teacherId in approvedIds) {
            if (teacherId == currentUser.uid) continue;
            final teacherDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(teacherId)
                .get();
            if (teacherDoc.exists) {
              _approvedTeachers.add({'id': teacherId, ...teacherDoc.data()!});
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveTeacher(String teacherId, String requestId) async {
    try {
      // Get school data to retrieve schoolTag
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .get();

      final schoolTag = schoolDoc.data()?['schoolTag'];
      final schoolName = schoolDoc.data()?['name'];

      // Update the join request status
      await FirebaseFirestore.instance
          .collection('teacher_join_requests')
          .doc(requestId)
          .update({'status': 'approved', 'approvedAt': Timestamp.now()});

      // Add teacher to school's teacherIds
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .update({
            'teacherIds': FieldValue.arrayUnion([teacherId]),
            'updatedAt': Timestamp.now(),
          });

      // CRITICAL FIX: Update teacher's user profile with schoolId and schoolTag
      final updateData = {
        'schoolId': _schoolId,
        'pendingSchoolId': FieldValue.delete(), // Remove pending status
        'updatedAt': Timestamp.now()
      };

      if (schoolTag != null) {
        updateData['schoolTag'] = schoolTag;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teacher approved and added to ${schoolName ?? 'school'}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadTeachers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectTeacher(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('teacher_join_requests')
          .doc(requestId)
          .update({'status': 'rejected', 'rejectedAt': Timestamp.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadTeachers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeTeacher(String teacherId, String teacherName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Teacher'),
        content: Text(
          'Are you sure you want to remove $teacherName from the school?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(_schoolId)
            .update({
              'teacherIds': FieldValue.arrayRemove([teacherId]),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher removed from school'),
            backgroundColor: Colors.orange,
          ),
        );

        _loadTeachers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, int>> _getTeacherStats(String teacherId) async {
    try {
      // Only count classrooms affiliated with this school
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: teacherId)
          .where('schoolId', isEqualTo: _schoolId)
          .get();

      int classroomCount = classroomsSnapshot.docs.length;
      Set<String> uniqueStudents = {};

      for (var classroom in classroomsSnapshot.docs) {
        final studentIds = List<String>.from(
          classroom.data()['studentIds'] ?? [],
        );
        uniqueStudents.addAll(studentIds);
      }

      // Filter out deleted students
      int existingStudentCount = 0;
      for (var studentId in uniqueStudents) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        if (studentDoc.exists) {
          existingStudentCount++;
        }
      }

      return {'classrooms': classroomCount, 'students': existingStudentCount};
    } catch (e) {
      return {'classrooms': 0, 'students': 0};
    }
  }

  Widget _buildTeacherStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: ListSkeleton(itemCount: 5));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTeachers,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Teacher Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_approvedTeachers.length} approved • ${_pendingTeachers.length} pending',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_pendingTeachers.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Pending Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final teacher = _pendingTeachers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.orange.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage: teacher['avatarUrl'] != null
                                      ? AssetImage(teacher['avatarUrl'])
                                      : null,
                                  child: teacher['avatarUrl'] == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.orange,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        teacher['displayName'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        teacher['email'] ?? '',
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveTeacher(
                                      teacher['id'],
                                      teacher['requestId'],
                                    ),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _rejectTeacher(teacher['requestId']),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: const BorderSide(color: Colors.red),
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
                      );
                    }, childCount: _pendingTeachers.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Approved Teachers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_approvedTeachers.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No approved teachers yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final teacher = _approvedTeachers[index];
                      return FutureBuilder<Map<String, int>>(
                        future: _getTeacherStats(teacher['id']),
                        builder: (context, snapshot) {
                          final stats =
                              snapshot.data ?? {'classrooms': 0, 'students': 0};

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppDesignSystem
                                          .primaryIndigo
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          teacher['avatarUrl'] != null
                                          ? AssetImage(teacher['avatarUrl'])
                                          : null,
                                      child: teacher['avatarUrl'] == null
                                          ? const Icon(
                                              Icons.person,
                                              color:
                                                  AppDesignSystem.primaryIndigo,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            teacher['displayName'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            teacher['email'] ?? '',
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
                                    IconButton(
                                      onPressed: () => _removeTeacher(
                                        teacher['id'],
                                        teacher['displayName'] ??
                                            'this teacher',
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Remove teacher',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTeacherStatChip(
                                        Icons.class_,
                                        '${stats['classrooms']} Classrooms',
                                        const Color(0xFF8B5CF6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTeacherStatChip(
                                        Icons.people,
                                        '${stats['students']} Students',
                                        const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }, childCount: _approvedTeachers.length),
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

class _SchoolClassroomsTab extends StatefulWidget {
  const _SchoolClassroomsTab();
  @override
  State<_SchoolClassroomsTab> createState() => _SchoolClassroomsTabState();
}

class _SchoolClassroomsTabState extends State<_SchoolClassroomsTab> {
  String? _schoolId;
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
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      _schoolId = userDoc.data()?['principalOfSchool'];

      if (_schoolId != null) {
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('schoolId', isEqualTo: _schoolId)
            .get();

        _classrooms = [];
        for (var doc in classroomsSnapshot.docs) {
          final data = doc.data();
          String teacherName = 'Unknown';
          final teacherId = data['teacherId'];
          if (teacherId != null) {
            final teacherDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(teacherId)
                .get();
            if (teacherDoc.exists) {
              teacherName = teacherDoc.data()?['displayName'] ?? 'Unknown';
            }
          }

          // Filter out deleted students
          final studentIds =
              (data['studentIds'] as List?)?.cast<String>() ?? [];
          int existingStudentCount = 0;

          for (var studentId in studentIds) {
            final studentDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(studentId)
                .get();
            if (studentDoc.exists) {
              existingStudentCount++;
            }
          }

          _classrooms.add({
            'id': doc.id,
            'teacherName': teacherName,
            'existingStudentCount': existingStudentCount, // Add filtered count
            ...data,
          });
        }
      }

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
      return const Scaffold(body: ListSkeleton(itemCount: 5));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadClassrooms,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'School Classrooms',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_classrooms.length} classroom${_classrooms.length == 1 ? '' : 's'} across all teachers',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_classrooms.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.class_, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No classrooms yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Teachers will create classrooms soon',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final classroom = _classrooms[index];
                      final studentCount =
                          classroom['existingStudentCount'] ?? 0;
                      final pendingCount =
                          (classroom['pendingStudentIds'] as List?)?.length ??
                          0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppDesignSystem.primaryIndigo
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.class_,
                                    color: AppDesignSystem.primaryIndigo,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        classroom['name'] ??
                                            'Untitled Classroom',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              classroom['teacherName'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildClassroomStat(
                                    Icons.people,
                                    studentCount.toString(),
                                    'Students',
                                    const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildClassroomStat(
                                    Icons.access_time,
                                    pendingCount.toString(),
                                    'Pending',
                                    const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.15),
                                          const Color(
                                            0xFFA78BFA,
                                          ).withValues(alpha: 0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_2,
                                          size: 18,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          classroom['joinCode'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8B5CF6),
                                            letterSpacing: 0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Code',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF8B5CF6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (classroom['description'] != null &&
                                classroom['description']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                classroom['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Show QR Code Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: QrCodeWidget(
                                        type: 'classroom',
                                        code: classroom['joinCode'] ?? '',
                                        name: classroom['name'] ?? 'Classroom',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2, size: 20),
                                label: const Text('Show QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _classrooms.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolAnalyticsTab extends StatefulWidget {
  const _SchoolAnalyticsTab();
  @override
  State<_SchoolAnalyticsTab> createState() => _SchoolAnalyticsTabState();
}

class _SchoolAnalyticsTabState extends State<_SchoolAnalyticsTab> {
  String? _schoolId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _topStudents = [];
  int _totalStudents = 0;
  double _avgXP = 0;
  int _activeThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      _schoolId = userDoc.data()?['principalOfSchool'];

      if (_schoolId != null) {
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('schoolId', isEqualTo: _schoolId)
            .get();

        Set<String> uniqueStudentIds = {};
        for (var classroom in classroomsSnapshot.docs) {
          final studentIds = List<String>.from(
            classroom.data()['studentIds'] ?? [],
          );
          uniqueStudentIds.addAll(studentIds);
        }

        List<Map<String, dynamic>> students = [];
        int totalXP = 0;

        // Only count existing students
        for (var studentId in uniqueStudentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();

          if (studentDoc.exists) {
            final studentData = studentDoc.data()!;
            final xp = (studentData['totalXP'] ?? 0) as int;
            totalXP += xp;

            students.add({
              'id': studentId,
              'name': studentData['displayName'] ?? 'Unknown',
              'xp': xp,
              'avatarUrl': studentData['avatarUrl'],
            });

            final lastActive = studentData['lastActiveDate'] as Timestamp?;
            if (lastActive != null) {
              final daysSince = DateTime.now()
                  .difference(lastActive.toDate())
                  .inDays;
              if (daysSince <= 7) {
                _activeThisWeek++;
              }
            }
          }
        }

        _totalStudents = students.length;
        if (_totalStudents > 0) {
          _avgXP = totalXP / _totalStudents;
        }

        students.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
        _topStudents = students.take(10).toList();
      }

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
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LoadingSkeleton(
                      height: 100,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: LoadingSkeleton(
                      height: 100,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              LoadingSkeleton(
                height: 200,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(height: 16),
              ListSkeleton(itemCount: 3),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'School Analytics',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Performance insights across your school',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Metrics',
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
                            child: _buildMetricCard(
                              'Total Students',
                              _totalStudents.toString(),
                              Icons.people,
                              const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Avg XP',
                              _avgXP.toStringAsFixed(0),
                              Icons.stars,
                              const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Active This Week',
                              _activeThisWeek.toString(),
                              Icons.trending_up,
                              const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Engagement',
                              '${((_activeThisWeek / (_totalStudents > 0 ? _totalStudents : 1)) * 100).toStringAsFixed(0)}%',
                              Icons.pie_chart,
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Top Performers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_topStudents.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No student data yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = _topStudents[index];
                      final rank = index + 1;
                      Color rankColor;
                      IconData rankIcon;

                      if (rank == 1) {
                        rankColor = const Color(0xFFFFD700);
                        rankIcon = Icons.workspace_premium;
                      } else if (rank == 2) {
                        rankColor = const Color(0xFFC0C0C0);
                        rankIcon = Icons.workspace_premium;
                      } else if (rank == 3) {
                        rankColor = const Color(0xFFCD7F32);
                        rankIcon = Icons.workspace_premium;
                      } else {
                        rankColor = Colors.grey;
                        rankIcon = Icons.star_border;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: rank <= 3
                              ? Border.all(
                                  color: rankColor.withValues(alpha: 0.3),
                                  width: 2,
                                )
                              : null,
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: rank <= 3
                                    ? Icon(rankIcon, color: rankColor, size: 20)
                                    : Text(
                                        '$rank',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: rankColor,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppDesignSystem.primaryIndigo
                                  .withValues(alpha: 0.1),
                              backgroundImage: student['avatarUrl'] != null
                                  ? AssetImage(student['avatarUrl'])
                                  : null,
                              child: student['avatarUrl'] == null
                                  ? const Icon(
                                      Icons.person,
                                      color: AppDesignSystem.primaryIndigo,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Color(0xFFF59E0B),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${student['xp']} XP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _topStudents.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PrincipalProfileTab extends StatefulWidget {
  const _PrincipalProfileTab();
  @override
  State<_PrincipalProfileTab> createState() => _PrincipalProfileTabState();
}

class _PrincipalProfileTabState extends State<_PrincipalProfileTab> {
  String? _displayName;
  String? _email;
  String? _avatarUrl;
  String? _schoolId;
  String? _schoolName;
  String? _schoolCode;
  String? _state;
  String? _city;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _displayName = userData['displayName'];
        _email = userData['email'];
        _avatarUrl = userData['avatarUrl'];

        final schoolId = userData['principalOfSchool'];
        _schoolId = schoolId;

        if (schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
          if (schoolDoc.exists) {
            final schoolData = schoolDoc.data()!;
            _schoolName = schoolData['name'];
            _schoolCode = schoolData['schoolCode'];
            _state = schoolData['state'];
            _city = schoolData['city'];
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileSkeleton();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                            imageUrl: _avatarUrl,
                            initials:
                                _displayName?.substring(0, 1).toUpperCase() ??
                                'P',
                            size: 60,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayName ?? 'Principal',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _email ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Principal',
                                    style: TextStyle(
                                      color: Colors.black87,
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
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                        children: [
                          _buildInfoRow(
                            Icons.school,
                            'School Name',
                            _schoolName ?? 'N/A',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.qr_code,
                            'School Code',
                            _schoolCode ?? 'N/A',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.location_city,
                            'City',
                            _city ?? 'N/A',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.map, 'State', _state ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppDesignSystem.primaryIndigo, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
