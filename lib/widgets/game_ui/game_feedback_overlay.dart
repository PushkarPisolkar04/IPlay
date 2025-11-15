import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';
import '../game_ui/game_particle_effect.dart';
import '../../utils/haptic_feedback_util.dart';

/// FeedbackOverlay widget with particle effects
/// Shows visual feedback for correct/incorrect answers
class GameFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String message;
  final VoidCallback? onComplete;
  final Duration duration;
  final bool showParticles;

  const GameFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.message,
    this.onComplete,
    this.duration = const Duration(seconds: 2),
    this.showParticles = true,
  });

  @override
  State<GameFeedbackOverlay> createState() => _GameFeedbackOverlayState();
}

class _GameFeedbackOverlayState extends State<GameFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    // Trigger haptic feedback
    if (widget.isCorrect) {
      HapticFeedbackUtil.correctAnswer();
    } else {
      HapticFeedbackUtil.incorrectAnswer();
    }

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCorrect ? GameColors.correct : GameColors.incorrect;
    final icon = widget.isCorrect ? Icons.check_circle : Icons.cancel;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent background
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
              );
            },
          ),

          // Particle effects
          if (widget.showParticles && widget.isCorrect)
            GameParticleEffect(
              particleCount: 50,
              particleType: ParticleType.confetti,
              color: color,
            ),

          if (widget.showParticles && !widget.isCorrect)
            GameParticleEffect(
              particleCount: 20,
              particleType: ParticleType.explosion,
              color: color,
            ),

          // Feedback message
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spacingXL,
                      ),
                      padding: const EdgeInsets.all(AppDesignSystem.spacingXL),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.backgroundWhite,
                        borderRadius: AppDesignSystem.borderRadiusXL,
                        boxShadow: AppDesignSystem.shadowXL,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 64,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: AppDesignSystem.spacingLG),

                          // Message
                          Text(
                            widget.message,
                            style: AppDesignSystem.h4.copyWith(
                              color: AppDesignSystem.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
