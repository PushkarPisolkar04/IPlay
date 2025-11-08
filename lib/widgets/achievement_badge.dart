import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../utils/accessibility_helper.dart';

/// AchievementBadge - Displays badge with locked/unlocked state
/// Shows unlock date if unlocked, grayscale when locked
class AchievementBadge extends StatelessWidget {
  final String name;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String? description;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.name,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = AccessibilityHelper.badgeLabel(
      name,
      unlocked: unlocked,
    );

    return Semantics(
      label: semanticLabel,
      hint: description,
      button: onTap != null,
      enabled: onTap != null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppDesignSystem.borderRadiusMD,
            child: Container(
          decoration: AppDesignSystem.solidDecoration(
            color: AppDesignSystem.backgroundWhite,
            borderRadius: AppDesignSystem.borderRadiusMD,
            boxShadow: unlocked ? AppDesignSystem.shadowMD : AppDesignSystem.shadowSM,
          ),
          padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: unlocked
                      ? AppDesignSystem.gradientPrimary
                      : null,
                  color: unlocked ? null : AppDesignSystem.backgroundGrey,
                  shape: BoxShape.circle,
                  boxShadow: unlocked ? AppDesignSystem.shadowMD : null,
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: unlocked
                          ? AppDesignSystem.backgroundWhite
                          : AppDesignSystem.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingMD),
              
              // Badge name
              Text(
                name,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: unlocked
                      ? AppDesignSystem.textPrimary
                      : AppDesignSystem.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Unlock date or locked status
              const SizedBox(height: AppDesignSystem.spacingXS),
              if (unlocked && unlockedAt != null)
                Text(
                  _formatDate(unlockedAt!),
                  style: AppDesignSystem.caption.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (!unlocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: AppDesignSystem.textTertiary,
                    ),
                    const SizedBox(width: AppDesignSystem.spacingXS),
                    Text(
                      'Locked',
                      style: AppDesignSystem.caption.copyWith(
                        color: AppDesignSystem.textTertiary,
                      ),
                    ),
                  ],
                ),
              
              // Description (optional)
              if (description != null && unlocked) ...[
                const SizedBox(height: AppDesignSystem.spacingSM),
                Text(
                  description!,
                  style: AppDesignSystem.caption.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
