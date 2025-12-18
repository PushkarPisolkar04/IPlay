import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../../widgets/clean_card.dart';
import '../../core/services/report_service.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/export_format_dialog.dart';
import '../../core/services/export_service.dart';
import '../../core/services/error_handler_service.dart';
import '../../widgets/error_dialog.dart';
import '../../core/services/file_download_service.dart';

class PrincipalGenerateReportScreen extends StatefulWidget {
  final String schoolId;

  const PrincipalGenerateReportScreen({super.key, required this.schoolId});

  @override
  State<PrincipalGenerateReportScreen> createState() =>
      _PrincipalGenerateReportScreenState();
}

class _PrincipalGenerateReportScreenState
    extends State<PrincipalGenerateReportScreen> {
  final List<Map<String, dynamic>> _classrooms = [];
  final List<Map<String, dynamic>> _students = [];
  String? _selectedClassroomId;
  String? _selectedStudentId;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _reportType =
      'school'; // 'school', 'classroom', 'student', 'comparison'
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get all classrooms in the school
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();

      _classrooms.clear();
      Set<String> allStudentIds = {};

      for (var doc in classroomsSnapshot.docs) {
        final classData = doc.data();
        _classrooms.add({
          'id': doc.id,
          'name': classData['name'] ?? 'Unknown',
          'teacherName': classData['teacherName'] ?? 'Unknown',
          'studentCount': (classData['studentIds'] as List?)?.length ?? 0,
        });

        final studentIds = List<String>.from(classData['studentIds'] ?? []);
        allStudentIds.addAll(studentIds);
      }

      _classrooms.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      // Get all students (excluding deleted ones)
      _students.clear();
      for (String studentId in allStudentIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          // Skip deleted students
          final isDeleted = userData['isDeleted'] == true;
          if (!isDeleted) {
            _students.add({
              'id': studentId,
              'name': userData['displayName'] ?? 'Unknown',
              'email': userData['email'] ?? '',
            });
          }
        }
      }

      _students.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      // print('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    if (_reportType == 'student' && _selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }

    if (_reportType == 'classroom' && _selectedClassroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classroom')),
      );
      return;
    }

    // Validate classroom has students
    if (_reportType == 'classroom') {
      final classroom = _classrooms.firstWhere(
        (c) => c['id'] == _selectedClassroomId,
      );
      if (classroom['studentCount'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This classroom has no active students. Cannot generate report.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // Validate school has classrooms for school and comparison reports
    if (_reportType == 'school' || _reportType == 'comparison') {
      if (_classrooms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No classrooms found. Cannot generate report.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // Show ExportFormatDialog for all report types
    if (_reportType == 'school') {
      _showExportFormatDialog('school', {'schoolId': widget.schoolId});
    } else if (_reportType == 'student') {
      final student = _students.firstWhere((s) => s['id'] == _selectedStudentId);
      _showExportFormatDialog('student', student);
    } else if (_reportType == 'classroom') {
      final classroom = _classrooms.firstWhere((c) => c['id'] == _selectedClassroomId);
      _showExportFormatDialog('classroom', classroom);
    } else if (_reportType == 'comparison') {
      _showExportFormatDialog('comparison', {'schoolId': widget.schoolId});
    }
  }









  /// Show export format selection dialog
  void _showExportFormatDialog(String reportType, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => ExportFormatDialog(
        title: 'Export ${reportType.replaceAll('_', ' ').toUpperCase()} Report',
        onPdfExport: () => _exportPDF(reportType, data),
        onCsvExport: () => _exportCSV(reportType, data),
        onExcelExport: () => _exportExcel(reportType, data),
      ),
    );
  }

  /// Export to PDF
  Future<void> _exportPDF(String reportType, Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final reportService = ReportService();
      Uint8List pdfBytes;
      
      // Generate PDF based on report type
      if (reportType == 'school') {
        // For school report, use classroom report with aggregated data
        pdfBytes = await reportService.generateClassroomReport(widget.schoolId);
      } else if (reportType == 'classroom') {
        pdfBytes = await reportService.generateClassroomReport(data['id'] ?? '');
      } else if (reportType == 'student') {
        pdfBytes = await reportService.generateStudentReport(data['id'] ?? '');
      } else {
        throw Exception('Unknown report type: $reportType');
      }

      final fileDownloadService = FileDownloadService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await fileDownloadService.saveFile(
        bytes: pdfBytes,
        suggestedName: '${reportType}_report_$timestamp.pdf',
        mimeType: 'application/pdf',
      );

      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: $savedPath'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: ErrorHandlerService.handleError(e));
      }
    }
  }

  /// Export to CSV
  Future<void> _exportCSV(String reportType, Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating CSV...')),
      );

      final exportService = ExportService();
      String? savedPath;

      if (reportType == 'school') {
        savedPath = await exportService.exportClassroomAnalyticsToCSV(
          'School Report',
          data,
        );
      } else if (reportType == 'classroom') {
        savedPath = await exportService.exportClassroomAnalyticsToCSV(
          data['name'] ?? 'Classroom',
          data,
        );
      } else if (reportType == 'student') {
        savedPath = await exportService.exportStudentsToCSV([data]);
      }

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV saved to: $savedPath'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export cancelled or failed'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// Export to Excel
  Future<void> _exportExcel(String reportType, Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating Excel...')),
      );

      final exportService = ExportService();
      String? savedPath;

      if (reportType == 'school') {
        savedPath = await exportService.exportClassroomAnalyticsToExcel(
          'School Report',
          data,
        );
      } else if (reportType == 'classroom') {
        savedPath = await exportService.exportClassroomAnalyticsToExcel(
          data['name'] ?? 'Classroom',
          data,
        );
      } else if (reportType == 'student') {
        savedPath = await exportService.exportStudentsToExcel([data]);
      }

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel saved to: $savedPath'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export cancelled or failed'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
                  colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Generate Reports',
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
                            'Generate school-wide reports and analytics',
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
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          LoadingSkeleton(
                            height: 60,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          SizedBox(height: 16),
                          LoadingSkeleton(
                            height: 200,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          SizedBox(height: 16),
                          LoadingSkeleton(
                            height: 60,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
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

                          // Report type buttons in a grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _buildReportTypeButton(
                                'School Report',
                                'school',
                                Icons.school,
                                'School-wide analytics',
                              ),
                              _buildReportTypeButton(
                                'Classroom Report',
                                'classroom',
                                Icons.class_,
                                'Individual classroom',
                              ),
                              _buildReportTypeButton(
                                'Student Report',
                                'student',
                                Icons.person,
                                'Individual student',
                              ),
                              _buildReportTypeButton(
                                'Comparison',
                                'comparison',
                                Icons.compare,
                                'Compare classrooms',
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Selection area based on report type
                          if (_reportType == 'classroom' ||
                              _reportType == 'student') ...[
                            Text(
                              _reportType == 'classroom'
                                  ? 'Select Classroom'
                                  : 'Select Student',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_reportType == 'classroom')
                              ..._buildClassroomList()
                            else
                              ..._buildStudentList(),

                            const SizedBox(height: 24),
                          ],

                          // Generate Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9333EA,
                                  ).withValues(alpha: 0.4),
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
                                _isGenerating
                                    ? 'Generating...'
                                    : 'Generate Report',
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

  Widget _buildReportTypeButton(
    String label,
    String type,
    IconData icon,
    String subtitle,
  ) {
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                    color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: 32,
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
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
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
              ? const Color(0xFF9333EA).withValues(alpha: 0.1)
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
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.class_, color: Colors.white, size: 28),
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
                        '${classroom['studentCount']} students • ${classroom['teacherName']}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF9333EA),
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
              ? const Color(0xFF9333EA).withValues(alpha: 0.1)
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
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.3),
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF9333EA),
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
}
