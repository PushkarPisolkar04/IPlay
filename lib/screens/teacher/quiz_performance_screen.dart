import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../core/models/realm_model.dart';

class QuizPerformanceScreen extends StatefulWidget {
  const QuizPerformanceScreen({Key? key}) : super(key: key);

  @override
  State<QuizPerformanceScreen> createState() => _QuizPerformanceScreenState();
}

class _QuizPerformanceScreenState extends State<QuizPerformanceScreen> {
  Map<String, Map<String, dynamic>> _realmPerformance = {};
  bool _isLoading = true;
  List<String> _studentIds = [];

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all students from teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      Set<String> allStudentIds = {};
      for (var doc in classroomsSnapshot.docs) {
        final studentIds = List<String>.from(doc.data()['studentIds'] ?? []);
        allStudentIds.addAll(studentIds);
      }

      _studentIds = allStudentIds.toList();

      // Initialize performance data for each realm (hardcoded for now)
      final realmIds = ['realm_1', 'realm_2', 'realm_3', 'realm_4', 'realm_5', 'realm_6'];
      final realmNames = ['Copyright', 'Trademark', 'Patent', 'Industrial Design', 'GI', 'Trade Secrets'];
      final realmIcons = ['©️', '™️', '🔬', '🎨', '🌍', '🔒'];
      
      for (int i = 0; i < realmIds.length; i++) {
        _realmPerformance[realmIds[i]] = {
          'name': realmNames[i],
          'icon': realmIcons[i],
          'totalStudents': 0,
          'completedStudents': 0,
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'highestScore': 0,
          'lowestScore': 100,
          'totalXP': 0,
        };
      }

      // Fetch progress data for all students
      for (String studentId in _studentIds) {
        final progressSnapshot = await FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: studentId)
            .where('status', isEqualTo: 'completed')
            .get();

        for (var progressDoc in progressSnapshot.docs) {
          final data = progressDoc.data();
          final contentId = data['contentId'] as String?;
          
          if (contentId == null) continue;

          // Extract realm ID from contentId (e.g., "copyright_level_1" -> "copyright")
          final realmId = contentId.split('_level_')[0];
          
          if (_realmPerformance.containsKey(realmId)) {
            final accuracy = data['accuracy'] as int? ?? 0;
            final xpEarned = data['xpEarned'] as int? ?? 0;

            _realmPerformance[realmId]!['totalQuizzes']++;
            _realmPerformance[realmId]!['averageScore'] += accuracy;
            _realmPerformance[realmId]!['totalXP'] += xpEarned;
            
            if (accuracy > _realmPerformance[realmId]!['highestScore']) {
              _realmPerformance[realmId]!['highestScore'] = accuracy;
            }
            if (accuracy < _realmPerformance[realmId]!['lowestScore']) {
              _realmPerformance[realmId]!['lowestScore'] = accuracy;
            }
          }
        }
      }

      // Calculate averages
      _realmPerformance.forEach((key, value) {
        if (value['totalQuizzes'] > 0) {
          value['averageScore'] = value['averageScore'] / value['totalQuizzes'];
        }
        // Reset lowest score if no quizzes
        if (value['totalQuizzes'] == 0) {
          value['lowestScore'] = 0;
        }
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading performance data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quiz & Module Performance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Performance across all realms',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Realms Performance List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPerformanceData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _realmPerformance.length,
                      itemBuilder: (context, index) {
                        final realmId = _realmPerformance.keys.elementAt(index);
                        final perf = _realmPerformance[realmId]!;
                        final hasData = perf['totalQuizzes'] > 0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CleanCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Realm Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        perf['icon'],
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            perf['name'],
                                            style: AppTextStyles.h3,
                                          ),
                                          Text(
                                            hasData 
                                                ? '${perf['totalQuizzes']} quizzes completed'
                                                : 'No quizzes taken yet',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: hasData ? AppColors.success : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (hasData) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  
                                  // Performance Stats
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatBox(
                                          'Average',
                                          '${perf['averageScore'].toStringAsFixed(0)}%',
                                          Icons.trending_up,
                                          AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatBox(
                                          'Highest',
                                          '${perf['highestScore']}%',
                                          Icons.star,
                                          AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatBox(
                                          'Lowest',
                                          '${perf['lowestScore']}%',
                                          Icons.warning,
                                          AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatBox(
                                          'Total XP',
                                          '${perf['totalXP']}',
                                          Icons.emoji_events,
                                          AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Performance Grade
                                  _buildPerformanceGrade(perf['averageScore']),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrade(double avgScore) {
    String grade;
    Color color;
    String message;
    
    if (avgScore >= 90) {
      grade = 'Excellent';
      color = AppColors.success;
      message = 'Outstanding performance!';
    } else if (avgScore >= 75) {
      grade = 'Good';
      color = AppColors.primary;
      message = 'Good progress!';
    } else if (avgScore >= 60) {
      grade = 'Fair';
      color = AppColors.warning;
      message = 'Room for improvement';
    } else {
      grade = 'Needs Improvement';
      color = AppColors.error;
      message = 'Extra support needed';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

