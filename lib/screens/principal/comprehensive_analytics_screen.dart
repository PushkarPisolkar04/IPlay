import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

/// Comprehensive Analytics Screen for Principal
/// Displays school-wide engagement metrics, top performers, and realm completion rates
/// with interactive charts and export options
class ComprehensiveAnalyticsScreen extends StatefulWidget {
  final String schoolId;

  const ComprehensiveAnalyticsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ComprehensiveAnalyticsScreen> createState() => _ComprehensiveAnalyticsScreenState();
}

class _ComprehensiveAnalyticsScreenState extends State<ComprehensiveAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isExporting = false;
  
  // Analytics Data
  int _totalStudents = 0;
  int _activeStudents = 0;
  double _avgXP = 0;
  double _avgStreak = 0;
  double _avgProgress = 0;
  
  List<Map<String, dynamic>> _topClassrooms = [];
  List<Map<String, dynamic>> _topStudents = [];
  Map<String, double> _realmCompletionRates = {};
  Map<String, int> _weeklyActivity = {};
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all classrooms in school
      final classroomsSnapshot = await _firestore
          .collection('classrooms')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();
      
      // Collect all student data
      Set<String> uniqueStudentIds = {};
      Map<String, Map<String, dynamic>> studentData = {};
      Map<String, List<String>> classroomStudents = {};
      Map<String, String> classroomNames = {};
      
      for (var classroomDoc in classroomsSnapshot.docs) {
        final data = classroomDoc.data();
        final classroomId = classroomDoc.id;
        final classroomName = data['name'] ?? 'Unnamed';
        classroomNames[classroomId] = classroomName;
        
        final studentIds = List<String>.from(data['studentIds'] ?? []);
        classroomStudents[classroomId] = studentIds;
        uniqueStudentIds.addAll(studentIds);
      }
      
      _totalStudents = uniqueStudentIds.length;
      
      // Load student data
      int totalXP = 0;
      int totalStreak = 0;
      int totalProgress = 0;
      _activeStudents = 0;
      
      Map<String, int> realmCompletions = {};
      Map<String, int> realmTotals = {};
      
      for (var studentId in uniqueStudentIds) {
        final studentDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();
        
        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          final xp = data['totalXP'] ?? 0;
          final streak = data['currentStreak'] ?? 0;
          final progressSummary = data['progressSummary'] as Map<String, dynamic>? ?? {};
          
          totalXP += xp as int;
          totalStreak += streak as int;
          
          // Calculate progress
          int levelsCompleted = 0;
          int totalLevels = 0;
          for (var entry in progressSummary.values) {
            if (entry is Map<String, dynamic>) {
              levelsCompleted += (entry['levelsCompleted'] as int?) ?? 0;
              totalLevels += (entry['totalLevels'] as int?) ?? 0;
              
              // Track realm completions
              final realmId = progressSummary.keys.firstWhere(
                (key) => progressSummary[key] == entry,
                orElse: () => '',
              );
              if (realmId.isNotEmpty) {
                realmTotals[realmId] = (realmTotals[realmId] ?? 0) + 1;
                if (entry['completed'] == true) {
                  realmCompletions[realmId] = (realmCompletions[realmId] ?? 0) + 1;
                }
              }
            }
          }
          
          final progress = totalLevels > 0 ? (levelsCompleted / totalLevels * 100).round() : 0;
          totalProgress += progress;
          
          // Check if active (last 7 days)
          final lastActive = (data['lastActiveDate'] as Timestamp?)?.toDate();
          if (lastActive != null) {
            final daysSince = DateTime.now().difference(lastActive).inDays;
            if (daysSince <= 7) {
              _activeStudents++;
            }
          }
          
          studentData[studentId] = {
            'id': studentId,
            'name': data['displayName'] ?? 'Unknown',
            'xp': xp,
            'streak': streak,
            'progress': progress,
            'avatarUrl': data['avatarUrl'],
          };
        }
      }
      
      // Calculate averages
      if (_totalStudents > 0) {
        _avgXP = totalXP / _totalStudents;
        _avgStreak = totalStreak / _totalStudents;
        _avgProgress = totalProgress / _totalStudents;
      }
      
      // Calculate realm completion rates
      _realmCompletionRates = {};
      for (var realmId in realmCompletions.keys) {
        final completions = realmCompletions[realmId] ?? 0;
        final total = realmTotals[realmId] ?? 1;
        _realmCompletionRates[realmId] = (completions / total * 100);
      }
      
      // Calculate top classrooms by average XP
      _topClassrooms = [];
      for (var classroomId in classroomStudents.keys) {
        final students = classroomStudents[classroomId] ?? [];
        if (students.isEmpty) continue;
        
        int classroomXP = 0;
        for (var studentId in students) {
          classroomXP += (studentData[studentId]?['xp'] ?? 0) as int;
        }
        
        _topClassrooms.add({
          'name': classroomNames[classroomId] ?? 'Unnamed',
          'avgXP': classroomXP / students.length,
          'studentCount': students.length,
        });
      }
      
      _topClassrooms.sort((a, b) => (b['avgXP'] as double).compareTo(a['avgXP'] as double));
      _topClassrooms = _topClassrooms.take(5).toList();
      
      // Get top students
      _topStudents = studentData.values.toList();
      _topStudents.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      _topStudents = _topStudents.take(10).toList();
      
      // Calculate weekly activity (last 7 days)
      _weeklyActivity = {};
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.month}/${date.day}';
        _weeklyActivity[dateKey] = 0;
      }
      
      // Count active students per day (simplified - would need activity logs)
      // For now, just show current active students distributed
      final dailyAvg = (_activeStudents / 7).round();
      for (var key in _weeklyActivity.keys) {
        _weeklyActivity[key] = dailyAvg;
      }
      
    } catch (e) {
      // print('Error loading analytics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToPDF() async {
    setState(() => _isExporting = true);
    
    try {
      // Generate CSV data
      final csvData = _generateCSVData();
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/school_analytics_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData);
      
      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'School Analytics Report',
        text: 'School analytics report generated on ${DateTime.now().toString().split('.')[0]}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics exported successfully')),
        );
      }
    } catch (e) {
      // print('Error exporting analytics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _generateCSVData() {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('School Analytics Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    
    // Overview
    buffer.writeln('Overview');
    buffer.writeln('Total Students,$_totalStudents');
    buffer.writeln('Active Students,$_activeStudents');
    buffer.writeln('Average XP,${_avgXP.toStringAsFixed(1)}');
    buffer.writeln('Average Streak,${_avgStreak.toStringAsFixed(1)}');
    buffer.writeln('Average Progress,${_avgProgress.toStringAsFixed(1)}%');
    buffer.writeln('');
    
    // Top Classrooms
    buffer.writeln('Top Classrooms');
    buffer.writeln('Rank,Classroom,Avg XP,Students');
    for (int i = 0; i < _topClassrooms.length; i++) {
      final classroom = _topClassrooms[i];
      buffer.writeln('${i + 1},${classroom['name']},${(classroom['avgXP'] as double).toStringAsFixed(1)},${classroom['studentCount']}');
    }
    buffer.writeln('');
    
    // Top Students
    buffer.writeln('Top Students');
    buffer.writeln('Rank,Name,XP,Streak,Progress');
    for (int i = 0; i < _topStudents.length; i++) {
      final student = _topStudents[i];
      buffer.writeln('${i + 1},${student['name']},${student['xp']},${student['streak']},${student['progress']}%');
    }
    buffer.writeln('');
    
    // Realm Completion Rates
    buffer.writeln('Realm Completion Rates');
    buffer.writeln('Realm,Completion Rate');
    for (var entry in _realmCompletionRates.entries) {
      buffer.writeln('${entry.key},${entry.value.toStringAsFixed(1)}%');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('School Analytics'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportToPDF,
          ),
        ],
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
                    ],
                  ),
                  SizedBox(height: 16),
                  LoadingSkeleton(height: 250, borderRadius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(height: 16),
                  LoadingSkeleton(height: 250, borderRadius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(height: 16),
                  ListSkeleton(itemCount: 3),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildSectionTitle('School Overview'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMetricCard(
                          'Total Students',
                          _totalStudents.toString(),
                          Icons.people,
                          const Color(0xFF3B82F6),
                        ),
                        _buildMetricCard(
                          'Active (7d)',
                          _activeStudents.toString(),
                          Icons.trending_up,
                          const Color(0xFF10B981),
                        ),
                        _buildMetricCard(
                          'Avg XP',
                          _avgXP.toStringAsFixed(0),
                          Icons.stars,
                          const Color(0xFFF59E0B),
                        ),
                        _buildMetricCard(
                          'Avg Progress',
                          '${_avgProgress.toStringAsFixed(0)}%',
                          Icons.show_chart,
                          const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Weekly Activity Chart
                    _buildSectionTitle('Weekly Activity'),
                    const SizedBox(height: 12),
                    CleanCard(
                      child: SizedBox(
                        height: 200,
                        child: _buildWeeklyActivityChart(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Realm Completion Rates
                    _buildSectionTitle('Realm Completion Rates'),
                    const SizedBox(height: 12),
                    CleanCard(
                      child: SizedBox(
                        height: 250,
                        child: _buildRealmCompletionChart(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Top Classrooms
                    _buildSectionTitle('Top Performing Classrooms'),
                    const SizedBox(height: 12),
                    CleanCard(
                      child: Column(
                        children: _topClassrooms.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No classroom data available'),
                                ),
                              ]
                            : _topClassrooms.asMap().entries.map((entry) {
                                final index = entry.key;
                                final classroom = entry.value;
                                return _buildClassroomTile(
                                  index + 1,
                                  classroom['name'],
                                  classroom['avgXP'],
                                  classroom['studentCount'],
                                );
                              }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Top Students
                    _buildSectionTitle('Top Performing Students'),
                    const SizedBox(height: 12),
                    CleanCard(
                      child: Column(
                        children: _topStudents.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No student data available'),
                                ),
                              ]
                            : _topStudents.asMap().entries.map((entry) {
                                final index = entry.key;
                                final student = entry.value;
                                return _buildStudentTile(
                                  index + 1,
                                  student['name'],
                                  student['xp'],
                                  student['progress'],
                                );
                              }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return CleanCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
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
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    if (_weeklyActivity.isEmpty) {
      return const Center(child: Text('No activity data'));
    }
    
    final spots = _weeklyActivity.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _weeklyActivity.length) {
                    final key = _weeklyActivity.keys.toList()[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF6B46C1),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF6B46C1).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealmCompletionChart() {
    if (_realmCompletionRates.isEmpty) {
      return const Center(child: Text('No realm data'));
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final keys = _realmCompletionRates.keys.toList();
                  if (index >= 0 && index < keys.length) {
                    final realmId = keys[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        AppConstants.realmNames[realmId] ?? realmId,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _realmCompletionRates.entries.toList().asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: const Color(0xFF10B981),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildClassroomTile(int rank, String name, double avgXP, int studentCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$studentCount students',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${avgXP.toStringAsFixed(0)} XP',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(int rank, String name, int xp, int progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progress% complete',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$xp XP',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    if (rank == 1) {
      color = const Color(0xFFFCD34D); // Gold
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32); // Bronze
    } else {
      color = const Color(0xFF9CA3AF); // Gray
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
