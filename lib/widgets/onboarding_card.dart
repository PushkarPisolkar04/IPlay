import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_spacing.dart';

/// Onboarding card component for tutorial content
/// Uses CleanCard as base with custom styling for onboarding screens
class OnboardingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? backgroundColor;
  
  const OnboardingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppDesignSystem.shadowLG,
        border: Border.all(
          color: AppDesignSystem.backgroundGrey,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding * 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (iconColor ?? AppDesignSystem.primaryIndigo).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: iconColor ?? AppDesignSystem.primaryIndigo,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Title
          Text(
            title,
            style: AppDesignSystem.h4.copyWith(
              color: AppDesignSystem.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Description
          Text(
            description,
            style: AppDesignSystem.bodyMedium.copyWith(
              color: AppDesignSystem.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
