import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// LevelCard - Displays level with lock icon if locked
/// Shows checkmark if completed, difficulty badge and XP reward
class LevelCard extends StatelessWidget {
  final int levelNumber;
  final String levelName;
  final String difficulty; // Basic, Intermediate, Advanced
  final int xpReward;
  final int estimatedMinutes;
  final bool isLocked;
  final bool isCompleted;
  final int? score; // Quiz score if completed
  final VoidCallback? onStart;
  final Color? accentColor;

  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.levelName,
    required this.difficulty,
    required this.xpReward,
    required this.estimatedMinutes,
    this.isLocked = false,
    this.isCompleted = false,
    this.score,
    this.onStart,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? AppDesignSystem.primaryIndigo;
    final canInteract = !isLocked && onStart != null;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canInteract ? onStart : null,
          borderRadius: AppDesignSystem.borderRadiusMD,
          child: Container(
            decoration: AppDesignSystem.solidDecoration(
              color: AppDesignSystem.backgroundWhite,
              borderRadius: AppDesignSystem.borderRadiusMD,
              boxShadow: isLocked ? null : AppDesignSystem.shadowSM,
              border: isCompleted
                  ? Border.all(
                      color: AppDesignSystem.success.withValues(alpha: 0.3),
                      width: 2,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
            child: Row(
              children: [
                // Level number or status icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(effectiveColor).withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusMD,
                  ),
                  child: Center(
                    child: _buildStatusIcon(effectiveColor),
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingMD),
                
                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level name
                      Text(
                        'Level $levelNumber: $levelName',
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? AppDesignSystem.textTertiary
                              : AppDesignSystem.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDesignSystem.spacingXS),
                      
                      // Metadata
                      Wrap(
                        spacing: AppDesignSystem.spacingSM,
                        runSpacing: AppDesignSystem.spacingXS,
                        children: [
                          _buildMetadataChip(
                            label: difficulty,
                            color: _getDifficultyColor(),
                          ),
                          _buildMetadataChip(
                            icon: Icons.stars,
                            label: '$xpReward XP',
                            color: AppDesignSystem.primaryAmber,
                          ),
                          _buildMetadataChip(
                            icon: Icons.access_time,
                            label: '$estimatedMinutes min',
                            color: AppDesignSystem.secondaryBlue,
                          ),
                        ],
                      ),
                      
                      // Score if completed
                      if (isCompleted && score != null) ...[
                        const SizedBox(height: AppDesignSystem.spacingXS),
                        Text(
                          'Score: $score%',
                          style: AppDesignSystem.caption.copyWith(
                            color: AppDesignSystem.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow or lock icon
                Icon(
                  isLocked
                      ? Icons.lock
                      : isCompleted
                          ? Icons.check_circle
                          : Icons.arrow_forward_ios,
                  color: isLocked
                      ? AppDesignSystem.textTertiary
                      : isCompleted
                          ? AppDesignSystem.success
                          : effectiveColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(Color color) {
    if (isLocked) {
      return Icon(
        Icons.lock,
        color: AppDesignSystem.textTertiary,
        size: 24,
      );
    } else if (isCompleted) {
      return Icon(
        Icons.check_circle,
        color: AppDesignSystem.success,
        size: 24,
      );
    } else {
      return Text(
        '$levelNumber',
        style: AppDesignSystem.h6.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Color _getStatusColor(Color defaultColor) {
    if (isLocked) return AppDesignSystem.textTertiary;
    if (isCompleted) return AppDesignSystem.success;
    return defaultColor;
  }

  Widget _buildMetadataChip({
    IconData? icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingSM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 10,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppDesignSystem.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'basic':
        return AppDesignSystem.success;
      case 'intermediate':
        return AppDesignSystem.warning;
      case 'advanced':
        return AppDesignSystem.error;
      default:
        return AppDesignSystem.textSecondary;
    }
  }
}
