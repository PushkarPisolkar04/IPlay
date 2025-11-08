import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

/// Learning Insights Screen - Detailed analytics for students
/// Requirement 43: Analytics and Insights
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final ContentService _contentService = ContentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic> _insightsData = {};
  Map<String, dynamic>? _classroomAverages;
  String? _classroomId;
  
  @override
  void initState() {
    super.initState();
    _loadInsights();
  }
  
  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      // Load user data to get classroom
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final classroomIds = userData?['classroomIds'] as List?;
      if (classroomIds != null && classroomIds.isNotEmpty) {
        _classroomId = classroomIds.first;
      }
      
      // Load progress data
      final progressSnapshot = await _firestore
          .collection('progress')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Calculate insights
      _insightsData = _calculateInsights(progressSnapshot.docs, userData);
      
      // Load classroom averages if in a classroom
      if (_classroomId != null) {
        _classroomAverages = await _loadClassroomAverages(_classroomId!);
      }
      
    } catch (e) {
      // print('Error loading insights: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Map<String, dynamic> _calculateInsights(
    List<QueryDocumentSnapshot> progressDocs,
    Map<String, dynamic>? userData,
  ) {
    final realms = _contentService.getAllRealms();
    Map<String, int> timeSpentPerRealm = {};
    Map<String, double> accuracyPerRealm = {};
    Map<String, int> xpPerRealm = {};
    List<Map<String, dynamic>> xpHistory = [];
    int totalQuestions = 0;
    int correctAnswers = 0;
    
    // Initialize realm data
    for (var realm in realms) {
      timeSpentPerRealm[realm.id] = 0;
      accuracyPerRealm[realm.id] = 0.0;
      xpPerRealm[realm.id] = 0;
    }
    
    // Process progress documents
    for (var doc in progressDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final contentId = data['contentId'] as String? ?? '';
      final xpEarned = data['xpEarned'] as int? ?? 0;
      final accuracy = data['accuracy'] as int? ?? 0;
      final timeSpent = data['timeSpentSeconds'] as int? ?? 0;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      
      // Extract realm ID from content ID (format: realmId_level_X)
      final realmId = contentId.split('_').first;
      
      if (timeSpentPerRealm.containsKey(realmId)) {
        timeSpentPerRealm[realmId] = (timeSpentPerRealm[realmId] ?? 0) + timeSpent;
        xpPerRealm[realmId] = (xpPerRealm[realmId] ?? 0) + xpEarned;
        
        // Track accuracy
        if (accuracy > 0) {
          final currentAccuracy = accuracyPerRealm[realmId] ?? 0.0;
          final count = progressDocs.where((d) {
            final cId = (d.data() as Map)['contentId'] as String? ?? '';
            return cId.startsWith(realmId);
          }).length;
          accuracyPerRealm[realmId] = ((currentAccuracy * (count - 1)) + accuracy) / count;
        }
      }
      
      // Track XP history for chart
      if (completedAt != null) {
        xpHistory.add({
          'date': completedAt,
          'xp': xpEarned,
          'realmId': realmId,
        });
      }
      
      // Calculate overall accuracy
      if (accuracy > 0) {
        totalQuestions += 100; // Assuming 100% scale
        correctAnswers += accuracy;
      }
    }
    
    // Sort XP history by date
    xpHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Calculate cumulative XP for chart
    int cumulativeXP = 0;
    List<Map<String, dynamic>> xpChartData = [];
    for (var entry in xpHistory) {
      cumulativeXP += entry['xp'] as int;
      xpChartData.add({
        'date': entry['date'],
        'cumulativeXP': cumulativeXP,
      });
    }
    
    // Get favorite games (placeholder - would need game tracking)
    List<Map<String, String>> favoriteGames = [
      {'name': 'Quiz Master', 'plays': '0'},
      {'name': 'Spot the Original', 'plays': '0'},
      {'name': 'GI Mapper', 'plays': '0'},
    ];
    
    // Calculate overall accuracy
    double overallAccuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;
    
    // Identify strengths and focus areas
    List<String> strengths = [];
    List<String> focusAreas = [];
    
    accuracyPerRealm.forEach((realmId, accuracy) {
      final realm = realms.firstWhere((r) => r.id == realmId, orElse: () => realms.first);
      if (accuracy >= 80) {
        strengths.add(realm.name);
      } else if (accuracy > 0 && accuracy < 60) {
        focusAreas.add(realm.name);
      }
    });
    
    return {
      'timeSpentPerRealm': timeSpentPerRealm,
      'accuracyPerRealm': accuracyPerRealm,
      'xpPerRealm': xpPerRealm,
      'xpChartData': xpChartData,
      'favoriteGames': favoriteGames,
      'overallAccuracy': overallAccuracy,
      'strengths': strengths,
      'focusAreas': focusAreas,
      'totalXP': userData?['totalXP'] ?? 0,
    };
  }
  
  Future<Map<String, dynamic>> _loadClassroomAverages(String classroomId) async {
    try {
      // Get all students in classroom
      final classroomDoc = await _firestore.collection('classrooms').doc(classroomId).get();
      final studentIds = List<String>.from(classroomDoc.data()?['studentIds'] ?? []);
      
      if (studentIds.isEmpty) return {};
      
      // Calculate averages
      int totalXP = 0;
      double totalAccuracy = 0.0;
      int studentCount = 0;
      
      for (var studentId in studentIds) {
        final userDoc = await _firestore.collection('users').doc(studentId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          totalXP += userData['totalXP'] as int? ?? 0;
          studentCount++;
        }
        
        // Get student's progress for accuracy
        final progressDocs = await _firestore
            .collection('progress')
            .where('userId', isEqualTo: studentId)
            .get();
        
        int studentQuestions = 0;
        int studentCorrect = 0;
        for (var doc in progressDocs.docs) {
          final accuracy = doc.data()['accuracy'] as int? ?? 0;
          if (accuracy > 0) {
            studentQuestions += 100;
            studentCorrect += accuracy;
          }
        }
        
        if (studentQuestions > 0) {
          totalAccuracy += (studentCorrect / studentQuestions * 100);
        }
      }
      
      return {
        'averageXP': studentCount > 0 ? (totalXP / studentCount).round() : 0,
        'averageAccuracy': studentCount > 0 ? (totalAccuracy / studentCount) : 0.0,
      };
    } catch (e) {
      // print('Error loading classroom averages: $e');
      return {};
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Learning Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                      SizedBox(width: 12),
                      Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                      SizedBox(width: 12),
                      Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                    ],
                  ),
                  SizedBox(height: 16),
                  LoadingSkeleton(height: 250, borderRadius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(height: 16),
                  LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(height: 16),
                  LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats
                    _buildOverviewSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // XP Over Time Chart
                    _buildXPChartSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Time Spent Per Realm
                    _buildTimeSpentSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Accuracy Rates
                    _buildAccuracySection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Favorite Games
                    _buildFavoriteGamesSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Strengths and Focus Areas
                    _buildStrengthsSection(),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Classroom Comparison
                    if (_classroomAverages != null) _buildClassroomComparisonSection(),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildOverviewSection() {
    final totalXP = _insightsData['totalXP'] ?? 0;
    final overallAccuracy = _insightsData['overallAccuracy'] ?? 0.0;
    final realms = _contentService.getAllRealms();
    final xpPerRealm = _insightsData['xpPerRealm'] as Map<String, int>? ?? {};
    final realmsStarted = xpPerRealm.values.where((xp) => xp > 0).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.stars,
                value: totalXP.toString(),
                label: 'Total XP',
                color: AppDesignSystem.primaryIndigo,
              ),
            ),
            const SizedBox(width: AppSpacing.cardSpacing),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                value: '${overallAccuracy.toStringAsFixed(0)}%',
                label: 'Accuracy',
                color: AppDesignSystem.success,
              ),
            ),
            const SizedBox(width: AppSpacing.cardSpacing),
            Expanded(
              child: _buildStatCard(
                icon: Icons.school,
                value: '$realmsStarted/${realms.length}',
                label: 'Realms',
                color: AppDesignSystem.info,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return CleanCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3,
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildXPChartSection() {
    final xpChartData = _insightsData['xpChartData'] as List<Map<String, dynamic>>? ?? [];
    
    if (xpChartData.isEmpty) {
      return CleanCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                'XP Over Time',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Complete levels to see your XP growth!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return CleanCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'XP Over Time',
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppDesignSystem.backgroundGrey,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= xpChartData.length) return const Text('');
                          final date = xpChartData[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: AppTextStyles.caption,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.caption,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppDesignSystem.backgroundGrey),
                  ),
                  minX: 0,
                  maxX: (xpChartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: (xpChartData.last['cumulativeXP'] as int).toDouble() * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: xpChartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['cumulativeXP'] as int).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppDesignSystem.primaryIndigo,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppDesignSystem.primaryIndigo,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
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
  
  Widget _buildTimeSpentSection() {
    final realms = _contentService.getAllRealms();
    final timeSpentPerRealm = _insightsData['timeSpentPerRealm'] as Map<String, int>? ?? {};
    
    // Filter realms with time spent
    final realmsWithTime = realms.where((realm) {
      return (timeSpentPerRealm[realm.id] ?? 0) > 0;
    }).toList();
    
    if (realmsWithTime.isEmpty) {
      return CleanCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                'Time Spent Per Realm',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Start learning to track your time!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Spent Per Realm',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        CleanCard(
          child: Column(
            children: realmsWithTime.asMap().entries.map((entry) {
              final index = entry.key;
              final realm = entry.value;
              final seconds = timeSpentPerRealm[realm.id] ?? 0;
              final minutes = (seconds / 60).round();
              final hours = (minutes / 60).floor();
              final remainingMinutes = minutes % 60;
              
              String timeText;
              if (hours > 0) {
                timeText = '${hours}h ${remainingMinutes}m';
              } else {
                timeText = '${minutes}m';
              }
              
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(realm.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            realm.iconEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              realm.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppDesignSystem.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeText,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(realm.color),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccuracySection() {
    final realms = _contentService.getAllRealms();
    final accuracyPerRealm = _insightsData['accuracyPerRealm'] as Map<String, double>? ?? {};
    
    // Filter realms with accuracy data
    final realmsWithAccuracy = realms.where((realm) {
      return (accuracyPerRealm[realm.id] ?? 0.0) > 0;
    }).toList();
    
    if (realmsWithAccuracy.isEmpty) {
      return CleanCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                'Accuracy Rates',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Complete quizzes to see your accuracy!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accuracy Rates',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        CleanCard(
          child: Column(
            children: realmsWithAccuracy.asMap().entries.map((entry) {
              final index = entry.key;
              final realm = entry.value;
              final accuracy = accuracyPerRealm[realm.id] ?? 0.0;
              
              Color accuracyColor;
              if (accuracy >= 80) {
                accuracyColor = AppDesignSystem.success;
              } else if (accuracy >= 60) {
                accuracyColor = AppDesignSystem.warning;
              } else {
                accuracyColor = AppDesignSystem.error;
              }
              
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(realm.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            realm.iconEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              realm.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppDesignSystem.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: accuracy / 100,
                                backgroundColor: AppDesignSystem.backgroundGrey,
                                valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${accuracy.toStringAsFixed(0)}%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accuracyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFavoriteGamesSection() {
    final favoriteGames = _insightsData['favoriteGames'] as List<Map<String, String>>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorite Games',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        CleanCard(
          child: Column(
            children: favoriteGames.asMap().entries.map((entry) {
              final index = entry.key;
              final game = entry.value;
              final name = game['name'] ?? '';
              final plays = game['plays'] ?? '0';
              
              IconData gameIcon;
              Color gameColor;
              
              switch (name) {
                case 'Quiz Master':
                  gameIcon = Icons.quiz;
                  gameColor = AppDesignSystem.primaryIndigo;
                  break;
                case 'Spot the Original':
                  gameIcon = Icons.image_search;
                  gameColor = AppDesignSystem.primaryPink;
                  break;
                case 'GI Mapper':
                  gameIcon = Icons.map;
                  gameColor = AppDesignSystem.success;
                  break;
                default:
                  gameIcon = Icons.games;
                  gameColor = AppDesignSystem.info;
              }
              
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: gameColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          gameIcon,
                          color: gameColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppDesignSystem.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$plays plays',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Game tracking coming soon!',
            style: AppTextStyles.caption.copyWith(
              color: AppDesignSystem.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStrengthsSection() {
    final strengths = _insightsData['strengths'] as List<String>? ?? [];
    final focusAreas = _insightsData['focusAreas'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Strengths & Focus Areas',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        CleanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strengths
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppDesignSystem.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Strengths',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (strengths.isEmpty)
                Text(
                  'Complete more levels with high accuracy to identify your strengths!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: strengths.map((strength) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppDesignSystem.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        strength,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              
              // Focus Areas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: AppDesignSystem.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Areas to Focus On',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (focusAreas.isEmpty)
                Text(
                  'Great job! Keep up the good work across all realms.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: focusAreas.map((area) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppDesignSystem.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        area,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildClassroomComparisonSection() {
    if (_classroomAverages == null) return const SizedBox.shrink();
    
    final myXP = _insightsData['totalXP'] ?? 0;
    final myAccuracy = _insightsData['overallAccuracy'] ?? 0.0;
    final avgXP = _classroomAverages!['averageXP'] ?? 0;
    final avgAccuracy = _classroomAverages!['averageAccuracy'] ?? 0.0;
    
    final xpDiff = myXP - avgXP;
    final accuracyDiff = myAccuracy - avgAccuracy;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classroom Comparison',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: AppSpacing.sm),
        CleanCard(
          child: Column(
            children: [
              // XP Comparison
              _buildComparisonRow(
                icon: Icons.stars,
                label: 'Total XP',
                myValue: myXP.toString(),
                avgValue: avgXP.toString(),
                difference: xpDiff,
                isHigherBetter: true,
                color: AppDesignSystem.primaryIndigo,
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              
              // Accuracy Comparison
              _buildComparisonRow(
                icon: Icons.check_circle,
                label: 'Accuracy',
                myValue: '${myAccuracy.toStringAsFixed(0)}%',
                avgValue: '${avgAccuracy.toStringAsFixed(0)}%',
                difference: accuracyDiff,
                isHigherBetter: true,
                color: AppDesignSystem.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildComparisonRow({
    required IconData icon,
    required String label,
    required String myValue,
    required String avgValue,
    required num difference,
    required bool isHigherBetter,
    required Color color,
  }) {
    final isAboveAverage = difference > 0;
    final comparisonColor = isAboveAverage == isHigherBetter
        ? AppDesignSystem.success
        : AppDesignSystem.warning;
    
    String comparisonText;
    IconData comparisonIcon;
    
    if (difference == 0) {
      comparisonText = 'At average';
      comparisonIcon = Icons.remove;
    } else if (isAboveAverage) {
      comparisonText = '${difference.abs().toStringAsFixed(0)} above avg';
      comparisonIcon = Icons.arrow_upward;
    } else {
      comparisonText = '${difference.abs().toStringAsFixed(0)} below avg';
      comparisonIcon = Icons.arrow_downward;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppDesignSystem.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  myValue,
                  style: AppTextStyles.h3.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Avg',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  avgValue,
                  style: AppTextStyles.h3.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: comparisonColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comparisonIcon,
                    size: 14,
                    color: comparisonColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comparisonText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: comparisonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
