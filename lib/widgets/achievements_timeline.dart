import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/design/app_design_system.dart';

/// Achievements timeline widget showing milestones and realm completions
class AchievementsTimeline extends StatelessWidget {
  final String userId;
  final int totalXP;
  final Map<String, dynamic> progressSummary;

  const AchievementsTimeline({
    super.key,
    required this.userId,
    required this.totalXP,
    required this.progressSummary,
  });

  List<Achievement> _buildAchievements() {
    final achievements = <Achievement>[];

    // XP Milestones
    final xpMilestones = [
      {'xp': 100, 'title': 'First Steps', 'icon': '🎯'},
      {'xp': 500, 'title': 'Getting Started', 'icon': '🌟'},
      {'xp': 1000, 'title': 'Rising Star', 'icon': '⭐'},
      {'xp': 2500, 'title': 'Knowledge Seeker', 'icon': '📚'},
      {'xp': 5000, 'title': 'IPR Expert', 'icon': '🎓'},
      {'xp': 10000, 'title': 'Master Scholar', 'icon': '👑'},
    ];

    for (final milestone in xpMilestones) {
      final xp = milestone['xp'] as int;
      final achieved = totalXP >= xp;
      achievements.add(Achievement(
        title: milestone['title'] as String,
        subtitle: achieved
            ? 'Reached $xp XP'
            : 'Reach $xp XP ($totalXP/$xp)',
        icon: milestone['icon'] as String,
        achieved: achieved,
        progress: achieved ? 1.0 : (totalXP / xp).clamp(0.0, 1.0),
        date: achieved ? DateTime.now() : null, // In production, get actual date
      ));
    }

    // Realm completions
    final realmInfo = {
      'copyright': {'name': 'Copyright Master', 'icon': '©️'},
      'trademark': {'name': 'Trademark Expert', 'icon': '™️'},
      'patent': {'name': 'Patent Guru', 'icon': '💡'},
      'industrial_design': {'name': 'Design Specialist', 'icon': '🎨'},
      'gi': {'name': 'GI Champion', 'icon': '🌍'},
      'trade_secrets': {'name': 'Secrets Keeper', 'icon': '🔒'},
    };

    for (final entry in progressSummary.entries) {
      final realmId = entry.key;
      final progress = entry.value as Map<String, dynamic>?;
      
      if (progress != null && realmInfo.containsKey(realmId)) {
        final completed = progress['completed'] == true;
        final levelsCompleted = progress['levelsCompleted'] as int? ?? 0;
        final totalLevels = progress['totalLevels'] as int? ?? 8;
        final info = realmInfo[realmId]!;

        achievements.add(Achievement(
          title: info['name'] as String,
          subtitle: completed
              ? 'Completed all $totalLevels levels'
              : 'Complete $levelsCompleted/$totalLevels levels',
          icon: info['icon'] as String,
          achieved: completed,
          progress: levelsCompleted / totalLevels,
          date: completed && progress['completedAt'] != null
              ? (progress['completedAt'] as Timestamp).toDate()
              : null,
        ));
      }
    }

    // Sort: achieved first (by date), then by progress
    achievements.sort((a, b) {
      if (a.achieved && !b.achieved) return -1;
      if (!a.achieved && b.achieved) return 1;
      if (a.achieved && b.achieved) {
        return (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now());
      }
      return b.progress.compareTo(a.progress);
    });

    return achievements;
  }

  Achievement? _getNextMilestone() {
    final achievements = _buildAchievements();
    return achievements.firstWhere(
      (a) => !a.achieved,
      orElse: () => achievements.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();
    final nextMilestone = _getNextMilestone();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${achievements.where((a) => a.achieved).length}/${achievements.length}',
                style: TextStyle(
                  fontSize: 18,
                  color: AppDesignSystem.primaryIndigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Next milestone card
        if (nextMilestone != null && !nextMilestone.achieved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesignSystem.primaryIndigo,
                    AppDesignSystem.primaryPink,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nextMilestone.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Milestone',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              nextMilestone.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                      value: nextMilestone.progress,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextMilestone.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Timeline
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return _buildTimelineItem(
              achievements[index],
              isFirst: index == 0,
              isLast: index == achievements.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    Achievement achievement, {
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.achieved
                      ? AppDesignSystem.primaryIndigo
                      : Colors.grey.shade300,
                  border: Border.all(
                    color: achievement.achieved
                        ? AppDesignSystem.primaryIndigo
                        : Colors.grey.shade400,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: achievement.achieved
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: achievement.achieved
                        ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!achievement.achieved)
                        Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      if (!achievement.achieved) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: achievement.achieved
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: achievement.achieved
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (achievement.date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(achievement.date!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  if (!achievement.achieved && achievement.progress > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppDesignSystem.primaryIndigo,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String title;
  final String subtitle;
  final String icon;
  final bool achieved;
  final double progress;
  final DateTime? date;

  Achievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.achieved,
    required this.progress,
    this.date,
  });
}
