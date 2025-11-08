import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// GameCard - Displays game with icon, description, and metadata
/// Shows "Coming Soon" badge if not implemented, high score if available
class GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final Color color;
  final String difficulty;
  final String xpReward;
  final String timeEstimate;
  final bool isImplemented;
  final int? highScore;
  final VoidCallback? onPlay;

  const GameCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.xpReward,
    required this.timeEstimate,
    this.isImplemented = true,
    this.highScore,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isImplemented ? onPlay : null,
        borderRadius: AppDesignSystem.borderRadiusLG,
        child: Container(
          decoration: AppDesignSystem.solidDecoration(
            color: AppDesignSystem.backgroundWhite,
            borderRadius: AppDesignSystem.borderRadiusLG,
            boxShadow: AppDesignSystem.shadowMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and coming soon badge
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDesignSystem.radiusLG),
                        topRight: Radius.circular(AppDesignSystem.radiusLG),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  
                  // Coming Soon badge
                  if (!isImplemented)
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
                  if (isImplemented && highScore != null)
                    Positioned(
                      top: AppDesignSystem.spacingSM,
                      right: AppDesignSystem.spacingSM,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacingSM,
                          vertical: AppDesignSystem.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primaryAmber,
                          borderRadius: AppDesignSystem.borderRadiusSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 12,
                              color: AppDesignSystem.backgroundWhite,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$highScore',
                              style: AppDesignSystem.caption.copyWith(
                                color: AppDesignSystem.backgroundWhite,
                                fontWeight: FontWeight.w600,
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
                      title,
                      style: AppDesignSystem.h6.copyWith(
                        color: AppDesignSystem.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingSM),
                    
                    // Description
                    Text(
                      description,
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingMD),
                    
                    // Metadata
                    Wrap(
                      spacing: AppDesignSystem.spacingSM,
                      runSpacing: AppDesignSystem.spacingSM,
                      children: [
                        _buildMetadataChip(
                          icon: Icons.signal_cellular_alt,
                          label: difficulty,
                          color: _getDifficultyColor(),
                        ),
                        _buildMetadataChip(
                          icon: Icons.stars,
                          label: xpReward,
                          color: AppDesignSystem.primaryAmber,
                        ),
                        _buildMetadataChip(
                          icon: Icons.access_time,
                          label: timeEstimate,
                          color: AppDesignSystem.secondaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
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
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppDesignSystem.success;
      case 'medium':
        return AppDesignSystem.warning;
      case 'hard':
        return AppDesignSystem.error;
      default:
        return AppDesignSystem.textSecondary;
    }
  }
}
