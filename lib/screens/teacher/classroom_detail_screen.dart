import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import 'teacher_leaderboard_screen.dart';
import 'teacher_announcements_screen.dart';
import '../classroom/join_requests_screen.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomModel classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  
  Future<void> _editClassroom() async {
    // TODO: Navigate to edit classroom screen or show edit dialog
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditClassroomDialog(
        currentName: widget.classroom.name,
        currentGrade: widget.classroom.grade.toString(),
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(widget.classroom.id)
            .update({
          'name': result['name'],
          'grade': result['grade'],
          'updatedAt': Timestamp.now(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context); // Go back to refresh
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteClassroom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Classroom'),
        content: Text('Are you sure you want to delete "${widget.classroom.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Remove classroom from all students
      for (String studentId in widget.classroom.studentIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .update({
          'classroomIds': FieldValue.arrayRemove([widget.classroom.id]),
          'updatedAt': Timestamp.now(),
        });
      }

      // Delete the classroom
      await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroom.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Classroom deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context); // Go back
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _editClassroom,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteClassroom();
                      } else if (value == 'requests') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JoinRequestsScreen(classroomId: widget.classroom.id),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'requests',
                        child: Row(
                          children: [
                            Icon(Icons.pending_actions, size: 20),
                            SizedBox(width: 12),
                            Text('Manage Join Requests'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Delete Classroom', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.classroom.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grade ${widget.classroom.grade}${widget.classroom.school != null ? ' • ${widget.classroom.school}' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Class Code Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.classCode,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                widget.classroom.joinCode,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.classroom.joinCode),
                                );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(AppStrings.codeCopied),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Share this code with students to join your classroom',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: CleanCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherAnnouncementsScreen(classroomId: widget.classroom.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.campaign, color: Color(0xFF10B981), size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Announcements',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CleanCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherLeaderboardScreen(classroomId: widget.classroom.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.leaderboard, color: Color(0xFFF59E0B), size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Leaderboard',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people,
                            value: '${widget.classroom.studentIds.length}',
                            label: AppStrings.students,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending,
                            value: '${widget.classroom.pendingStudentIds.length}',
                            label: 'Pending',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pending Approvals
                    if (widget.classroom.pendingStudentIds.isNotEmpty) ...[
                      const Text(
                        AppStrings.pendingApprovals,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.classroom.pendingStudentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: widget.classroom.id,
                            isPending: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Students List
                    const Text(
                      AppStrings.students,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (widget.classroom.studentIds.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 60,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No students yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...widget.classroom.studentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: widget.classroom.id,
                            isPending: false,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String studentId;
  final String classroomId;
  final bool isPending;

  const _StudentCard({
    required this.studentId,
    required this.classroomId,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isPending
            ? Border.all(color: AppColors.warning, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student $studentId', // Replace with actual student name from Firestore
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending ? 'Waiting for approval' : 'Active',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPending ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Approve student
                  },
                  icon: const Icon(Icons.check_circle),
                  color: AppColors.success,
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Reject student
                  },
                  icon: const Icon(Icons.cancel),
                  color: AppColors.error,
                ),
              ],
            )
          else
            IconButton(
              onPressed: () {
                // TODO: View student details
              },
              icon: const Icon(Icons.arrow_forward_ios),
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

// Edit Classroom Dialog
class _EditClassroomDialog extends StatefulWidget {
  final String currentName;
  final String currentGrade;

  const _EditClassroomDialog({
    required this.currentName,
    required this.currentGrade,
  });

  @override
  State<_EditClassroomDialog> createState() => _EditClassroomDialogState();
}

class _EditClassroomDialogState extends State<_EditClassroomDialog> {
  late TextEditingController _nameController;
  late TextEditingController _gradeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _gradeController = TextEditingController(text: widget.currentGrade);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Classroom'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Classroom Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a classroom name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a grade';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'grade': _gradeController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

