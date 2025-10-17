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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
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
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Quiz Performance',
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
                        Icon(Icons.analytics, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Track student quiz performance across all realms',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Realms Performance List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
                  : RefreshIndicator(
                      onRefresh: _loadPerformanceData,
                      color: const Color(0xFFEC4899),
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
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Realm Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            perf['icon'],
                                            style: const TextStyle(fontSize: 26),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                perf['name'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                hasData 
                                                    ? '${perf['totalQuizzes']} quizzes completed'
                                                    : 'No quizzes taken yet',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: hasData ? const Color(0xFF10B981) : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
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
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
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
    IconData icon;
    
    if (avgScore >= 90) {
      grade = 'Excellent';
      color = const Color(0xFF10B981);
      message = 'Outstanding performance!';
      icon = Icons.emoji_events;
    } else if (avgScore >= 75) {
      grade = 'Good';
      color = const Color(0xFF3B82F6);
      message = 'Good progress!';
      icon = Icons.thumb_up;
    } else if (avgScore >= 60) {
      grade = 'Fair';
      color = const Color(0xFFF59E0B);
      message = 'Room for improvement';
      icon = Icons.trending_up;
    } else {
      grade = 'Needs Improvement';
      color = const Color(0xFFEF4444);
      message = 'Extra support needed';
      icon = Icons.priority_high;
    }
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
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

