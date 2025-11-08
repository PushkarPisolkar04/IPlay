import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../core/services/report_service.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final List<Map<String, dynamic>> _students = [];
  final List<Map<String, dynamic>> _classrooms = [];
  String? _selectedStudentId;
  String? _selectedClassroomId;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _reportType = 'student'; // 'student' or 'classroom'
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      Set<String> allStudentIds = {};
      
      for (var doc in classroomsSnapshot.docs) {
        final classData = doc.data();
        _classrooms.add({
          'id': doc.id,
          'name': classData['name'] ?? 'Unknown',
          'studentCount': (classData['studentIds'] as List?)?.length ?? 0,
        });
        
        final studentIds = List<String>.from(classData['studentIds'] ?? []);
        allStudentIds.addAll(studentIds);
      }

      _classrooms.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Get all students
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
      // print('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_reportType == 'student' && _selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }
    
    if (_reportType == 'classroom' && _selectedClassroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classroom')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      if (_reportType == 'student') {
        // Fetch complete student data for preview
        final studentData = await _fetchStudentReportData(_selectedStudentId!);
        
        if (mounted) {
          _showReportPreviewDialog(studentData, 'student');
        }
      } else {
        // Fetch classroom data for preview
        final classroomData = await _fetchClassroomReportData(_selectedClassroomId!);
        
        if (mounted) {
          _showReportPreviewDialog(classroomData, 'classroom');
        }
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
  
  Future<Map<String, dynamic>> _fetchClassroomReportData(String classroomId) async {
    final classroomDoc = await FirebaseFirestore.instance
        .collection('classrooms')
        .doc(classroomId)
        .get();
    
    final classData = classroomDoc.data()!;
    final studentIds = List<String>.from(classData['studentIds'] ?? []);
    
    int totalXP = 0;
    int totalStreak = 0;
    int totalCompleted = 0;
    
    for (String studentId in studentIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        totalXP += (userData['totalXP'] ?? 0) as int;
        totalStreak += (userData['currentStreak'] ?? 0) as int;
        
        final progressSummary = userData['progressSummary'] as Map?;
        if (progressSummary != null) {
          totalCompleted += progressSummary.values
              .where((v) => v['completed'] == true)
              .length;
        }
      }
    }
    
    return {
      'classroomId': classroomId,
      'name': classData['name'],
      'teacherName': classData['teacherName'],
      'studentCount': studentIds.length,
      'totalXP': totalXP,
      'avgXP': studentIds.isNotEmpty ? (totalXP / studentIds.length).round() : 0,
      'avgStreak': studentIds.isNotEmpty ? (totalStreak / studentIds.length).round() : 0,
      'totalRealmsCompleted': totalCompleted,
    };
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

  void _showReportPreviewDialog(Map<String, dynamic> data, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type == 'student' ? 'Student Report Preview' : 'Classroom Report Preview',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: type == 'student' 
                ? _buildStudentPreview(data)
                : _buildClassroomPreview(data),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _downloadAndShareReport(data, type);
              },
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _downloadAndShareReport(data, type, share: true);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildStudentPreview(Map<String, dynamic> data) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['email'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
    ];
  }
  
  List<Widget> _buildClassroomPreview(Map<String, dynamic> data) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Teacher: ${data['teacherName']}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _buildReportRow('Total Students', '${data['studentCount']}', Icons.people),
      _buildReportRow('Total XP', '${data['totalXP']}', Icons.stars),
      _buildReportRow('Average XP', '${data['avgXP']}', Icons.trending_up),
      _buildReportRow('Average Streak', '${data['avgStreak']} days', Icons.local_fire_department),
      _buildReportRow('Realms Completed', '${data['totalRealmsCompleted']}', Icons.check_circle),
    ];
  }
  
  Future<void> _downloadAndShareReport(Map<String, dynamic> data, String type, {bool share = false}) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 16),
                Text(share ? 'Preparing report to share...' : 'Generating PDF...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Generate PDF
      final pdfBytes = type == 'student'
          ? await _reportService.generateStudentReport(data['studentId'] ?? _selectedStudentId!)
          : await _reportService.generateClassroomReport(data['classroomId'] ?? _selectedClassroomId!);
      
      // Get directory to save
      final directory = await getApplicationDocumentsDirectory();
      final fileName = type == 'student'
          ? 'student_report_${data['name'].replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : 'classroom_report_${data['name'].replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes);
      
      if (share) {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: type == 'student'
              ? 'Student Progress Report for ${data['name']}'
              : 'Classroom Performance Report for ${data['name']}',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Report shared successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        // Just download
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Report saved to: ${file.path}'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () async {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: type == 'student'
                        ? 'Student Progress Report for ${data['name']}'
                        : 'Classroom Performance Report for ${data['name']}',
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // print('Error generating/sharing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildReportRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Generate Report',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Generate detailed PDF reports and export CSV data',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LoadingSkeleton(height: 60, borderRadius: BorderRadius.all(Radius.circular(12))),
                          SizedBox(height: 16),
                          LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
                          SizedBox(height: 16),
                          LoadingSkeleton(height: 60, borderRadius: BorderRadius.all(Radius.circular(12))),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Report Type Selector
                          const Text(
                            'Report Type',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReportTypeButton(
                                  'Student Report',
                                  'student',
                                  Icons.person,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReportTypeButton(
                                  'Classroom Report',
                                  'classroom',
                                  Icons.class_,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          Text(
                            _reportType == 'student' ? 'Select Student' : 'Select Classroom',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_reportType == 'student')
                            ..._buildStudentList()
                          else
                            ..._buildClassroomList(),
                          
                          const SizedBox(height: 24),
                          
                          // Export CSV Button (for classroom reports)
                          if (_reportType == 'classroom' && _selectedClassroomId != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isGenerating ? null : _exportClassroomCSV,
                                  icon: const Icon(Icons.table_chart, size: 24),
                                  label: const Text(
                                    'Export as CSV',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Generate PDF Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
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
                                  : const Icon(Icons.picture_as_pdf, size: 24),
                              label: Text(
                                _isGenerating ? 'Generating...' : 'Generate PDF Report',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
  
  Widget _buildReportTypeButton(String label, String type, IconData icon) {
    final isSelected = _reportType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reportType = type;
          _selectedStudentId = null;
          _selectedClassroomId = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildStudentList() {
    if (_students.isEmpty) {
      return [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No students found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    
    return _students.map((student) {
                              final isSelected = _selectedStudentId == student['id'];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CleanCard(
                                  color: isSelected 
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                      : Colors.white,
                                  onTap: () {
                                    setState(() {
                                      _selectedStudentId = student['id'];
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              student['name'][0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
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
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                student['email'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!, width: 2),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList();
  }
  
  List<Widget> _buildClassroomList() {
    if (_classrooms.isEmpty) {
      return [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.class_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No classrooms found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    
    return _classrooms.map((classroom) {
      final isSelected = _selectedClassroomId == classroom['id'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CleanCard(
          color: isSelected 
              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
              : Colors.white,
          onTap: () {
            setState(() {
              _selectedClassroomId = classroom['id'];
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.class_,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${classroom['studentCount']} students',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  
  Future<void> _exportClassroomCSV() async {
    if (_selectedClassroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classroom')),
      );
      return;
    }
    
    setState(() => _isGenerating = true);
    
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 16),
                Text('Generating CSV...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Generate CSV
      final csvData = await _reportService.exportClassDataCSV(_selectedClassroomId!);
      
      // Get directory to save
      final directory = await getApplicationDocumentsDirectory();
      final classroom = _classrooms.firstWhere((c) => c['id'] == _selectedClassroomId);
      final fileName = 'classroom_data_${classroom['name'].replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      // Write CSV to file
      await file.writeAsString(csvData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('CSV saved to: ${file.path}'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Classroom Data Export for ${classroom['name']}',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // print('Error exporting CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}
