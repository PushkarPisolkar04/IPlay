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

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Student Progress Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Name: ${userData['displayName']}'),
          pw.Text('Email: ${userData['email']}'),
          pw.Text('Total XP: ${userData['totalXP']}'),
          pw.Text('Current Streak: ${userData['currentStreak']} days'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Realm Progress')),
          pw.TableHelper.fromTextArray(
            headers: ['Content', 'Status', 'XP Earned', 'Accuracy'],
            data: progress.docs.map((doc) {
              final data = doc.data();
              return [
                data['contentId'] ?? '',
                data['status'] ?? '',
                '${data['xpEarned'] ?? 0}',
                '${data['accuracy'] ?? 0}%',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Report Generated: ${DateTime.now().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return pdf.save();
  }

  /// Export Class Data as CSV
  Future<String> exportClassDataCSV(String classroomId) async {
    final classroom = await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .get();

    final studentIds = List<String>.from(classroom['studentIds']);

    List<List<dynamic>> rows = [
      ['Name', 'Email', 'Total XP', 'Streak', 'Realms Completed', 'Join Date']
    ];

    for (String studentId in studentIds) {
      final user = await _firestore.collection('users').doc(studentId).get();
      final userData = user.data()!;

      final progressSummary = userData['progressSummary'] as Map<String, dynamic>?;
      final realmsCompleted = progressSummary?.values
              .where((v) => v['completed'] == true)
              .length ??
          0;

      rows.add([
        userData['displayName'] ?? '',
        userData['email'] ?? '',
        userData['totalXP'] ?? 0,
        userData['currentStreak'] ?? 0,
        realmsCompleted,
        (userData['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? '',
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
      ['Classroom', 'Teacher', 'Students', 'Total XP', 'Avg XP']
    ];

    for (var classroom in classrooms.docs) {
      final classData = classroom.data();
      final studentIds = List<String>.from(classData['studentIds']);
      
      int totalXP = 0;
      for (String studentId in studentIds) {
        final user = await _firestore.collection('users').doc(studentId).get();
        totalXP += (user.data()?['totalXP'] ?? 0) as int;
      }

      rows.add([
        classData['name'],
        classData['teacherName'],
        studentIds.length,
        totalXP,
        studentIds.isNotEmpty ? (totalXP / studentIds.length).toStringAsFixed(1) : '0',
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
    
    // Gather student data
    List<Map<String, dynamic>> studentData = [];
    for (String studentId in studentIds) {
      final user = await _firestore.collection('users').doc(studentId).get();
      studentData.add(user.data()!);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Classroom Performance Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Classroom: ${classData['name']}'),
          pw.Text('Teacher: ${classData['teacherName']}'),
          pw.Text('Total Students: ${studentIds.length}'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Student Performance')),
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'XP', 'Streak', 'Realms'],
            data: studentData.map((student) {
              final progressSummary = student['progressSummary'] as Map?;
              final realmsCompleted = progressSummary?.values
                      .where((v) => v['completed'] == true)
                      .length ??
                  0;
              return [
                student['displayName'] ?? '',
                '${student['totalXP'] ?? 0}',
                '${student['currentStreak'] ?? 0}',
                '$realmsCompleted/6',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Report Generated: ${DateTime.now().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 10)),
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
