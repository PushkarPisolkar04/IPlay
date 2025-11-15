import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';

/// ScoreDisplay widget with animated counter and star icon
/// Shows current score with smooth number animations
class GameScoreDisplay extends StatefulWidget {
  final int score;
  final int? maxScore;
  final Color? color;
  final bool showStar;
  final double size;

  const GameScoreDisplay({
    super.key,
    required this.score,
    this.maxScore,
    this.color,
    this.showStar = true,
    this.size = 24.0,
  });

  @override
  State<GameScoreDisplay> createState() => _GameScoreDisplayState();
}

class _GameScoreDisplayState extends State<GameScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(
      begin: _previousScore.toDouble(),
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(GameScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _previousScore = oldWidget.score;
      _animation = Tween<double>(
        begin: _previousScore.toDouble(),
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
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
    final displayColor = widget.color ?? GameColors.quizMaster;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMD,
        vertical: AppDesignSystem.spacingSM,
      ),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusLG,
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showStar) ...[
            Icon(
              Icons.stars,
              color: displayColor,
              size: widget.size,
            ),
            const SizedBox(width: AppDesignSystem.spacingSM),
          ],
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Text(
                _animation.value.toInt().toString(),
                style: AppDesignSystem.h4.copyWith(
                  color: displayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size,
                ),
              );
            },
          ),
          if (widget.maxScore != null) ...[
            Text(
              ' / ${widget.maxScore}',
              style: AppDesignSystem.bodyMedium.copyWith(
                color: displayColor.withValues(alpha: 0.7),
                fontSize: widget.size * 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
