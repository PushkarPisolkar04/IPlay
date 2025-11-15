import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';

/// ProgressBar widget for game progression
/// Shows visual progress with smooth animations
class GameProgressBar extends StatefulWidget {
  final int current;
  final int total;
  final Color? color;
  final double height;
  final bool showLabel;
  final String? customLabel;

  const GameProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.color,
    this.height = 8.0,
    this.showLabel = true,
    this.customLabel,
  });

  @override
  State<GameProgressBar> createState() => _GameProgressBarState();
}

class _GameProgressBarState extends State<GameProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.current / widget.total;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: _previousProgress,
      end: widget.current / widget.total,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(GameProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.total != widget.total) {
      _previousProgress = oldWidget.current / oldWidget.total;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.current / widget.total,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.color ?? GameColors.quizMaster;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.customLabel ?? 'Progress',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: AppDesignSystem.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.current} / ${widget.total}',
                style: AppDesignSystem.bodySmall.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingSM),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                // Progress
                FractionallySizedBox(
                  widthFactor: _animation.value.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
