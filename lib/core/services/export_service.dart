import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'file_download_service.dart';

/// Service for exporting data in multiple formats (CSV, Excel, PDF)
class ExportService {
  /// Export student data to CSV
  Future<String?> exportStudentsToCSV(List<Map<String, dynamic>> students) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> rows = [];
      
      // Enhanced header row
      rows.add([
        'Name',
        'Email',
        'Total XP',
        'Level',
        'Badges',
        'Current Streak',
        'Longest Streak',
        'Completed Levels',
        'Average Score',
        'Joined Date',
      ]);

      // Data rows with enhanced information
      for (var student in students) {
        // Handle both 'name' and 'displayName' fields
        final name = student['name'] ?? student['displayName'] ?? 'N/A';
        final email = student['email'] ?? 'N/A';
        final totalXP = (student['totalXP'] ?? 0);
        final badges = student['badges'] is int 
            ? student['badges'] 
            : (student['badges'] as List?)?.length ?? 0;
        final currentStreak = (student['currentStreak'] ?? 0);
        final longestStreak = (student['longestStreak'] ?? 0);
        final completedLevels = student['completedLevels'] ?? 0;
        final avgScore = student['averageScore'] ?? 0;
        
        rows.add([
          name,
          email,
          totalXP,
          _calculateLevel(totalXP is int ? totalXP : 0),
          badges,
          currentStreak,
          longestStreak,
          completedLevels,
          avgScore is double ? avgScore.toStringAsFixed(1) : avgScore.toString(),
          _formatTimestamp(student['createdAt']),
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Use FileDownloadService for user-selected location
      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: Uint8List.fromList(csv.codeUnits),
        suggestedName: 'students_report_$timestamp.csv',
        mimeType: 'text/csv',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  /// Export student data to Excel
  Future<String?> exportStudentsToExcel(List<Map<String, dynamic>> students) async {
    try {
      var excel = Excel.createExcel();
      
      // Create our custom sheet FIRST
      var sheet = excel['Students Report'];

      // Enhanced header row
      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Email'),
        TextCellValue('Total XP'),
        TextCellValue('Level'),
        TextCellValue('Badges'),
        TextCellValue('Current Streak'),
        TextCellValue('Longest Streak'),
        TextCellValue('Completed Levels'),
        TextCellValue('Average Score'),
        TextCellValue('Joined Date'),
      ]);

      // Data rows with enhanced information
      for (var student in students) {
        // Handle both 'name' and 'displayName' fields
        final name = student['name'] ?? student['displayName'] ?? 'N/A';
        final email = student['email'] ?? 'N/A';
        final totalXP = (student['totalXP'] ?? 0);
        final badges = student['badges'] is int 
            ? student['badges'] 
            : (student['badges'] as List?)?.length ?? 0;
        final currentStreak = (student['currentStreak'] ?? 0);
        final longestStreak = (student['longestStreak'] ?? 0);
        final completedLevels = student['completedLevels'] ?? 0;
        final avgScore = student['averageScore'] ?? 0;
        
        sheet.appendRow([
          TextCellValue(name),
          TextCellValue(email),
          IntCellValue(totalXP is int ? totalXP : 0),
          IntCellValue(_calculateLevel(totalXP is int ? totalXP : 0)),
          IntCellValue(badges is int ? badges : 0),
          IntCellValue(currentStreak is int ? currentStreak : 0),
          IntCellValue(longestStreak is int ? longestStreak : 0),
          IntCellValue(completedLevels is int ? completedLevels : 0),
          TextCellValue(avgScore is double ? avgScore.toStringAsFixed(1) : avgScore.toString()),
          TextCellValue(_formatTimestamp(student['createdAt'])),
        ]);
      }

      // Delete default sheet AFTER creating our sheet
      excel.delete('Sheet1');

      // Save to bytes using save() method
      var fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to encode Excel file');

      // Use FileDownloadService for user-selected location
      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: Uint8List.fromList(fileBytes),
        suggestedName: 'students_report_$timestamp.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to export Excel: $e');
    }
  }

  /// Export classroom analytics to CSV
  Future<String?> exportClassroomAnalyticsToCSV(
    String classroomName,
    Map<String, dynamic> analytics,
  ) async {
    try {
      List<List<dynamic>> rows = [];

      // Title
      rows.add(['Classroom Analytics Report']);
      rows.add(['Classroom: $classroomName']);
      rows.add(['Generated: ${DateTime.now().toString().split('.')[0]}']);
      rows.add([]); // Empty row

      // Summary section - handle both field name variations
      rows.add(['Summary']);
      rows.add(['Total Students', analytics['studentCount'] ?? analytics['totalStudents'] ?? 0]);
      rows.add(['Average XP', analytics['avgXP'] ?? analytics['averageXP'] ?? 0]);
      rows.add(['Average Streak', analytics['avgStreak'] ?? 0]);
      rows.add(['Total Realms Completed', analytics['totalRealmsCompleted'] ?? 0]);
      rows.add([]); // Empty row

      // Top performers (if available)
      final topPerformers = analytics['topPerformers'] as List? ?? [];
      if (topPerformers.isNotEmpty) {
        rows.add(['Top Performers']);
        rows.add(['Rank', 'Name', 'XP', 'Level', 'Badges']);
        
        for (int i = 0; i < topPerformers.length; i++) {
          final student = topPerformers[i];
          rows.add([
            i + 1,
            student['name'] ?? 'N/A',
            student['totalXP'] ?? 0,
            _calculateLevel(student['totalXP'] ?? 0),
            student['badges'] ?? 0,
          ]);
        }
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Use FileDownloadService for cross-platform support
      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: Uint8List.fromList(csv.codeUnits),
        suggestedName: '${classroomName.replaceAll(' ', '_')}_analytics_$timestamp.csv',
        mimeType: 'text/csv',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to export analytics CSV: $e');
    }
  }

  /// Export classroom analytics to Excel
  Future<String?> exportClassroomAnalyticsToExcel(
    String classroomName,
    Map<String, dynamic> analytics,
  ) async {
    try {
      var excel = Excel.createExcel();
      
      // Create our custom sheet FIRST
      var sheet = excel['Analytics'];

      // Title
      sheet.appendRow([TextCellValue('Classroom Analytics Report')]);
      sheet.appendRow([TextCellValue('Classroom: $classroomName')]);
      sheet.appendRow([TextCellValue('Generated: ${DateTime.now().toString().split('.')[0]}')]);
      sheet.appendRow([]); // Empty row

      // Summary - handle both field name variations
      sheet.appendRow([TextCellValue('Summary')]);
      sheet.appendRow([TextCellValue('Total Students'), IntCellValue(analytics['studentCount'] ?? analytics['totalStudents'] ?? 0)]);
      sheet.appendRow([TextCellValue('Average XP'), IntCellValue(analytics['avgXP'] ?? analytics['averageXP'] ?? 0)]);
      sheet.appendRow([TextCellValue('Average Streak'), IntCellValue(analytics['avgStreak'] ?? 0)]);
      sheet.appendRow([TextCellValue('Total Realms Completed'), IntCellValue(analytics['totalRealmsCompleted'] ?? 0)]);
      sheet.appendRow([]); // Empty row

      // Top performers (if available)
      final topPerformers = analytics['topPerformers'] as List? ?? [];
      if (topPerformers.isNotEmpty) {
        sheet.appendRow([TextCellValue('Top Performers')]);
        sheet.appendRow([TextCellValue('Rank'), TextCellValue('Name'), TextCellValue('XP'), TextCellValue('Level'), TextCellValue('Badges')]);

        for (int i = 0; i < topPerformers.length; i++) {
          final student = topPerformers[i];
          sheet.appendRow([
            IntCellValue(i + 1),
            TextCellValue(student['name'] ?? 'N/A'),
            IntCellValue(student['totalXP'] ?? 0),
            IntCellValue(_calculateLevel(student['totalXP'] ?? 0)),
            IntCellValue(student['badges'] ?? 0),
          ]);
        }
      }

      // Delete default sheet AFTER creating our sheet
      excel.delete('Sheet1');

      // Save to bytes using save() method
      var fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Failed to encode Excel file');

      // Use FileDownloadService for user-selected location
      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: Uint8List.fromList(fileBytes),
        suggestedName: '${classroomName.replaceAll(' ', '_')}_analytics_$timestamp.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to export analytics Excel: $e');
    }
  }

  /// Export school analytics to Excel (all classrooms)
  Future<String?> exportSchoolAnalyticsToExcel(
    String reportName,
    String schoolId,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['School Analytics'];

      // Header row with styling
      sheet.appendRow([
        TextCellValue('Classroom'),
        TextCellValue('Teacher'),
        TextCellValue('Active Students'),
        TextCellValue('Total XP'),
        TextCellValue('Avg XP'),
        TextCellValue('Avg Streak'),
      ]);

      // Get all classrooms in the school
      final classrooms = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      int totalStudents = 0;
      int totalXP = 0;
      int totalStreak = 0;

      for (var classroom in classrooms.docs) {
        final classData = classroom.data();
        final studentIds = List<String>.from(classData['studentIds'] ?? []);

        int classXP = 0;
        int classStreak = 0;
        int activeStudents = 0;

        for (String studentId in studentIds) {
          final user = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (user.exists && user.data()?['isDeleted'] != true) {
            activeStudents++;
            classXP += (user.data()?['totalXP'] ?? 0) as int;
            classStreak += (user.data()?['currentStreak'] ?? 0) as int;
          }
        }

        totalStudents += activeStudents;
        totalXP += classXP;
        totalStreak += classStreak;

        final avgXP = activeStudents > 0
            ? (classXP / activeStudents).toStringAsFixed(1)
            : '0';
        final avgStreak = activeStudents > 0
            ? (classStreak / activeStudents).toStringAsFixed(1)
            : '0';

        sheet.appendRow([
          TextCellValue(classData['name'] ?? 'Unknown'),
          TextCellValue(classData['teacherName'] ?? 'Unknown'),
          IntCellValue(activeStudents),
          IntCellValue(classXP),
          TextCellValue(avgXP),
          TextCellValue(avgStreak),
        ]);
      }

      // Add summary row
      sheet.appendRow([]);
      final overallAvgXP = totalStudents > 0
          ? (totalXP / totalStudents).toStringAsFixed(1)
          : '0';
      final overallAvgStreak = totalStudents > 0
          ? (totalStreak / totalStudents).toStringAsFixed(1)
          : '0';

      sheet.appendRow([
        TextCellValue('TOTAL'),
        TextCellValue(''),
        IntCellValue(totalStudents),
        IntCellValue(totalXP),
        TextCellValue(overallAvgXP),
        TextCellValue(overallAvgStreak),
      ]);

      // Delete default sheet
      excel.delete('Sheet1');

      // Save file
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to encode Excel file');
      }

      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: Uint8List.fromList(fileBytes),
        suggestedName: '${reportName.replaceAll(' ', '_')}_$timestamp.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to export school analytics to Excel: $e');
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: title,
        text: 'IPlay Report - $title',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Helper methods
  int _calculateLevel(int totalXP) {
    return (totalXP / 100).floor() + 1;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
