import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/services/progress_service.dart';
import '../../core/models/realm_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/loading_skeleton.dart';
import 'level_preview_screen.dart';

/// Realm Detail Screen - Shows levels within a realm
class RealmDetailScreen extends StatefulWidget {
  final Map<String, dynamic> realm;
  
  const RealmDetailScreen({
    super.key,
    required this.realm,
  });

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
  
  // Cached XP calculations
  int _cachedEarnedXP = 0;
  int _cachedTotalXP = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final realmId = widget.realm['realmId'] as String;
      
      // Load levels from ContentService (async)
      final levels = await _contentService.getLevelsForRealm(realmId);
      
      // Load user progress from ProgressService
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final progress = await _progressService.getRealmProgress(user.uid, realmId);
        if (progress != null) {
          setState(() {
            _levels = levels;
            _completedLevels = Set<int>.from(progress.completedLevels);
            _currentLevelNumber = progress.currentLevelNumber;
          });
        } else {
          setState(() {
            _levels = levels;
          });
        }
      } else {
        setState(() {
          _levels = levels;
        });
      }
      
      // Calculate cached XP values
      _updateCachedXP();
    } catch (e) {
      print('Error loading realm data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateCachedXP() {
    _cachedEarnedXP = 0;
    for (final level in _levels) {
      if (_completedLevels.contains(level.levelNumber)) {
        _cachedEarnedXP += level.xpReward;
      }
    }
    _cachedTotalXP = _levels.fold(0, (sum, level) => sum + level.xpReward);
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
    return _cachedEarnedXP;
  }

  int _getTotalXP() {
    return _cachedTotalXP;
  }
  
  Widget _buildCompactStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final String title = widget.realm['title'] ?? 'Realm';
    
    // Handle color - might be int or Color object
    Color color = AppDesignSystem.primaryIndigo;
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
        backgroundColor: AppDesignSystem.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Gradient App Bar with back button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                  child: Stack(
                    children: [
                      // Back button on the left
                      Positioned(
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Centered title
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title,
                            style: AppTextStyles.h2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Expanded(child: ListSkeleton(itemCount: 5)),
            ],
          ),
        ),
      );
    }

    final completedCount = _getCompletedLevelsCount();
    final progress = _getRealmProgress();
    final earnedXP = _getEarnedXP();
    final totalXP = _getTotalXP();
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient App Bar with back button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                child: Stack(
                  children: [
                    // Back button on the left
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Centered title
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Realm hero card with icon and stats - compact version
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Realm icon - smaller
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              widget.realm['iconPath'] as String? ?? 'assets/icons/realm_default.png',
                              width: 50,
                              height: 50,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.school,
                                  size: 50,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Stats - horizontal layout
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCompactStat(
                                      Icons.emoji_events,
                                      '$completedCount/${_levels.length}',
                                      'Levels',
                                    ),
                                    _buildCompactStat(
                                      Icons.stars,
                                      '$earnedXP',
                                      'XP',
                                    ),
                                    _buildCompactStat(
                                      Icons.trending_up,
                                      '${(progress * 100).toInt()}%',
                                      'Done',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white.withOpacity(0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            
            // About section - inline with description if available
            if (description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.4,
                          fontSize: 13,
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.md),
            
            // Levels section header - compact
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Levels',
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_levels.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Dynamic level items from ContentService
            ...(_levels.map((level) {
              final status = _getLevelStatus(level.levelNumber);
              
              // Try to get difficulty from level description or default based on level number
              String difficulty = 'Basic';
              if (level.description.contains('Intermediate')) {
                difficulty = 'Intermediate';
              } else if (level.description.contains('Advanced')) {
                difficulty = 'Advanced';
              } else if (level.levelNumber <= 3) {
                difficulty = 'Basic';
              } else if (level.levelNumber <= 6) {
                difficulty = 'Intermediate';
              } else {
                difficulty = 'Advanced';
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                child: _LevelItem(
                  levelNumber: level.levelNumber,
                  title: level.name,
                  xp: level.xpReward,
                  stars: _completedLevels.contains(level.levelNumber) ? 5 : 0, // TODO: Track actual stars
                  status: status,
                  color: color,
                  difficulty: difficulty,
                  estimatedMinutes: level.estimatedMinutes,
                  onTap: status == LevelStatus.locked 
                    ? () {
                        // Show locked message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Complete Level ${level.levelNumber - 1} to unlock this level'),
                            backgroundColor: AppDesignSystem.warning,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : () async {
                        // Navigate to level preview screen
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelPreviewScreen(
                              levelId: level.id,
                              realmId: widget.realm['realmId'] as String,
                            ),
                          ),
                        );
                        
                        // Reload data if level was completed
                        if (result == true) {
                          _loadData();
                        }
                      },
                ),
              );
            }).toList()),
            
            const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'basic':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppDesignSystem.textSecondary;
    }
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
  final String? difficulty;
  final int? estimatedMinutes;
  
  const _LevelItem({
    required this.levelNumber,
    required this.title,
    required this.xp,
    required this.stars,
    required this.status,
    required this.color,
    required this.onTap,
    this.difficulty,
    this.estimatedMinutes,
  });
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'basic':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppDesignSystem.textSecondary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isLocked = status == LevelStatus.locked;
    final bool isCurrent = status == LevelStatus.current;
    final bool isCompleted = status == LevelStatus.completed;
    
    return Container(
      decoration: BoxDecoration(
        color: isCurrent 
            ? color.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: isCurrent 
                ? color.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isCurrent ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? LinearGradient(
                                  colors: [
                                    AppDesignSystem.success,
                                    AppDesignSystem.success.withOpacity(0.8),
                                  ],
                                )
                              : isCurrent
                                  ? LinearGradient(
                                      colors: [
                                        color,
                                        color.withOpacity(0.8),
                                      ],
                                    )
                                  : null,
                          color: isLocked ? AppDesignSystem.backgroundGrey : null,
                          shape: BoxShape.circle,
                          boxShadow: isCompleted || isCurrent
                              ? [
                                  BoxShadow(
                                    color: (isCompleted ? AppDesignSystem.success : color)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : isCurrent
                                  ? Icons.play_circle_filled
                                  : Icons.lock,
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : AppDesignSystem.textTertiary,
                          size: 22,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppDesignSystem.success.withOpacity(0.15)
                                    : isCurrent
                                        ? color.withOpacity(0.15)
                                        : AppDesignSystem.backgroundGrey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Level $levelNumber',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isCompleted
                                      ? AppDesignSystem.success
                                      : isCurrent
                                          ? color
                                          : AppDesignSystem.textSecondary,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Difficulty badge
                            if (difficulty != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(difficulty!).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  difficulty!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: _getDifficultyColor(difficulty!),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (difficulty != null) const SizedBox(width: 8),
                            // Estimated time
                            if (estimatedMinutes != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$estimatedMinutes min',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            if (estimatedMinutes != null) const SizedBox(width: 8),
                            // XP reward
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? AppDesignSystem.backgroundGrey
                                    : AppDesignSystem.primaryAmber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stars,
                                    size: 13,
                                    color: isLocked
                                        ? AppDesignSystem.textTertiary
                                        : AppDesignSystem.primaryAmber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCompleted ? '$xp XP' : '+$xp XP',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isLocked
                                          ? AppDesignSystem.textTertiary
                                          : AppDesignSystem.primaryAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isCompleted) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  index < stars ? Icons.star : Icons.star_border,
                                  size: 14,
                                  color: AppDesignSystem.primaryAmber,
                                ),
                              ),
                            ),
                          ),
                        ],
                            if (isLocked) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 12,
                                    color: AppDesignSystem.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Complete Level ${levelNumber - 1} first',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Action button for current level - full width below
                  if (isCurrent) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Start Level',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
