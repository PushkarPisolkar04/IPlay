import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';

/// GameTimer widget with circular progress and color changes
/// Shows countdown timer with visual feedback
class GameTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onComplete;
  final VoidCallback? onTick;
  final Color? color;
  final double size;
  final bool autoStart;

  const GameTimer({
    super.key,
    required this.totalSeconds,
    this.onComplete,
    this.onTick,
    this.color,
    this.size = 60.0,
    this.autoStart = true,
  });

  @override
  State<GameTimer> createState() => GameTimerState();
}

class GameTimerState extends State<GameTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.autoStart) {
      start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        widget.onTick?.call();

        // Pulse animation when time is running low
        if (_remainingSeconds <= 10) {
          _controller.forward(from: 0);
        }

        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _isRunning = false;
          widget.onComplete?.call();
        }
      });
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  void resume() {
    if (!_isRunning && _remainingSeconds > 0) {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.totalSeconds;
      _isRunning = false;
    });
  }

  void addTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
    });
  }

  Color _getTimerColor() {
    final baseColor = widget.color ?? GameColors.quizMaster;
    final progress = _remainingSeconds / widget.totalSeconds;

    if (progress > 0.5) {
      return baseColor;
    } else if (progress > 0.25) {
      return GameColors.warning;
    } else {
      return GameColors.incorrect;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.totalSeconds;
    final timerColor = _getTimerColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timerColor.withValues(alpha: 0.2),
                  ),
                ),
                // Progress circle
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
                // Time text
                Text(
                  _formatTime(_remainingSeconds),
                  style: AppDesignSystem.h6.copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.size * 0.25,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return secs.toString();
  }
}
