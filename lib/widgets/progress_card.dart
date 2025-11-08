import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// ProgressCard - Displays realm progress with visual progress bar
/// Shows completion percentage and XP earned
class ProgressCard extends StatelessWidget {
  final String realmName;
  final String realmIcon;
  final double progress; // 0.0 to 1.0
  final int levelsCompleted;
  final int totalLevels;
  final int xpEarned;
  final VoidCallback onContinue;
  final Color? accentColor;

  const ProgressCard({
    super.key,
    required this.realmName,
    required this.realmIcon,
    required this.progress,
    required this.levelsCompleted,
    required this.totalLevels,
    required this.xpEarned,
    required this.onContinue,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? AppDesignSystem.primaryIndigo;
    final percentage = (progress * 100).toInt();

    return Container(
      decoration: AppDesignSystem.solidDecoration(
        color: AppDesignSystem.backgroundWhite,
        borderRadius: AppDesignSystem.borderRadiusLG,
        boxShadow: AppDesignSystem.shadowMD,
      ),
      padding: const EdgeInsets.all(AppDesignSystem.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and realm name
          Row(
            children: [
              // Realm icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [effectiveColor, effectiveColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppDesignSystem.borderRadiusMD,
                ),
                child: Center(
                  child: Text(
                    realmIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingMD),
              
              // Realm name and level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      realmName,
                      style: AppDesignSystem.h5.copyWith(
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    Text(
                      'Level $levelsCompleted/$totalLevels • $percentage% Complete',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingLG),
          
          // Progress bar
          ClipRRect(
            borderRadius: AppDesignSystem.borderRadiusFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppDesignSystem.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingMD),
          
          // XP earned and continue button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // XP earned
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: AppDesignSystem.primaryAmber,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingXS),
                  Text(
                    '$xpEarned XP',
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: AppDesignSystem.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              // Continue button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onContinue,
                  borderRadius: AppDesignSystem.borderRadiusMD,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacingMD,
                      vertical: AppDesignSystem.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.1),
                      borderRadius: AppDesignSystem.borderRadiusMD,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: effectiveColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppDesignSystem.spacingXS),
                        Icon(
                          Icons.arrow_forward,
                          color: effectiveColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
