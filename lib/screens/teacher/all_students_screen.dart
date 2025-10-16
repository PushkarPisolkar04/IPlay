import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({Key? key}) : super(key: key);

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _sortBy = 'xp'; // xp, name, completion

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
  }

  Future<void> _loadAllStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      Set<String> allStudentIds = {};
      Map<String, String> studentClassrooms = {};

      // Collect all unique student IDs
      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final studentIds = List<String>.from(classroomData['studentIds'] ?? []);
        final classroomName = classroomData['name'] as String;
        
        for (String studentId in studentIds) {
          allStudentIds.add(studentId);
          studentClassrooms[studentId] = classroomName;
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
        int totalLevels = 36; // 6 realms × 6 levels average

        // Calculate grades
        int totalScore = 0;
        int quizCount = 0;
        for (var doc in completedDocs) {
          if (doc.data()['accuracy'] != null) {
            totalScore += (doc.data()['accuracy'] as int);
            quizCount++;
          }
        }
        
        double avgScore = quizCount > 0 ? totalScore / quizCount : 0;
        String grade = _calculateGrade(avgScore);
        
        // Completion rate
        double completionRate = (completedLevels / totalLevels * 100).clamp(0, 100);

        _students.add({
          'id': studentId,
          'name': userData['displayName'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'classroom': studentClassrooms[studentId] ?? 'Unknown',
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
      print('Error loading students: $e');
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
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.primary;
    if (grade.startsWith('C')) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'All Students Summary',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_students.length} Students',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sort Options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('No students found'))
                    : RefreshIndicator(
                        onRefresh: _loadAllStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CleanCard(
                                padding: const EdgeInsets.all(16),
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
                                            gradient: AppColors.primaryGradient,
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
                                          AppColors.accent,
                                        ),
                                        _buildMiniStat(
                                          Icons.check_circle,
                                          '${student['completedLevels']}/${student['totalLevels']}',
                                          'Levels',
                                          AppColors.success,
                                        ),
                                        _buildMiniStat(
                                          Icons.school,
                                          '${student['avgScore'].toStringAsFixed(0)}%',
                                          'Avg Score',
                                          AppColors.primary,
                                        ),
                                        _buildMiniStat(
                                          Icons.emoji_events,
                                          '${student['badges']}',
                                          'Badges',
                                          AppColors.warning,
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
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
                                                color: AppColors.success,
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
                                            backgroundColor: AppColors.textLight,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
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
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

