import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../models/classroom_model.dart';

/// Classroom Analytics Screen - View student progress, average XP, engagement metrics
class ClassroomAnalyticsScreen extends StatefulWidget {
  final ClassroomModel classroom;

  const ClassroomAnalyticsScreen({
    super.key,
    required this.classroom,
  });

  @override
  State<ClassroomAnalyticsScreen> createState() => _ClassroomAnalyticsScreenState();
}

class _ClassroomAnalyticsScreenState extends State<ClassroomAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _studentProgress = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final studentIds = widget.classroom.studentIds;
      if (studentIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all student data
      final studentDocs = await Future.wait(
        studentIds.map((id) => 
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
              'lastActiveDate': data['lastActiveDate'],
            };
          })
          .toList();

      // Calculate analytics
      final totalXP = studentData.fold<int>(0, (sum, student) => sum + (student['totalXP'] as int));
      final avgXP = studentData.isEmpty ? 0 : totalXP ~/ studentData.length;
      
      final activeStudents = studentData.where((student) {
        final lastActive = student['lastActiveDate'] as Timestamp?;
        if (lastActive == null) return false;
        final daysSince = DateTime.now().difference(lastActive.toDate()).inDays;
        return daysSince <= 7;
      }).length;

      final totalBadges = studentData.fold<int>(0, (sum, student) => sum + (student['badges'] as List).length);
      final avgBadges = studentData.isEmpty ? 0.0 : totalBadges / studentData.length;

      // Sort by totalXP for leaderboard
      studentData.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));

      setState(() {
        _analytics = {
          'totalStudents': studentData.length,
          'activeStudents': activeStudents,
          'totalXP': totalXP,
          'averageXP': avgXP,
          'averageBadges': avgBadges,
        };
        _studentProgress = studentData;
        _isLoading = false;
      });
    } catch (e) {
      // print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('${widget.classroom.name} Analytics'),
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
                            'Total Students',
                            '${_analytics['totalStudents']}',
                            Icons.people,
                            AppDesignSystem.primaryIndigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Active (7d)',
                            '${_analytics['activeStudents']}',
                            Icons.online_prediction,
                            AppDesignSystem.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Avg XP',
                            '${_analytics['averageXP']}',
                            Icons.star,
                            AppDesignSystem.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Avg Badges',
                            (_analytics['averageBadges'] as double).toStringAsFixed(1),
                            Icons.emoji_events,
                            AppDesignSystem.error,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Student Progress List
                    Text(
                      'Student Progress',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 12),

                    if (_studentProgress.isEmpty)
                      CleanCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppDesignSystem.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Students Yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppDesignSystem.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._studentProgress.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildStudentCard(student, index + 1),
                        );
                      }),
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
              color: AppDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int rank) {
    final totalXP = student['totalXP'] as int;
    final currentStreak = student['currentStreak'] as int;
    final badgeCount = (student['badges'] as List).length;
    final lastActive = student['lastActiveDate'] as Timestamp?;
    
    String lastActiveText = 'Never';
    if (lastActive != null) {
      final days = DateTime.now().difference(lastActive.toDate()).inDays;
      if (days == 0) {
        lastActiveText = 'Today';
      } else if (days == 1) {
        lastActiveText = '1 day ago';
      } else if (days < 7) {
        lastActiveText = '$days days ago';
      } else {
        lastActiveText = '7+ days ago';
      }
    }

    return CleanCard(
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppDesignSystem.warning.withValues(alpha: 0.2) : AppDesignSystem.backgroundGrey,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppDesignSystem.warning : AppDesignSystem.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
            backgroundImage: student['avatarUrl'] != null
                ? NetworkImage(student['avatarUrl'])
                : null,
            child: student['avatarUrl'] == null
                ? Text(
                    (student['displayName'] as String).substring(0, 1).toUpperCase(),
                    style: AppTextStyles.h3.copyWith(color: AppDesignSystem.primaryIndigo),
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
                    const Icon(Icons.star, size: 14, color: AppDesignSystem.warning),
                    const SizedBox(width: 4),
                    Text('$totalXP XP', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, size: 14, color: AppDesignSystem.error),
                    const SizedBox(width: 4),
                    Text('$currentStreak', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.emoji_events, size: 14, color: AppDesignSystem.primaryIndigo),
                    const SizedBox(width: 4),
                    Text('$badgeCount', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Last active: $lastActiveText',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
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

