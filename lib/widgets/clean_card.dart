import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
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
    Key? key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.border,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        boxShadow: const [AppColors.cardShadow],
        border: border ?? Border.all(
          color: AppColors.border,
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
    Key? key,
    required this.child,
    required this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
        boxShadow: const [AppColors.cardShadow],
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

