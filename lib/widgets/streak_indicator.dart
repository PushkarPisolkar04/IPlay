import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../utils/accessibility_helper.dart';

/// StreakIndicator - Displays flame icon with streak count
/// Animated flame when active, gray flame when inactive
class StreakIndicator extends StatefulWidget {
  final int currentStreak;
  final int maxStreak;
  final bool isActive; // Did user complete activity today?
  final TextStyle? textStyle;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    required this.maxStreak,
    required this.isActive,
    this.textStyle,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.6),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(StreakIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = widget.textStyle ??
        AppDesignSystem.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        );

    final semanticLabel = AccessibilityHelper.streakLabel(
      widget.currentStreak,
      isActive: widget.isActive,
    );

    return Semantics(
      label: semanticLabel,
      value: '${widget.currentStreak}',
      child: ExcludeSemantics(
        child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMD,
        vertical: AppDesignSystem.spacingSM,
      ),
      decoration: BoxDecoration(
        color: widget.isActive
            ? AppDesignSystem.primaryAmber.withValues(alpha: 0.1)
            : AppDesignSystem.backgroundGrey,
        borderRadius: AppDesignSystem.borderRadiusFull,
        border: Border.all(
          color: widget.isActive
              ? AppDesignSystem.primaryAmber.withValues(alpha: 0.3)
              : AppDesignSystem.textTertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated flame icon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? _scaleAnimation.value : 1.0,
                child: Opacity(
                  opacity: widget.isActive ? _opacityAnimation.value : 1.0,
                  child: Text(
                    '🔥',
                    style: TextStyle(
                      fontSize: 20,
                      color: widget.isActive ? null : Colors.grey,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppDesignSystem.spacingSM),
          
          // Streak count
          Text(
            '${widget.currentStreak}',
            style: effectiveTextStyle.copyWith(
              color: widget.isActive
                  ? AppDesignSystem.primaryAmber
                  : AppDesignSystem.textTertiary,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacingXS),
          Text(
            'Day Streak',
            style: effectiveTextStyle.copyWith(
              fontSize: effectiveTextStyle.fontSize! * 0.85,
              color: widget.isActive
                  ? AppDesignSystem.textSecondary
                  : AppDesignSystem.textTertiary,
            ),
          ),
          
          // Max streak indicator (if current equals max)
          if (widget.currentStreak == widget.maxStreak &&
              widget.currentStreak > 0) ...[
            const SizedBox(width: AppDesignSystem.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingXS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppDesignSystem.success.withValues(alpha: 0.1),
                borderRadius: AppDesignSystem.borderRadiusSM,
              ),
              child: Text(
                'Best!',
                style: AppDesignSystem.caption.copyWith(
                  color: AppDesignSystem.success,
                  fontWeight: FontWeight.w600,
                ),
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
