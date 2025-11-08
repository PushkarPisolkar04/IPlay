import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';

/// Clean progress bar
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showPercentage;
  
  const ProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.showPercentage = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final progressValue = progress.clamp(0.0, 1.0);
    
    return Row(
      children: [
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppDesignSystem.backgroundGrey,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: FractionallySizedBox(
              widthFactor: progressValue,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? AppDesignSystem.primaryIndigo,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 8),
          Text(
            '${(progressValue * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Circular progress indicator with percentage
class CircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final double size;
  final double strokeWidth;
  final Widget? child;
  
  const CircularProgress({
    super.key,
    required this.progress,
    this.color,
    this.size = 80.0,
    this.strokeWidth = 8.0,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: AppDesignSystem.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppDesignSystem.primaryIndigo,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

