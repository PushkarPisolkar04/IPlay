import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'dart:typed_data';

/// Service for generating reports (PDF and CSV)
/// No Cloud Functions needed - all client-side
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate Student Progress Report (PDF)
  Future<Uint8List> generateStudentReport(String studentId) async {
    final user = await _firestore.collection('users').doc(studentId).get();
    final userData = user.data()!;

    final progress = await _firestore
        .collection('progress')
        .where('userId', isEqualTo: studentId)
        .get();

    // Calculate statistics
    final completedProgress = progress.docs.where((doc) => doc.data()['status'] == 'completed').toList();
    final totalProgress = progress.docs.length;
    final completionRate = totalProgress > 0 ? (completedProgress.length / totalProgress * 100).toStringAsFixed(1) : '0';
    
    int totalXPEarned = 0;
    int totalQuizzes = 0;
    int totalAccuracy = 0;
    
    for (var doc in completedProgress) {
      final data = doc.data();
      totalXPEarned += (data['xpEarned'] as int?) ?? 0;
      if (data['accuracy'] != null) {
        totalAccuracy += (data['accuracy'] as int);
        totalQuizzes++;
      }
    }
    
    final avgAccuracy = totalQuizzes > 0 ? (totalAccuracy / totalQuizzes).toStringAsFixed(1) : '0';
    final level = _calculateLevel(userData['totalXP'] ?? 0);
    final badges = (userData['badges'] as List?)?.length ?? 0;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Student Progress Report',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),
          
          // Student Information
          pw.Header(level: 1, child: pw.Text('Student Information', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${userData['displayName'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Email: ${userData['email'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Level: $level', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total XP: ${userData['totalXP'] ?? 0}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Badges Earned: $badges', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Current Streak: ${userData['currentStreak'] ?? 0} days', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Performance Summary
          pw.Header(level: 1, child: pw.Text('Performance Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Realms Completed', '${completedProgress.length} / $totalProgress'],
              ['Completion Rate', '$completionRate%'],
              ['Total XP Earned from Realms', totalXPEarned.toString()],
              ['Quizzes Completed', totalQuizzes.toString()],
              ['Average Quiz Accuracy', '$avgAccuracy%'],
              ['Longest Streak', '${userData['longestStreak'] ?? 0} days'],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
          ),
          pw.SizedBox(height: 20),
          
          // Detailed Realm Progress
          pw.Header(level: 1, child: pw.Text('Detailed Realm Progress', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          if (progress.docs.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Realm', 'Status', 'XP Earned', 'Accuracy'],
              data: progress.docs.map((doc) {
                final data = doc.data();
                return [
                  data['contentId'] ?? 'Unknown',
                  data['status'] ?? 'Not Started',
                  '${data['xpEarned'] ?? 0} XP',
                  data['accuracy'] != null ? '${data['accuracy']}%' : 'N/A',
                ];
              }).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellHeight: 25,
            )
          else
            pw.Text('No realm progress recorded yet.', style: const pw.TextStyle(fontSize: 12)),
          
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Report Generated: ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 1000) return 4;
    if (xp < 2000) return 5;
    if (xp < 3500) return 6;
    if (xp < 5500) return 7;
    if (xp < 8000) return 8;
    if (xp < 11000) return 9;
    return 10;
  }

  /// Export Class Data as CSV
  Future<String> exportClassDataCSV(String classroomId) async {
    final classroom = await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .get();

    final studentIds = List<String>.from(classroom['studentIds']);

    List<List<dynamic>> rows = [
      ['Name', 'Email', 'Total XP', 'Streak', 'Realms Completed', 'Join Date'],
    ];

    for (String studentId in studentIds) {
      final user = await _firestore.collection('users').doc(studentId).get();
      if (!user.exists) continue;
      
      final userData = user.data()!;
      // Skip deleted students
      if (userData['isDeleted'] == true) continue;

      final progressSummary =
          userData['progressSummary'] as Map<String, dynamic>?;
      final realmsCompleted =
          progressSummary?.values.where((v) => v['completed'] == true).length ??
          0;

      rows.add([
        userData['displayName'] ?? '',
        userData['email'] ?? '',
        userData['totalXP'] ?? 0,
        userData['currentStreak'] ?? 0,
        realmsCompleted,
        (userData['createdAt'] as Timestamp?)?.toDate().toString().split(
              ' ',
            )[0] ??
            '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export School Analytics as CSV
  Future<String> exportSchoolAnalyticsCSV(String schoolId) async {
    final classrooms = await _firestore
        .collection('classrooms')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    List<List<dynamic>> rows = [
      ['Classroom', 'Teacher', 'Active Students', 'Total XP', 'Avg XP'],
    ];

    for (var classroom in classrooms.docs) {
      final classData = classroom.data();
      final studentIds = List<String>.from(classData['studentIds']);

      int totalXP = 0;
      int activeStudents = 0;
      
      for (String studentId in studentIds) {
        final user = await _firestore.collection('users').doc(studentId).get();
        // Skip deleted students
        if (user.exists && user.data()?['isDeleted'] != true) {
          activeStudents++;
          totalXP += (user.data()?['totalXP'] ?? 0) as int;
        }
      }

      rows.add([
        classData['name'],
        classData['teacherName'],
        activeStudents,
        totalXP,
        activeStudents > 0
            ? (totalXP / activeStudents).toStringAsFixed(1)
            : '0',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generate Classroom Performance Report (PDF)
  Future<Uint8List> generateClassroomReport(String classroomId) async {
    final classroom = await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .get();
    final classData = classroom.data()!;

    final studentIds = List<String>.from(classData['studentIds']);

    final pdf = pw.Document();

    // Gather student data - filter out deleted students
    List<Map<String, dynamic>> studentData = [];
    int totalXP = 0;
    int totalStreak = 0;
    int totalBadges = 0;
    int totalRealmsCompleted = 0;
    
    for (String studentId in studentIds) {
      final user = await _firestore.collection('users').doc(studentId).get();
      if (!user.exists) continue;
      
      final userData = user.data()!;
      // Skip deleted students
      if (userData['isDeleted'] == true) continue;
      
      studentData.add(userData);
      totalXP += (userData['totalXP'] as int?) ?? 0;
      totalStreak += (userData['currentStreak'] as int?) ?? 0;
      totalBadges += ((userData['badges'] as List?)?.length ?? 0);
      
      final progressSummary = userData['progressSummary'] as Map?;
      if (progressSummary != null) {
        totalRealmsCompleted += progressSummary.values
            .where((v) => v['completed'] == true)
            .length;
      }
    }

    final studentCount = studentData.length;
    final avgXP = studentCount > 0 ? (totalXP / studentCount).toStringAsFixed(1) : '0';
    final avgStreak = studentCount > 0 ? (totalStreak / studentCount).toStringAsFixed(1) : '0';
    final avgBadges = studentCount > 0 ? (totalBadges / studentCount).toStringAsFixed(1) : '0';
    final avgRealms = studentCount > 0 ? (totalRealmsCompleted / studentCount).toStringAsFixed(1) : '0';

    // Sort students by XP for top performers
    studentData.sort((a, b) => ((b['totalXP'] ?? 0) as int).compareTo((a['totalXP'] ?? 0) as int));
    final topPerformers = studentData.take(5).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Classroom Performance Report',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),
          
          // Classroom Information
          pw.Header(level: 1, child: pw.Text('Classroom Information', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Classroom: ${classData['name'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Teacher: ${classData['teacherName'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Grade: ${classData['grade'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text('Total Students: $studentCount', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Class Statistics
          pw.Header(level: 1, child: pw.Text('Class Statistics', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Total', 'Average per Student'],
            data: [
              ['Total XP', totalXP.toString(), avgXP],
              ['Current Streak (days)', totalStreak.toString(), avgStreak],
              ['Badges Earned', totalBadges.toString(), avgBadges],
              ['Realms Completed', totalRealmsCompleted.toString(), avgRealms],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
          ),
          pw.SizedBox(height: 20),
          
          // Top Performers
          if (topPerformers.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Top 5 Performers', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Rank', 'Name', 'XP', 'Level', 'Streak', 'Badges'],
              data: topPerformers.asMap().entries.map((entry) {
                final student = entry.value;
                final rank = entry.key + 1;
                return [
                  rank.toString(),
                  student['displayName'] ?? 'N/A',
                  '${student['totalXP'] ?? 0}',
                  _calculateLevel(student['totalXP'] ?? 0).toString(),
                  '${student['currentStreak'] ?? 0}',
                  '${(student['badges'] as List?)?.length ?? 0}',
                ];
              }).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellHeight: 25,
            ),
            pw.SizedBox(height: 20),
          ],
          
          // All Students Performance
          pw.Header(level: 1, child: pw.Text('All Students Performance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          if (studentData.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'XP', 'Level', 'Streak', 'Realms'],
              data: studentData.map((student) {
                final progressSummary = student['progressSummary'] as Map?;
                final realmsCompleted =
                    progressSummary?.values
                        .where((v) => v['completed'] == true)
                        .length ??
                    0;
                return [
                  student['displayName'] ?? 'N/A',
                  '${student['totalXP'] ?? 0}',
                  _calculateLevel(student['totalXP'] ?? 0).toString(),
                  '${student['currentStreak'] ?? 0}',
                  '$realmsCompleted/6',
                ];
              }).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellHeight: 25,
            )
          else
            pw.Text('No active students in this classroom.', style: const pw.TextStyle(fontSize: 12)),
          
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Report Generated: ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate School Analytics Report (PDF) - All classrooms
  Future<Uint8List> generateSchoolReport(String schoolId) async {
    final classrooms = await _firestore
        .collection('classrooms')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final pdf = pw.Document();

    // Gather school-wide data
    int totalStudents = 0;
    int totalXP = 0;
    int totalStreak = 0;
    int totalBadges = 0;
    List<Map<String, dynamic>> classroomData = [];

    for (var classroom in classrooms.docs) {
      final classData = classroom.data();
      final studentIds = List<String>.from(classData['studentIds'] ?? []);

      int classXP = 0;
      int classStreak = 0;
      int classBadges = 0;
      int activeStudents = 0;

      for (String studentId in studentIds) {
        final user = await _firestore.collection('users').doc(studentId).get();
        if (user.exists && user.data()?['isDeleted'] != true) {
          activeStudents++;
          classXP += (user.data()?['totalXP'] ?? 0) as int;
          classStreak += (user.data()?['currentStreak'] ?? 0) as int;
          classBadges += ((user.data()?['badges'] as List?)?.length ?? 0);
        }
      }

      totalStudents += activeStudents;
      totalXP += classXP;
      totalStreak += classStreak;
      totalBadges += classBadges;

      classroomData.add({
        'name': classData['name'] ?? 'Unknown',
        'teacher': classData['teacherName'] ?? 'Unknown',
        'students': activeStudents,
        'xp': classXP,
        'avgXP': activeStudents > 0 ? (classXP / activeStudents).toStringAsFixed(1) : '0',
        'avgStreak': activeStudents > 0 ? (classStreak / activeStudents).toStringAsFixed(1) : '0',
      });
    }

    // Sort by total XP
    classroomData.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'School Analytics Report',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // School Summary
          pw.Header(level: 1, child: pw.Text('School Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Total', 'Average'],
            data: [
              ['Total Classrooms', classrooms.docs.length.toString(), '-'],
              ['Total Students', totalStudents.toString(), '-'],
              ['Total XP', totalXP.toString(), totalStudents > 0 ? (totalXP / totalStudents).toStringAsFixed(1) : '0'],
              ['Total Streak', totalStreak.toString(), totalStudents > 0 ? (totalStreak / totalStudents).toStringAsFixed(1) : '0'],
              ['Total Badges', totalBadges.toString(), totalStudents > 0 ? (totalBadges / totalStudents).toStringAsFixed(1) : '0'],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
          ),
          pw.SizedBox(height: 20),

          // Classroom Breakdown
          pw.Header(level: 1, child: pw.Text('Classroom Performance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Classroom', 'Teacher', 'Students', 'Total XP', 'Avg XP', 'Avg Streak'],
            data: classroomData.map((c) => [
              c['name'],
              c['teacher'],
              c['students'].toString(),
              c['xp'].toString(),
              c['avgXP'],
              c['avgStreak'],
            ]).toList(),
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellHeight: 25,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Submit a content report (bug, inappropriate content, etc.)
  Future<void> submitReport({
    required String reportType,
    required String contentId,
    required String description,
    String? screenshotUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'reportType': reportType, // 'bug', 'content', 'user', etc.
      'contentId': contentId,
      'description': description,
      'screenshotUrl': screenshotUrl,
      'status': 'pending',
      'reportedAt': Timestamp.now(),
    });
  }
}
