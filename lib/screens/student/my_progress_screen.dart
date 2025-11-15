import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

/// My Progress Screen - Student's self-view of their progress
class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic> _progressSummary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _progressSummary = _userData?['progressSummary'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error loading progress: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: ProfileSkeleton(),
      );
    }

    final totalXP = _userData?['totalXP'] ?? 0;
    final level = _userData?['level'] ?? 1;
    final dayStreak = _userData?['currentStreak'] ?? 0;
    final badges = (_userData?['badges'] as List?)?.length ?? 0;

    // Calculate realm stats
    int completedRealms = 0;
    int totalLevels = 0;
    int completedLevels = 0;

    _progressSummary.forEach((key, value) {
      if (value is Map) {
        if (value['completed'] == true) {
          completedRealms++;
        }
        totalLevels += (value['totalLevels'] ?? 0) as int;
        completedLevels += (value['levelsCompleted'] ?? 0) as int;
      }
    });

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient - Just title
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
                          'My Progress',
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level and User Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                            AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Level circle
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppDesignSystem.gradientPrimary,
                              border: Border.all(color: AppDesignSystem.primaryIndigo, width: 3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Level',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$level',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _userData?['displayName'] ?? 'Student',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppDesignSystem.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // XP Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '⭐',
                            '$totalXP',
                            'Total XP',
                            const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '🔥',
                            '$dayStreak',
                            'Day Streak',
                            const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '🏅',
                            '$badges',
                            'Badges',
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '✅',
                            '$completedRealms',
                            'Realms Done',
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Realm Progress
                    const Text(
                      'Realm Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CleanCard(
                      child: Column(
                        children: [
                          _buildProgressRow(
                            'Total Levels',
                            completedLevels,
                            totalLevels,
                            Colors.blue,
                          ),
                          const Divider(height: 24),
                          _buildProgressRow(
                            'Realms Completed',
                            completedRealms,
                            6,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Detailed Realm List
                    const Text(
                      'Realm Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._progressSummary.entries.map((entry) {
                      if (entry.value is! Map) return const SizedBox();
                      
                      final realmData = entry.value as Map;
                      final realmName = entry.key;
                      final levelsCompleted = (realmData['levelsCompleted'] ?? 0) as int;
                      final totalLevels = (realmData['totalLevels'] ?? 1) as int;
                      final progress = levelsCompleted / totalLevels;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CleanCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getRealmIcon(realmName),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatRealmName(realmName),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '$levelsCompleted / $totalLevels levels',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (realmData['completed'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, 
                                            color: Colors.green[700], 
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Done',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    realmData['completed'] == true
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(progress * 100).toInt()}% Complete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int total, Color color) {
    final progress = total > 0 ? current / total : 0.0;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$current / $total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRealmIcon(String realmName) {
    final icons = {
      'patent': '📜',
      'trademark': '™️',
      'copyright': '©️',
      'trade_secrets': '🤐',
      'industrial_design': '🎨',
      'geographical_indications': '🌍',
    };
    return icons[realmName.toLowerCase()] ?? '📚';
  }

  String _formatRealmName(String name) {
    return name.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
