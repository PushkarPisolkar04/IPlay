import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';

/// Enhanced GameCard widget with elevation, shadow, and rounded corners
/// Displays game information with vibrant colors and smooth animations
class EnhancedGameCard extends StatefulWidget {
  final String title;
  final String description;
  final String icon;
  final String gameType;
  final String difficulty;
  final String xpReward;
  final String timeEstimate;
  final bool isImplemented;
  final int? highScore;
  final VoidCallback? onPlay;

  const EnhancedGameCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gameType,
    required this.difficulty,
    required this.xpReward,
    required this.timeEstimate,
    this.isImplemented = true,
    this.highScore,
    this.onPlay,
  });

  @override
  State<EnhancedGameCard> createState() => _EnhancedGameCardState();
}

class _EnhancedGameCardState extends State<EnhancedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isImplemented) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gameColor = GameColors.getGameColor(widget.gameType);
    final gameGradient = GameColors.getGameGradient(widget.gameType);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isImplemented ? widget.onPlay : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundWhite,
                borderRadius: AppDesignSystem.borderRadiusLG,
                boxShadow: _isPressed
                    ? AppDesignSystem.shadowSM
                    : AppDesignSystem.shadowMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient and icon
                  Stack(
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: gameGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppDesignSystem.radiusLG),
                            topRight: Radius.circular(AppDesignSystem.radiusLG),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.icon,
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                      ),

                      // Coming Soon badge
                      if (!widget.isImplemented)
                        Positioned(
                          top: AppDesignSystem.spacingSM,
                          right: AppDesignSystem.spacingSM,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spacingSM,
                              vertical: AppDesignSystem.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.backgroundWhite,
                              borderRadius: AppDesignSystem.borderRadiusSM,
                              boxShadow: AppDesignSystem.shadowSM,
                            ),
                            child: Text(
                              'Coming Soon',
                              style: AppDesignSystem.caption.copyWith(
                                color: AppDesignSystem.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // High score badge
                      if (widget.isImplemented && widget.highScore != null)
                        Positioned(
                          top: AppDesignSystem.spacingSM,
                          right: AppDesignSystem.spacingSM,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spacingSM,
                              vertical: AppDesignSystem.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              gradient: GameColors.correctGradient,
                              borderRadius: AppDesignSystem.borderRadiusSM,
                              boxShadow: AppDesignSystem.shadowSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  size: 14,
                                  color: AppDesignSystem.backgroundWhite,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.highScore}',
                                  style: AppDesignSystem.caption.copyWith(
                                    color: AppDesignSystem.backgroundWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: AppDesignSystem.h6.copyWith(
                            color: AppDesignSystem.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingSM),

                        // Description
                        Text(
                          widget.description,
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingMD),

                        // Metadata chips
                        Wrap(
                          spacing: AppDesignSystem.spacingSM,
                          runSpacing: AppDesignSystem.spacingSM,
                          children: [
                            _buildMetadataChip(
                              icon: Icons.signal_cellular_alt,
                              label: widget.difficulty,
                              color: _getDifficultyColor(),
                            ),
                            _buildMetadataChip(
                              icon: Icons.stars,
                              label: widget.xpReward,
                              color: GameColors.giMapper,
                            ),
                            _buildMetadataChip(
                              icon: Icons.access_time,
                              label: widget.timeEstimate,
                              color: gameColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingSM,
        vertical: AppDesignSystem.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppDesignSystem.borderRadiusSM,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppDesignSystem.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy':
        return GameColors.correct;
      case 'medium':
        return GameColors.warning;
      case 'hard':
        return GameColors.incorrect;
      default:
        return AppDesignSystem.textSecondary;
    }
  }
}
