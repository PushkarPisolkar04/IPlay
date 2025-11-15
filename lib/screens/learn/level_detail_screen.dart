import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/realm_model.dart';
import '../../core/services/content_service.dart';
import '../quiz/level_quiz_screen.dart';
import '../../widgets/loading_skeleton.dart';
import '../../services/bookmark_service.dart';

/// Screen to display level details with video, content, and quiz
class LevelDetailScreen extends StatefulWidget {
  final String levelId;
  final bool isLocked;

  const LevelDetailScreen({
    super.key,
    required this.levelId,
    this.isLocked = false,
  });

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  final ContentService _contentService = ContentService();
  final BookmarkService _bookmarkService = BookmarkService();
  LevelModel? _level;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  bool _videoCompleted = false;
  String? _errorMessage;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadLevel();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _bookmarkService.isBookmarked(widget.levelId);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_level == null) return;

    try {
      final newStatus = await _bookmarkService.toggleBookmark(
        levelId: widget.levelId,
        levelName: _level!.name,
        realmId: _level!.realmId,
        realmName: _getRealmName(_level!.realmId),
      );

      if (mounted) {
        setState(() {
          _isBookmarked = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Bookmark added' : 'Bookmark removed',
            ),
            backgroundColor: AppDesignSystem.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  String _getRealmName(String realmId) {
    // Use centralized realm names from AppConstants
    return AppConstants.realmNames[realmId] ?? 'Unknown Realm';
  }

  Future<void> _loadLevel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Loading level: ${widget.levelId}');
      
      // Load level using the updated service that merges quiz data
      final level = await _contentService.getLevelById(widget.levelId);
      
      if (level != null) {
        print('✅ Level loaded, initializing UI');
        await _loadFromModel(level);
      } else {
        print('❌ Level is null');
        setState(() {
          _errorMessage = 'Level content not found';
          _isLoading = false;
        });
        return;
      }
    } catch (e, stackTrace) {
      print('❌ Error loading level: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load level content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromJson(Map<String, dynamic> json) async {
    // Initialize video player if video URL exists
    if (json['videoUrl'] != null) {
      final videoUrl = json['videoUrl'] as String;
      String? videoId;
      
      // Check if it's already a video ID or a full URL
      if (videoUrl.length == 11 && !videoUrl.contains('/')) {
        videoId = videoUrl;
      } else {
        videoId = YoutubePlayer.convertUrlToId(videoUrl);
      }
      
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
          ),
        );
        
        // Listen to video progress
        _youtubeController!.addListener(_onVideoProgress);
      }
    }

    // Convert JSON to LevelModel for compatibility
    final level = _convertJsonToModel(json);

    setState(() {
      _level = level;
      _isLoading = false;
    });
  }

  Future<void> _loadFromModel(LevelModel level) async {
    if (level.videoUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(level.videoUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
          ),
        );
        
        _youtubeController!.addListener(_onVideoProgress);
      }
    }

    setState(() {
      _level = level;
      _isLoading = false;
    });
  }

  void _onVideoProgress() {
    if (_youtubeController == null) return;
    
    final position = _youtubeController!.value.position.inSeconds;
    final duration = _youtubeController!.metadata.duration.inSeconds;
    
    if (duration > 0) {
      final progress = position / duration;
      // Mark as completed if watched 90% or more
      if (progress >= 0.9 && !_videoCompleted) {
        setState(() {
          _videoCompleted = true;
        });
      }
    }
  }

  LevelModel _convertJsonToModel(Map<String, dynamic> json) {
    // Extract key takeaways
    final keyTakeaways = (json['keyTakeaways'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    // Extract quiz questions
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

    // Build content from content blocks
    final contentBlocks = (json['contentBlocks'] as List<dynamic>?)
        ?.map((block) {
          final b = block as Map<String, dynamic>;
          final type = b['type'] as String;
          final content = b['content'] as String;
          final caption = b['caption'] as String?;
          
          switch (type) {
            case 'text':
              return content;
            case 'image':
              return '![${caption ?? 'Image'}]($content)';
            case 'example':
              final title = b['metadata']?['title'] as String? ?? 'Example';
              return '### 📝 $title\n\n$content';
            case 'case_study':
              final title = b['metadata']?['title'] as String? ?? 'Case Study';
              return '### 📚 $title\n\n$content';
            case 'summary':
              return '### 📌 Summary\n\n$content';
            default:
              return content;
          }
        })
        .join('\n\n') ?? '';

    return LevelModel(
      id: json['levelId'] as String,
      realmId: json['realmId'] as String,
      levelNumber: json['levelNumber'] as int,
      name: json['name'] as String,
      description: 'Difficulty: ${json['difficulty']}',
      content: contentBlocks,
      keyPoints: keyTakeaways,
      quiz: quizQuestions,
      xpReward: json['xpReward'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      videoUrl: json['videoUrl'] as String?,
    );
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_onVideoProgress);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Locked Level'),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This level is locked',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Complete previous levels to unlock',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: Colors.white,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
              SizedBox(height: 16),
              LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12))),
              SizedBox(height: 16),
              LoadingSkeleton(height: 300, borderRadius: BorderRadius.all(Radius.circular(12))),
            ],
          ),
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
                onPressed: _loadLevel,
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
        title: Text(_level!.name),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          // Bookmark button
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
          ),
          // XP reward badge
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '+${_level!.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player (if available)
            if (_youtubeController != null) ...[
              YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppDesignSystem.primaryIndigo,
                progressColors: ProgressBarColors(
                  playedColor: AppDesignSystem.primaryIndigo,
                  handleColor: AppDesignSystem.primaryIndigo,
                ),
                onReady: () {
                  // print('Video player ready');
                },
                onEnded: (metadata) {
                  setState(() {
                    _videoCompleted = true;
                  });
                },
              ),
              // Video completion indicator
              if (_videoCompleted)
                Container(
                  color: AppDesignSystem.success.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppDesignSystem.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Video completed! Great job! 🎉',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppDesignSystem.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Level Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level Title and Description
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${_level!.levelNumber}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppDesignSystem.primaryIndigo,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _level!.name,
                              style: AppTextStyles.h2,
                            ),
                            Text(
                              '${_level!.estimatedMinutes} min read',
                              style: AppTextStyles.caption.copyWith(
                                color: AppDesignSystem.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Content (Markdown) - MOVED UP
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
                    child: MarkdownBody(
                      data: _level!.content,
                      styleSheet: MarkdownStyleSheet(
                        h1: AppTextStyles.h1,
                        h2: AppTextStyles.h2,
                        h3: AppTextStyles.h3,
                        p: AppTextStyles.bodyMedium,
                        listBullet: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Key Points - MOVED TO END
                  if (_level!.keyPoints.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: AppDesignSystem.primaryIndigo,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Key Takeaways',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppDesignSystem.primaryIndigo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ..._level!.keyPoints.map((point) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 28,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Take Quiz Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LevelQuizScreen(
                              level: _level!,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.primaryIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.quiz),
                          const SizedBox(width: 8),
                          Text(
                            'Take Quiz (${_level!.quiz.length} Questions)',
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
}

