import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget that displays an animated XP gain notification
class XPGainAnimation extends StatelessWidget {
  final int xpGained;
  final VoidCallback? onComplete;
  final bool isPerfectScore;
  final bool isFirstCompletion;

  const XPGainAnimation({
    super.key,
    required this.xpGained,
    this.onComplete,
    this.isPerfectScore = false,
    this.isFirstCompletion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700,
            Colors.orange.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star icon
          Icon(
            Icons.star,
            size: 64,
            color: Colors.white,
          )
              .animate(
                onComplete: (_) => onComplete?.call(),
              )
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
              )
              .then()
              .shimmer(
                duration: 1000.ms,
                color: Colors.white.withOpacity(0.5),
              ),

          const SizedBox(height: 16),

          // XP amount
          Text(
            '+$xpGained XP',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0, duration: 300.ms, delay: 200.ms),

          const SizedBox(height: 8),

          // Bonus badges
          if (isPerfectScore || isFirstCompletion) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (isPerfectScore)
                  _BonusBadge(
                    icon: Icons.emoji_events,
                    label: 'Perfect Score!',
                  ),
                if (isFirstCompletion)
                  _BonusBadge(
                    icon: Icons.new_releases,
                    label: 'First Time!',
                  ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 400.ms)
                .scale(
                  duration: 300.ms,
                  delay: 400.ms,
                  curve: Curves.elasticOut,
                ),
          ],
        ],
      ),
    );
  }
}

class _BonusBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BonusBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show XP gain dialog
Future<void> showXPGainDialog(
  BuildContext context, {
  required int xpGained,
  bool isPerfectScore = false,
  bool isFirstCompletion = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: XPGainAnimation(
        xpGained: xpGained,
        isPerfectScore: isPerfectScore,
        isFirstCompletion: isFirstCompletion,
        onComplete: () {
          // Auto-dismiss after animation completes
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        },
      ),
    ),
  );
}
