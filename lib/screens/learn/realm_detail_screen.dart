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
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  
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
      
      // Load levels from ContentService
      _levels = _contentService.getLevelsForRealm(realmId);
      
      // Check if realm is downloaded for offline
      _isDownloaded = await _contentService.isRealmAvailableOffline(realmId);
      
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
      
      // Calculate cached XP values
      _updateCachedXP();
    } catch (e) {
      // print('Error loading realm data: $e');
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

  Future<void> _downloadRealmForOffline() async {
    final realmId = widget.realm['realmId'] as String;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Show download dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Downloading Realm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Downloading all levels and content for offline access...'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: AppDesignSystem.backgroundGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.realm['color'] is Color 
                          ? widget.realm['color'] as Color 
                          : Color(widget.realm['color'] as int? ?? AppDesignSystem.primaryIndigo.value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Download each level with progress updates
      for (int i = 0; i < _levels.length; i++) {
        final level = _levels[i];
        final levelId = level.id;
        
        // Load and cache level content
        await _contentService.getLevelContent(levelId);
        
        // Update progress
        setState(() {
          _downloadProgress = (i + 1) / _levels.length;
        });
        
        // Update dialog
        if (mounted) {
          // Force rebuild of dialog
          Navigator.of(context).pop();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Downloading Realm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Downloading level ${i + 1} of ${_levels.length}...'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: AppDesignSystem.backgroundGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.realm['color'] is Color 
                          ? widget.realm['color'] as Color 
                          : Color(widget.realm['color'] as int? ?? AppDesignSystem.primaryIndigo.value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
      }

      // Mark realm as downloaded
      final success = await _contentService.downloadRealmForOffline(realmId);
      
      if (success) {
        setState(() {
          _isDownloaded = true;
        });
        
        // Close dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Realm downloaded! You can now access it offline.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppDesignSystem.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      // print('Error downloading realm: $e');
      
      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Failed to download realm. Please try again.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppDesignSystem.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  Future<void> _deleteOfflineRealm() async {
    final realmId = widget.realm['realmId'] as String;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline Content'),
        content: const Text(
          'Are you sure you want to delete the offline content for this realm? '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppDesignSystem.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _contentService.deleteOfflineRealm(realmId);
        
        setState(() {
          _isDownloaded = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline content deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // print('Error deleting offline realm: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete offline content'),
              backgroundColor: AppDesignSystem.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
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
    return _cachedEarnedXP;
  }

  int _getTotalXP() {
    return _cachedTotalXP;
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
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const ListSkeleton(itemCount: 5),
      );
    }

    final completedCount = _getCompletedLevelsCount();
    final progress = _getRealmProgress();
    final earnedXP = _getEarnedXP();
    final totalXP = _getTotalXP();
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isDownloaded)
            IconButton(
              icon: const Icon(Icons.download_done),
              color: AppDesignSystem.success,
              onPressed: _deleteOfflineRealm,
              tooltip: 'Downloaded - Tap to delete',
            )
          else
            IconButton(
              icon: _isDownloading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              onPressed: _isDownloading ? null : _downloadRealmForOffline,
              tooltip: _isDownloaded 
                  ? 'Downloaded' 
                  : 'Download for offline',
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
                color: color.withValues(alpha: 0.1),
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
                            color: AppDesignSystem.primaryAmber,
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
                  onTap: () {
                    // Navigate to level preview screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelPreviewScreen(
                          levelId: level.id,
                          realmId: widget.realm['realmId'] as String,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList()),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Download button
            if (!_isDownloaded)
              SecondaryButton(
                text: _isDownloading ? 'Downloading...' : 'Download for Offline',
                onPressed: _isDownloading ? null : _downloadRealmForOffline,
                fullWidth: true,
                icon: _isDownloading ? null : Icons.download,
              )
            else
              SecondaryButton(
                text: 'Delete Offline Content',
                onPressed: _deleteOfflineRealm,
                fullWidth: true,
                icon: Icons.delete_outline,
              ),
            
            const SizedBox(height: AppSpacing.xl),
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
    
    return CleanCard(
      color: isCurrent 
          ? color.withValues(alpha: 0.05) 
          : AppDesignSystem.backgroundLight,
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
                    ? AppDesignSystem.success.withValues(alpha: 0.15)
                    : isCurrent
                        ? color.withValues(alpha: 0.15)
                        : AppDesignSystem.backgroundGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.play_arrow
                        : Icons.lock,
                color: isCompleted
                    ? AppDesignSystem.success
                    : isCurrent
                        ? color
                        : AppDesignSystem.textTertiary,
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
                              ? AppDesignSystem.success
                              : isCurrent
                                  ? color
                                  : AppDesignSystem.textSecondary,
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Difficulty badge
                      if (difficulty != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty!,
                            style: AppTextStyles.caption.copyWith(
                              color: _getDifficultyColor(difficulty!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      // Estimated time
                      if (estimatedMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppDesignSystem.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$estimatedMinutes min',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      // XP reward
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            size: 12,
                            color: isLocked
                                ? AppDesignSystem.textTertiary
                                : AppDesignSystem.primaryAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? '$xp XP' : '+$xp XP',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? AppDesignSystem.textTertiary
                                  : AppDesignSystem.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < stars
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppDesignSystem.primaryAmber,
                        ),
                      ),
                    ),
                  ],
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
