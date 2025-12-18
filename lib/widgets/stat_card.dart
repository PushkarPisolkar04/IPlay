import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// StatCard - Displays a metric with icon, value, and optional subtitle
/// Used in dashboards for quick stats
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDesignSystem.borderRadiusMD,
        child: Container(
          decoration: AppDesignSystem.solidDecoration(
            color: AppDesignSystem.backgroundWhite,
            borderRadius: AppDesignSystem.borderRadiusMD,
            boxShadow: AppDesignSystem.shadowSM,
          ),
          padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingSM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadiusSM,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppDesignSystem.spacingMD),

              // Value
              Text(
                value,
                style: AppDesignSystem.h3.copyWith(
                  color: AppDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingXS),

              // Title
              Text(
                title,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),

              // Subtitle (optional)
              if (subtitle != null) ...[
                const SizedBox(height: AppDesignSystem.spacingXS),
                Text(
                  subtitle!,
                  style: AppDesignSystem.caption.copyWith(
                    color: AppDesignSystem.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
