import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../student/my_progress_screen.dart';
import '../../services/simplified_chat_service.dart';
import '../chat/chat_screen.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final List<Map<String, dynamic>> _students = [];
  final List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = true;
  String _sortBy = 'xp'; // xp, name, completion
  String? _selectedClassroomId; // null means "All Classrooms"

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      _classrooms.clear();
      _classrooms.add({'id': null, 'name': 'All Classrooms'}); // Add "All" option

      for (var doc in classroomsSnapshot.docs) {
        _classrooms.add({
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unnamed Classroom',
        });
      }

      await _loadStudents();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get classrooms based on filter
      Query classroomsQuery = FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid);

      final classroomsSnapshot = await classroomsQuery.get();

      Set<String> allStudentIds = {};
      Map<String, List<String>> studentClassrooms = {}; // Changed to List to handle multiple classrooms
      Map<String, String> studentClassroomIds = {};

      // Collect student IDs based on selected classroom
      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomId = classroomDoc.id;

        // Skip if filtering by classroom and this isn't the selected one
        if (_selectedClassroomId != null && classroomId != _selectedClassroomId) {
          continue;
        }

        final classroomData = classroomDoc.data() as Map<String, dynamic>;
        final studentIds = List<String>.from(classroomData['studentIds'] as List? ?? []);
        final classroomName = classroomData['name'] as String? ?? 'Unknown';

        for (String studentId in studentIds) {
          allStudentIds.add(studentId); // Set ensures uniqueness
          
          // Add classroom to student's list of classrooms
          if (!studentClassrooms.containsKey(studentId)) {
            studentClassrooms[studentId] = [];
          }
          studentClassrooms[studentId]!.add(classroomName);
          
          // Store first classroom ID for reference
          if (!studentClassroomIds.containsKey(studentId)) {
            studentClassroomIds[studentId] = classroomId;
          }
        }
      }

      _students.clear();

      // Load each student's data
      for (String studentId in allStudentIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;

        // Skip deleted users
        if (userData['isDeleted'] == true) continue;

        // Get progress
        final progressSnapshot = await FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: studentId)
            .get();

        // Calculate completion stats
        final completedDocs = progressSnapshot.docs
            .where((doc) => doc.data()['status'] == 'completed')
            .toList();

        int completedLevels = completedDocs.length;
        int totalLevels = 60; // 6 realms × 10 levels each

        // Calculate grades
        int totalScore = 0;
        int quizCount = 0;
        for (var doc in completedDocs) {
          final accuracy = doc.data()['accuracy'];
          if (accuracy is int) {
            totalScore += accuracy;
            quizCount++;
          }
        }

        double avgScore = quizCount > 0 ? totalScore / quizCount : 0;
        String grade = _calculateGrade(avgScore);

        // Completion rate
        double completionRate = (completedLevels / totalLevels * 100).clamp(0, 100);

        // Format classroom names
        final classroomsList = studentClassrooms[studentId] ?? ['Unknown'];
        final classroomDisplay = classroomsList.length > 1 
            ? '${classroomsList.length} classes' 
            : classroomsList.first;
        
        _students.add({
          'id': studentId,
          'name': userData['displayName'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'classroom': classroomDisplay,
          'classrooms': classroomsList, // Store full list
          'classroomId': studentClassroomIds[studentId],
          'totalXP': userData['totalXP'] ?? 0,
          'completedLevels': completedLevels,
          'totalLevels': totalLevels,
          'completionRate': completionRate,
          'avgScore': avgScore,
          'grade': grade,
          'currentStreak': userData['currentStreak'] ?? 0,
          'badges': (userData['badges'] as List?)?.length ?? 0,
        });
      }

      _sortStudents();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sortStudents() {
    switch (_sortBy) {
      case 'xp':
        _students.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
        break;
      case 'name':
        _students.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
      case 'completion':
        _students.sort((a, b) => (b['completionRate'] as double).compareTo(a['completionRate'] as double));
        break;
    }
  }

  String _calculateGrade(double avgScore) {
    if (avgScore >= 90) return 'A+';
    if (avgScore >= 80) return 'A';
    if (avgScore >= 70) return 'B+';
    if (avgScore >= 60) return 'B';
    if (avgScore >= 50) return 'C';
    return 'D';
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return AppDesignSystem.success;
    if (grade.startsWith('B')) return AppDesignSystem.primaryIndigo;
    if (grade.startsWith('C')) return AppDesignSystem.warning;
    return AppDesignSystem.error;
  }

  Future<void> _viewStudentDetails(Map<String, dynamic> student) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyProgressScreen(
          studentId: student['id'],
          studentName: student['name'],
        ),
      ),
    );
  }

  Future<void> _messageStudent(Map<String, dynamic> student) async {
    try {
      final chatService = SimplifiedChatService();
      final teacherId = FirebaseAuth.instance.currentUser!.uid;

      final chatId = await chatService.createTeacherStudentChat(
        teacherId: teacherId,
        studentId: student['id'],
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: student['name'],
            otherUserAvatar: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  Future<void> _removeStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Are you sure you want to remove ${student['name']} from their classroom?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppDesignSystem.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomId = classroomDoc.id;
        final data = classroomDoc.data() as Map<String, dynamic>;
        final studentIds = List<String>.from(data['studentIds'] as List? ?? []);

        if (studentIds.contains(student['id'])) {
          await FirebaseFirestore.instance
              .collection('classrooms')
              .doc(classroomId)
              .update({
            'studentIds': FieldValue.arrayRemove([student['id']]),
            'updatedAt': Timestamp.now(),
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(student['id'])
              .update({
            'classroomIds': FieldValue.arrayRemove([classroomId]),
            'updatedAt': Timestamp.now(),
          });
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student['name']} removed successfully'),
          backgroundColor: AppDesignSystem.success,
        ),
      );

      _loadStudents(); // Fixed: was _loadAllStudents()
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Purple Gradient Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'All Students',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Student Count
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_students.length} ${_students.length == 1 ? 'Student' : 'Students'}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  // Classroom Filter - Vertical Tabs
                  if (_classrooms.length > 1)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _classrooms.length,
                        itemBuilder: (context, index) {
                          final classroom = _classrooms[index];
                          final isSelected = _selectedClassroomId == classroom['id'];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedClassroomId = classroom['id'];
                                });
                                _loadStudents();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(isSelected ? 1.0 : 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  classroom['name'],
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Sort Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortChip('Total XP', 'xp'),
                          const SizedBox(width: 8),
                          _buildSortChip('Name', 'name'),
                          const SizedBox(width: 8),
                          _buildSortChip('Completion', 'completion'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No students found',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CleanCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Student Info
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              gradient: AppDesignSystem.gradientPrimary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                student['name'][0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(student['name'], style: AppTextStyles.cardTitle),
                                                Text(student['classroom'], style: AppTextStyles.bodySmall),
                                              ],
                                            ),
                                          ),
                                          // Grade Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getGradeColor(student['grade']),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              student['grade'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 12),

                                      // Stats Grid
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildMiniStat(
                                            Icons.stars,
                                            '${student['totalXP']}',
                                            'XP',
                                            AppDesignSystem.primaryAmber,
                                          ),
                                          _buildMiniStat(
                                            Icons.check_circle,
                                            '${student['completedLevels']}/${student['totalLevels']}',
                                            'Levels',
                                            AppDesignSystem.success,
                                          ),
                                          _buildMiniStat(
                                            Icons.school,
                                            '${student['avgScore'].toStringAsFixed(0)}%',
                                            'Avg Score',
                                            AppDesignSystem.primaryIndigo,
                                          ),
                                          _buildMiniStat(
                                            Icons.emoji_events,
                                            '${student['badges']}',
                                            'Badges',
                                            AppDesignSystem.warning,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _viewStudentDetails(student),
                                              icon: const Icon(Icons.visibility, size: 18),
                                              label: const Text('View', style: TextStyle(fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _messageStudent(student),
                                              icon: const Icon(Icons.message, size: 18),
                                              label: const Text('Message', style: TextStyle(fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                foregroundColor: AppDesignSystem.primaryIndigo,
                                                side: BorderSide(color: AppDesignSystem.primaryIndigo),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _removeStudent(student),
                                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                                              label: const Text('Remove', style: TextStyle(fontSize: 13)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                foregroundColor: AppDesignSystem.error,
                                                side: BorderSide(color: AppDesignSystem.error),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Completion Progress Bar
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Course Completion',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${student['completionRate'].toStringAsFixed(0)}%',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppDesignSystem.success,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: student['completionRate'] / 100,
                                              minHeight: 8,
                                              backgroundColor: AppDesignSystem.backgroundWhite,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.success),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortStudents();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }
}