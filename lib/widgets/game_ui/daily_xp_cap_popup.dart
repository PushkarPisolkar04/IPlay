import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated popup shown when daily XP cap is reached or close to being reached
class DailyXPCapPopup extends StatelessWidget {
  final int currentXP;
  final int dailyCap;
  final int cappedAmount;
  final bool isFullyCapped;

  const DailyXPCapPopup({
    super.key,
    required this.currentXP,
    required this.dailyCap,
    required this.cappedAmount,
    this.isFullyCapped = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXP / dailyCap).clamp(0.0, 1.0);
    final remainingXP = (dailyCap - currentXP).clamp(0, dailyCap);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isFullyCapped
                ? [Colors.red.shade600, Colors.orange.shade700]
                : [Colors.orange.shade600, Colors.amber.shade600],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isFullyCapped ? Colors.red : Colors.orange).withOpacity(
                0.4,
              ),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      isFullyCapped
                          ? Icons.hourglass_empty
                          : Icons.warning_amber,
                      size: 50,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                  )
                  .then()
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),

              const SizedBox(height: 24),

              // Title
              Text(
                    isFullyCapped
                        ? 'Daily XP Cap Reached! 🎯'
                        : 'Daily XP Cap Warning ⚠️',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 16),

              // Message
              Text(
                    isFullyCapped
                        ? 'You\'ve reached your daily XP limit of $dailyCap XP! Come back tomorrow to continue earning XP.'
                        : 'You\'re close to your daily XP cap! You earned ${currentXP - cappedAmount} XP ($cappedAmount XP was capped).',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 32),

              // Progress bar container
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // XP stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s XP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currentXP / $dailyCap',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$remainingXP XP',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Background
                              Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              // Progress fill
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().scaleX(
                                duration: 800.ms,
                                delay: 800.ms,
                                curve: Curves.easeOutCubic,
                                begin: 0,
                                end: progress,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

                        const SizedBox(height: 8),

                        // Percentage
                        Text(
                          '${(progress * 100).round()}% Complete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 500.ms),

              const SizedBox(height: 32),

              // Action button
              SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isFullyCapped
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1000.ms)
                  .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 1000.ms)
                  .scale(
                    duration: 300.ms,
                    delay: 1000.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show daily XP cap popup
Future<void> showDailyXPCapPopup(
  BuildContext context, {
  required int currentXP,
  required int dailyCap,
  required int cappedAmount,
  bool isFullyCapped = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => DailyXPCapPopup(
      currentXP: currentXP,
      dailyCap: dailyCap,
      cappedAmount: cappedAmount,
      isFullyCapped: isFullyCapped,
    ),
  );
}
