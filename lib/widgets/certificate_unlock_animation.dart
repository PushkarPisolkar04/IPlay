import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/design/app_design_system.dart';

/// Full-screen celebration animation for certificate unlock
class CertificateUnlockAnimation extends StatefulWidget {
  final String realmName;
  final String certificateNumber;
  final VoidCallback onDismiss;

  const CertificateUnlockAnimation({
    super.key,
    required this.realmName,
    required this.certificateNumber,
    required this.onDismiss,
  });

  @override
  State<CertificateUnlockAnimation> createState() =>
      _CertificateUnlockAnimationState();
}

class _CertificateUnlockAnimationState extends State<CertificateUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation for certificate
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start animations
    _controller.forward();
    _confettiController.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.yellow,
                Colors.blue,
                Colors.purple,
                Colors.green,
              ],
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Certificate icon with scale animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.3),
                              Colors.amber.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.workspace_premium,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Certificate unlocked text with fade
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            '🎓 Certificate Earned!',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              shadows: [
                                Shadow(
                                  color: Colors.amber,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Realm name
                          Text(
                            widget.realmName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Congratulations message
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Congratulations on completing all levels!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Certificate number
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.amber,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Certificate Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.certificateNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Action buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // View Certificate button
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onDismiss();
                              // Navigate to certificates screen
                              Navigator.pushNamed(context, '/certificates');
                            },
                            icon: const Icon(Icons.description),
                            label: const Text('View Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Continue button
                          ElevatedButton(
                            onPressed: widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Close button
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
