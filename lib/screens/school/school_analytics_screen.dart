import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../core/models/school_model.dart';

/// School Analytics Screen - View all classrooms, teachers, top students across school
class SchoolAnalyticsScreen extends StatefulWidget {
  final SchoolModel school;

  const SchoolAnalyticsScreen({
    Key? key,
    required this.school,
  }) : super(key: key);

  @override
  State<SchoolAnalyticsScreen> createState() => _SchoolAnalyticsScreenState();
}

class _SchoolAnalyticsScreenState extends State<SchoolAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _topStudents = [];
  List<Map<String, dynamic>> _classrooms = [];
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch all classrooms
      final classroomDocs = await Future.wait(
        widget.school.classroomIds.map((id) =>
          FirebaseFirestore.instance.collection('classrooms').doc(id).get()
        ),
      );

      final classroomData = classroomDocs
          .where((doc) => doc.exists)
          .map((doc) {
            final data = doc.data()!;
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'grade': data['grade'] ?? 'N/A',
              'studentCount': (data['studentIds'] as List?)?.length ?? 0,
              'teacherName': data['teacherName'] ?? 'Unknown',
            };
          })
          .toList();

      // Fetch all teachers
      final teacherDocs = await Future.wait(
        widget.school.teacherIds.map((id) =>
          FirebaseFirestore.instance.collection('users').doc(id).get()
        ),
      );

      final teacherData = teacherDocs
          .where((doc) => doc.exists)
          .map((doc) {
            final data = doc.data()!;
            final teacherClassrooms = classroomData
                .where((c) => widget.school.classroomIds.contains(c['id']))
                .length;
            return {
              'userId': doc.id,
              'displayName': data['displayName'] ?? 'Unknown',
              'email': data['email'] ?? '',
              'avatarUrl': data['avatarUrl'],
              'classroomCount': teacherClassrooms,
            };
          })
          .toList();

      // Fetch all students from all classrooms
      final allStudentIds = <String>{};
      for (final classroom in classroomDocs) {
        if (classroom.exists) {
          final studentIds = List<String>.from(classroom.data()!['studentIds'] ?? []);
          allStudentIds.addAll(studentIds);
        }
      }

      final studentDocs = await Future.wait(
        allStudentIds.map((id) =>
          FirebaseFirestore.instance.collection('users').doc(id).get()
        ),
      );

      final studentData = studentDocs
          .where((doc) => doc.exists)
          .map((doc) {
            final data = doc.data()!;
            return {
              'userId': doc.id,
              'displayName': data['displayName'] ?? 'Unknown',
              'avatarUrl': data['avatarUrl'],
              'totalXP': data['totalXP'] ?? 0,
              'currentStreak': data['currentStreak'] ?? 0,
              'badges': List<String>.from(data['badges'] ?? []),
            };
          })
          .toList();

      // Sort students by XP for top performers
      studentData.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
      final topStudents = studentData.take(10).toList();

      // Calculate analytics
      final totalStudents = studentData.length;
      final totalXP = studentData.fold<int>(0, (sum, student) => sum + (student['totalXP'] as int));
      final avgXP = totalStudents == 0 ? 0 : totalXP ~/ totalStudents;
      final totalBadges = studentData.fold<int>(0, (sum, student) => sum + (student['badges'] as List).length);
      final avgBadges = totalStudents == 0 ? 0.0 : totalBadges / totalStudents;

      setState(() {
        _analytics = {
          'totalClassrooms': classroomData.length,
          'totalTeachers': teacherData.length,
          'totalStudents': totalStudents,
          'averageXP': avgXP,
          'averageBadges': avgBadges,
          'totalXP': totalXP,
        };
        _topStudents = topStudents;
        _classrooms = classroomData;
        _teachers = teacherData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading school analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.school.name} Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Classrooms',
                            '${_analytics['totalClassrooms']}',
                            Icons.class_,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Teachers',
                            '${_analytics['totalTeachers']}',
                            Icons.school,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Students',
                            '${_analytics['totalStudents']}',
                            Icons.people,
                            AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Avg XP',
                            '${_analytics['averageXP']}',
                            Icons.star,
                            AppColors.error,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Top Students
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top Students', style: AppTextStyles.h3),
                        Text(
                          'Top 10',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_topStudents.isEmpty)
                      CleanCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Students Yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._topStudents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTopStudentCard(student, index + 1),
                        );
                      }).toList(),

                    const SizedBox(height: 24),

                    // Classrooms
                    Text('Classrooms', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    if (_classrooms.isEmpty)
                      CleanCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.class_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Classrooms Yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._classrooms.map((classroom) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildClassroomCard(classroom),
                        );
                      }).toList(),

                    const SizedBox(height: 24),

                    // Teachers
                    Text('Teachers', style: AppTextStyles.h3),
                    const SizedBox(height: 12),

                    if (_teachers.isEmpty)
                      CleanCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Teachers Yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._teachers.map((teacher) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTeacherCard(teacher),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return CleanCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopStudentCard(Map<String, dynamic> student, int rank) {
    final totalXP = student['totalXP'] as int;
    final badgeCount = (student['badges'] as List).length;
    final currentStreak = student['currentStreak'] as int;

    // Medal for top 3
    Color rankColor = AppColors.textSecondary;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    return CleanCard(
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: student['avatarUrl'] != null
                ? NetworkImage(student['avatarUrl'])
                : null,
            child: student['avatarUrl'] == null
                ? Text(
                    (student['displayName'] as String).substring(0, 1).toUpperCase(),
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['displayName'],
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('$totalXP XP', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('$currentStreak', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.emoji_events, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('$badgeCount', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom) {
    return CleanCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom['name'],
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade ${classroom['grade']} • ${classroom['studentCount']} students',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Teacher: ${classroom['teacherName']}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    return CleanCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.success.withOpacity(0.2),
            backgroundImage: teacher['avatarUrl'] != null
                ? NetworkImage(teacher['avatarUrl'])
                : null,
            child: teacher['avatarUrl'] == null
                ? Text(
                    (teacher['displayName'] as String).substring(0, 1).toUpperCase(),
                    style: AppTextStyles.h3.copyWith(color: AppColors.success),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher['displayName'],
                  style: AppTextStyles.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  teacher['email'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${teacher['classroomCount']} classrooms',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

