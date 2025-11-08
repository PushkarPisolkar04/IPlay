import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../utils/accessibility_helper.dart';

/// Animated XP Counter Widget
/// Shows XP with animation when value changes
class XPCounter extends StatefulWidget {
  final int xp;
  final Duration animationDuration;
  final TextStyle? textStyle;

  const XPCounter({
    super.key,
    required this.xp,
    this.animationDuration = const Duration(milliseconds: 800),
    this.textStyle,
  });

  @override
  State<XPCounter> createState() => _XPCounterState();
}

class _XPCounterState extends State<XPCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousXP = 0;

  @override
  void initState() {
    super.initState();
    _previousXP = widget.xp;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = IntTween(begin: widget.xp, end: widget.xp).animate(_controller);
  }

  @override
  void didUpdateWidget(XPCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xp != widget.xp) {
      // Animate from previous value to new value
      _animation = IntTween(
        begin: _previousXP,
        end: widget.xp,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0);
      _previousXP = widget.xp;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityHelper.xpLabel(widget.xp),
      value: '${widget.xp}',
      liveRegion: true, // Announce changes to screen readers
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ExcludeSemantics(
            child: Text(
              '${_animation.value}',
              style: widget.textStyle ?? AppDesignSystem.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignSystem.primaryAmber,
              ),
            ),
          );
        },
      ),
    );
  }
}
