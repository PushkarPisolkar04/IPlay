import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import 'teacher_leaderboard_screen.dart';
import 'teacher_announcements_screen.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final ClassroomModel classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

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
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    classroom.name,
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
                            'Grade ${classroom.grade}${classroom.school != null ? ' • ${classroom.school}' : ''}',
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
                                classroom.classCode,
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
                                    ClipboardData(text: classroom.classCode),
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
                                  builder: (context) => TeacherAnnouncementsScreen(classroomId: classroom.id),
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
                                  builder: (context) => TeacherLeaderboardScreen(classroomId: classroom.id),
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
                            value: '${classroom.studentIds.length}',
                            label: AppStrings.students,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending,
                            value: '${classroom.pendingStudentIds.length}',
                            label: 'Pending',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pending Approvals
                    if (classroom.pendingStudentIds.isNotEmpty) ...[
                      const Text(
                        AppStrings.pendingApprovals,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...classroom.pendingStudentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: classroom.id,
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

                    if (classroom.studentIds.isEmpty)
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
                      ...classroom.studentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: classroom.id,
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

