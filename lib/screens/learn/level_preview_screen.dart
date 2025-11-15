import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/models/realm_model.dart';
import '../../core/services/content_service.dart';
import '../../core/services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'level_detail_screen.dart';

/// Screen to preview level before starting
class LevelPreviewScreen extends StatefulWidget {
  final String levelId;
  final String realmId;

  const LevelPreviewScreen({
    super.key,
    required this.levelId,
    required this.realmId,
  });

  @override
  State<LevelPreviewScreen> createState() => _LevelPreviewScreenState();
}

class _LevelPreviewScreenState extends State<LevelPreviewScreen> {
  final ContentService _contentService = ContentService();
  final ProgressService _progressService = ProgressService();
  
  LevelModel? _level;
  Map<String, dynamic>? _levelJson;
  bool _isLoading = true;
  bool _isCompleted = false;
  List<String> _prerequisiteLevels = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLevelPreview();
  }

  Future<void> _loadLevelPreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Loading level preview: ${widget.levelId}');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      // Load level from JSON
      final level = await _contentService.getLevelById(widget.levelId);
      
      if (level != null) {
        print('✅ Level preview loaded: ${level.name}');
        _level = level;
      } else {
        print('❌ Level is null');
        setState(() {
          _errorMessage = 'Level content not found';
          _isLoading = false;
        });
        return;
      }

      // Check if level is completed
      if (userId != null) {
        final realmProgress = await _progressService.getRealmProgress(userId, widget.realmId);
        if (realmProgress != null) {
          // Extract level number from levelId (format: realmId_level_X)
          final levelNumber = int.tryParse(widget.levelId.split('_').last) ?? 0;
          _isCompleted = realmProgress.isLevelCompleted(levelNumber);
        }
      }

      // Get prerequisite levels
      _prerequisiteLevels = await _getPrerequisiteLevels();

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading level preview: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load level preview: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _getPrerequisiteLevels() async {
    if (_level == null) return [];
    
    // Get all levels in the realm
    final allLevels = await _contentService.getLevelsForRealm(widget.realmId);
    
    // Find levels that come before this one
    final prerequisites = <String>[];
    for (final level in allLevels) {
      if (level.levelNumber < _level!.levelNumber) {
        prerequisites.add(level.name);
      }
    }
    
    return prerequisites;
  }

  LevelModel _convertJsonToModel(Map<String, dynamic> json) {
    final keyTakeaways = (json['keyTakeaways'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    final quizQuestions = (json['quizQuestions'] as List<dynamic>?)
        ?.map((q) {
          final question = q as Map<String, dynamic>;
          return QuizQuestion(
            question: question['question'] as String,
            options: (question['options'] as List<dynamic>)
                .map((e) => e.toString())
                .toList(),
            correctIndex: question['correctIndex'] as int,
            explanation: question['explanation'] as String,
          );
        })
        .toList() ?? [];

    return LevelModel(
      id: json['levelId'] as String,
      realmId: json['realmId'] as String,
      levelNumber: json['levelNumber'] as int,
      name: json['name'] as String,
      description: 'Difficulty: ${json['difficulty']}',
      content: '',
      keyPoints: keyTakeaways,
      quiz: quizQuestions,
      xpReward: json['xpReward'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      videoUrl: json['videoUrl'] as String?,
    );
  }

  String _getDifficultyLevel() {
    if (_levelJson != null) {
      return _levelJson!['difficulty'] as String? ?? 'Basic';
    }
    return 'Basic';
  }

  Color _getDifficultyColor() {
    final difficulty = _getDifficultyLevel();
    switch (difficulty.toLowerCase()) {
      case 'basic':
        return AppDesignSystem.success;
      case 'intermediate':
        return AppDesignSystem.warning;
      case 'advanced':
        return AppDesignSystem.error;
      default:
        return AppDesignSystem.primaryIndigo;
    }
  }

  List<String> _getTopicsCovered() {
    if (_level == null) return [];
    
    // Extract topics from key points
    return _level!.keyPoints.take(5).toList();
  }

  void _startLevel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LevelDetailScreen(
          levelId: widget.levelId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _level == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppDesignSystem.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage ?? 'Failed to load level',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _loadLevelPreview,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('Level ${_level!.levelNumber}'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesignSystem.primaryIndigo,
                    AppDesignSystem.secondaryPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Difficulty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyLevel().toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Level Title
                  Text(
                    _level!.name,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Completion Status
                  if (_isCompleted)
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: '${_level!.estimatedMinutes} min',
                          color: AppDesignSystem.primaryIndigo,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star_outline,
                          label: 'XP Reward',
                          value: '+${_level!.xpReward}',
                          color: AppDesignSystem.primaryAmber,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.quiz_outlined,
                          label: 'Questions',
                          value: '${_level!.quiz.length}',
                          color: AppDesignSystem.primaryGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Topics Covered
                  Text(
                    'What You\'ll Learn',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _getTopicsCovered().map((topic) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppDesignSystem.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  topic,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Prerequisites
                  if (_prerequisiteLevels.isNotEmpty) ...[
                    Text(
                      'Prerequisites',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(
                          color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppDesignSystem.primaryIndigo,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Complete these levels first:',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppDesignSystem.primaryIndigo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ..._prerequisiteLevels.map((prereq) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 4,
                                left: 28,
                              ),
                              child: Text(
                                '• $prereq',
                                style: AppTextStyles.bodyMedium,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Video Indicator
                  if (_level!.videoUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.secondaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: AppDesignSystem.secondaryBlue,
                            size: 32,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Video Content Included',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppDesignSystem.secondaryBlue,
                                  ),
                                ),
                                Text(
                                  'Watch the video to better understand the concepts',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Start Level Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.primaryIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _isCompleted ? 'Review Level' : 'Start Level',
                            style: AppTextStyles.buttonLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
