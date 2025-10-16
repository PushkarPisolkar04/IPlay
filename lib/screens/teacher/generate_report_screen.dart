import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({Key? key}) : super(key: key);

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all students
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      Set<String> allStudentIds = {};
      for (var doc in classroomsSnapshot.docs) {
        final studentIds = List<String>.from(doc.data()['studentIds'] ?? []);
        allStudentIds.addAll(studentIds);
      }

      _students.clear();

      for (String studentId in allStudentIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _students.add({
            'id': studentId,
            'name': userData['displayName'] ?? 'Unknown',
            'email': userData['email'] ?? '',
          });
        }
      }

      _students.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Fetch complete student data
      final studentData = await _fetchStudentReportData(_selectedStudentId!);

      // In a real app, you would use a PDF generation library like pdf package
      // For now, we'll show a detailed report dialog
      if (mounted) {
        _showReportDialog(studentData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<Map<String, dynamic>> _fetchStudentReportData(String studentId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get();

    final userData = userDoc.data()!;

    // Get all progress
    final progressSnapshot = await FirebaseFirestore.instance
        .collection('progress')
        .where('userId', isEqualTo: studentId)
        .get();

    final completedDocs = progressSnapshot.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .toList();

    int totalScore = 0;
    int quizCount = 0;
    int totalXP = 0;

    for (var doc in completedDocs) {
      final data = doc.data();
      if (data['accuracy'] != null) {
        totalScore += (data['accuracy'] as int);
        quizCount++;
      }
      totalXP += (data['xpEarned'] as int? ?? 0);
    }

    double avgScore = quizCount > 0 ? totalScore / quizCount : 0;

    return {
      'name': userData['displayName'] ?? 'Unknown',
      'email': userData['email'] ?? '',
      'totalXP': userData['totalXP'] ?? 0,
      'earnedXP': totalXP,
      'currentStreak': userData['currentStreak'] ?? 0,
      'completedLevels': completedDocs.length,
      'totalQuizzes': quizCount,
      'averageScore': avgScore,
      'badges': (userData['badges'] as List?)?.length ?? 0,
      'lastActive': userData['lastActiveDate'] != null 
          ? (userData['lastActiveDate'] as Timestamp).toDate()
          : null,
    };
  }

  void _showReportDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Student Report'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['name'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                data['email'],
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _buildReportRow('Total XP', '${data['totalXP']}', Icons.stars),
              _buildReportRow('XP Earned', '${data['earnedXP']}', Icons.trending_up),
              _buildReportRow('Current Streak', '${data['currentStreak']} days', Icons.local_fire_department),
              _buildReportRow('Completed Levels', '${data['completedLevels']}', Icons.check_circle),
              _buildReportRow('Total Quizzes', '${data['totalQuizzes']}', Icons.quiz),
              _buildReportRow('Average Score', '${data['averageScore'].toStringAsFixed(1)}%', Icons.school),
              _buildReportRow('Badges Earned', '${data['badges']}', Icons.emoji_events),
              if (data['lastActive'] != null)
                _buildReportRow('Last Active', _formatDate(data['lastActive']), Icons.access_time),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF generation feature coming soon!'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Generate Student Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Student',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Student List
                        ..._students.map((student) {
                          final isSelected = _selectedStudentId == student['id'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CleanCard(
                              color: isSelected 
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.white,
                              onTap: () {
                                setState(() {
                                  _selectedStudentId = student['id'];
                                });
                              },
                              child: Row(
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'],
                                          style: AppTextStyles.cardTitle,
                                        ),
                                        Text(
                                          student['email'],
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        
                        const SizedBox(height: 24),
                        
                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateReport,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(
                              _isGenerating ? 'Generating...' : 'Generate Report',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
}

