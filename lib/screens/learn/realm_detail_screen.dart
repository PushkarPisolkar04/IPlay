import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/models/realm_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';

/// Realm Detail Screen - Shows levels within a realm
class RealmDetailScreen extends StatefulWidget {
  final Map<String, dynamic> realm;
  
  const RealmDetailScreen({
    Key? key,
    required this.realm,
  }) : super(key: key);

  @override
  State<RealmDetailScreen> createState() => _RealmDetailScreenState();
}

class _RealmDetailScreenState extends State<RealmDetailScreen> {
  final ContentService _contentService = ContentService();
  final ProgressService _progressService = ProgressService();
  
  List<LevelModel> _levels = [];
  Set<int> _completedLevels = {};
  int _currentLevelNumber = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final realmId = widget.realm['realmId'] as String;
      
      // Load levels from ContentService
      _levels = _contentService.getLevelsForRealm(realmId);
      
      // Load user progress from ProgressService
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final progress = await _progressService.getRealmProgress(user.uid, realmId);
        if (progress != null) {
          setState(() {
            _completedLevels = Set<int>.from(progress.completedLevels);
            _currentLevelNumber = progress.currentLevelNumber;
          });
        }
      }
    } catch (e) {
      print('Error loading realm data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  LevelStatus _getLevelStatus(int levelNumber) {
    if (_completedLevels.contains(levelNumber)) {
      return LevelStatus.completed;
    } else if (levelNumber == _currentLevelNumber) {
      return LevelStatus.current;
    } else if (levelNumber > _currentLevelNumber) {
      return LevelStatus.locked;
    } else {
      return LevelStatus.current; // Previous uncompleted levels
    }
  }

  int _getCompletedLevelsCount() {
    return _completedLevels.length;
  }

  double _getRealmProgress() {
    if (_levels.isEmpty) return 0.0;
    return _completedLevels.length / _levels.length;
  }

  int _getEarnedXP() {
    int totalXP = 0;
    for (final level in _levels) {
      if (_completedLevels.contains(level.levelNumber)) {
        totalXP += level.xpReward;
      }
    }
    return totalXP;
  }

  int _getTotalXP() {
    return _levels.fold(0, (sum, level) => sum + level.xpReward);
  }
  
  @override
  Widget build(BuildContext context) {
    final String title = widget.realm['title'] ?? 'Realm';
    
    // Handle color - might be int or Color object
    Color color = AppColors.primary;
    if (widget.realm['color'] != null) {
      if (widget.realm['color'] is Color) {
        color = widget.realm['color'] as Color;
      } else if (widget.realm['color'] is int) {
        color = Color(widget.realm['color'] as int);
      }
    }
    
    final String description = widget.realm['description'] ?? '';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final completedCount = _getCompletedLevelsCount();
    final progress = _getRealmProgress();
    final earnedXP = _getEarnedXP();
    final totalXP = _getTotalXP();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // TODO: Download realm for offline
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline download coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Realm illustration placeholder
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: color,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Progress card
            CleanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(progress: progress, height: 10),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$completedCount/${_levels.length} levels',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '•',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$earnedXP/$totalXP XP',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // About section
            if (description.isNotEmpty) ...[
              Text(
                'About',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodyMedium,
              ),
            ],
            
            const SizedBox(height: AppSpacing.lg),
            
            // Levels section
            Text(
              'Levels (${_levels.length})',
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Dynamic level items from ContentService
            ...(_levels.map((level) {
              final status = _getLevelStatus(level.levelNumber);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                child: _LevelItem(
                  levelNumber: level.levelNumber,
                  title: level.name,
                  xp: level.xpReward,
                  stars: _completedLevels.contains(level.levelNumber) ? 5 : 0, // TODO: Track actual stars
                  status: status,
                  color: color,
                  onTap: () {
                    // Navigate to level content screen
                    Navigator.pushNamed(
                      context,
                      '/level-content',
                      arguments: {'level': level},
                    );
                  },
                ),
              );
            }).toList()),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Download button
            SecondaryButton(
              text: 'Download Offline',
              onPressed: () {},
              fullWidth: true,
              icon: Icons.download,
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

enum LevelStatus { completed, current, locked }

/// Level item card
class _LevelItem extends StatelessWidget {
  final int levelNumber;
  final String title;
  final int xp;
  final int stars;
  final LevelStatus status;
  final Color color;
  final VoidCallback onTap;
  
  const _LevelItem({
    Key? key,
    required this.levelNumber,
    required this.title,
    required this.xp,
    required this.stars,
    required this.status,
    required this.color,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isLocked = status == LevelStatus.locked;
    final bool isCurrent = status == LevelStatus.current;
    final bool isCompleted = status == LevelStatus.completed;
    
    return CleanCard(
      color: isCurrent 
          ? color.withOpacity(0.05) 
          : AppColors.background,
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withOpacity(0.15)
                    : isCurrent
                        ? color.withOpacity(0.15)
                        : AppColors.backgroundGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.play_arrow
                        : Icons.lock,
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? color
                        : AppColors.textTertiary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Level $levelNumber',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.success
                              : isCurrent
                                  ? color
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isCompleted) ...[
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < stars
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: isLocked
                            ? AppColors.textTertiary
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? '$xp XP' : '0/$xp XP',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Complete Level ${levelNumber - 1} first',
                      style: AppTextStyles.caption,
                    ),
                  ],
                  if (isCurrent) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
