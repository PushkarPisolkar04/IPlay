import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/loading_skeleton.dart';

class StudentClassroomViewScreen extends StatefulWidget {
  final String classroomId;

  const StudentClassroomViewScreen({
    super.key,
    required this.classroomId,
  });

  @override
  State<StudentClassroomViewScreen> createState() => _StudentClassroomViewScreenState();
}

class _StudentClassroomViewScreenState extends State<StudentClassroomViewScreen> {
  Map<String, dynamic>? _classroomData;
  Map<String, dynamic>? _teacherData;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassroomData();
  }

  Future<void> _loadClassroomData() async {
    try {
      // Load classroom data
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .get();

      if (!classroomDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      _classroomData = classroomDoc.data()!;

      // Load teacher data
      final teacherId = _classroomData!['teacherId'];
      if (teacherId != null) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(teacherId)
            .get();
        if (teacherDoc.exists) {
          _teacherData = teacherDoc.data()!;
        }
      }

      // Load students
      final studentIds = List<String>.from(_classroomData!['studentIds'] ?? []);
      for (final studentId in studentIds) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        if (studentDoc.exists) {
          _students.add({
            'id': studentId,
            ...studentDoc.data()!,
          });
        }
      }

      // Sort students by name
      _students.sort((a, b) => 
        (a['displayName'] ?? '').compareTo(b['displayName'] ?? ''));

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom gradient app bar
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
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
                          'My Classroom',
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
            ),

            // Body content
            Expanded(
              child: _isLoading
                  ? const ListSkeleton(itemCount: 5)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Classroom Info Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppDesignSystem.gradientPrimary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _classroomData!['name'] ?? 'Classroom',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Grade ${_classroomData!['grade'] ?? '-'} • ${_classroomData!['section'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                if (_classroomData!['classCode'] != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.key,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Code: ${_classroomData!['classCode']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_classroomData!['description'] != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _classroomData!['description'],
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Created: ${_formatDate(_classroomData!['createdAt'])}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Teacher Section
                          if (_teacherData != null) ...[
                            const Text(
                              'Teacher',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                  backgroundImage: _teacherData!['avatarUrl'] != null
                                      ? (_teacherData!['avatarUrl'].toString().startsWith('http')
                                          ? NetworkImage(_teacherData!['avatarUrl'])
                                          : AssetImage(_teacherData!['avatarUrl']) as ImageProvider)
                                      : null,
                                  child: _teacherData!['avatarUrl'] == null
                                      ? Text(
                                          _teacherData!['displayName'][0].toUpperCase(),
                                          style: TextStyle(
                                            color: AppDesignSystem.primaryIndigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  _teacherData!['displayName'] ?? 'Teacher',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  _teacherData!['email'] ?? '',
                                  style: TextStyle(
                                    color: AppDesignSystem.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Students Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Classmates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_students.length} students',
                                  style: TextStyle(
                                    color: AppDesignSystem.primaryIndigo,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Students List
                          if (_students.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No other students yet',
                                  style: TextStyle(
                                    color: AppDesignSystem.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _students.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return Container(
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
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                      backgroundImage: student['avatarUrl'] != null
                                          ? (student['avatarUrl'].toString().startsWith('http')
                                              ? NetworkImage(student['avatarUrl'])
                                              : AssetImage(student['avatarUrl']) as ImageProvider)
                                          : null,
                                      child: student['avatarUrl'] == null
                                          ? Text(
                                              student['displayName'][0].toUpperCase(),
                                              style: TextStyle(
                                                color: AppDesignSystem.primaryIndigo,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      student['displayName'] ?? 'Student',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: student['totalXP'] != null
                                        ? Row(
                                            children: [
                                              Icon(
                                                Icons.stars,
                                                size: 14,
                                                color: AppDesignSystem.primaryAmber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${student['totalXP']} XP',
                                                style: TextStyle(
                                                  color: AppDesignSystem.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
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
}
