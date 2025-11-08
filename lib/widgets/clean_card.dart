import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_spacing.dart';

/// Clean white card with subtle shadow and border
class CleanCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Border? border;
  
  const CleanCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.border,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppDesignSystem.backgroundLight,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        boxShadow: AppDesignSystem.shadowMD,
        border: border ?? Border.all(
          color: AppDesignSystem.backgroundGrey,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Colored card for featured content (no border)
class ColoredCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  
  const ColoredCard({
    super.key,
    required this.child,
    required this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        boxShadow: AppDesignSystem.shadowMD,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

