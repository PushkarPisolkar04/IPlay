import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class BadgeUnlockAnimation extends StatefulWidget {
  final String badgeName;
  final String badgeIcon;
  final VoidCallback onComplete;

  const BadgeUnlockAnimation({
    Key? key,
    required this.badgeName,
    required this.badgeIcon,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<BadgeUnlockAnimation> createState() => _BadgeUnlockAnimationState();
}

class _BadgeUnlockAnimationState extends State<BadgeUnlockAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _controller.forward();
    _confettiController.play();
    Future.delayed(const Duration(seconds: 3), widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text('Badge Unlocked!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.badgeName, style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }
}

