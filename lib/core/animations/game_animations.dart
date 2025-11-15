import 'package:flutter/material.dart';

/// Game animation constants and utilities
/// Provides consistent animation durations and curves
class GameAnimations {
  // ============================================================================
  // DURATION CONSTANTS
  // ============================================================================
  
  /// Quick transition (200ms)
  static const Duration quickTransition = Duration(milliseconds: 200);
  
  /// Normal transition (300ms)
  static const Duration normalTransition = Duration(milliseconds: 300);
  
  /// Slow transition (500ms)
  static const Duration slowTransition = Duration(milliseconds: 500);
  
  /// Very slow transition (800ms)
  static const Duration verySlowTransition = Duration(milliseconds: 800);
  
  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================
  
  /// Bounce-in animation (elasticOut curve)
  static const Curve bounceIn = Curves.elasticOut;
  
  /// Smooth in-out animation
  static const Curve smoothInOut = Curves.easeInOut;
  
  /// Quick snap animation
  static const Curve quickSnap = Curves.easeOut;
  
  /// Ease in animation
  static const Curve easeIn = Curves.easeIn;
  
  /// Ease out animation
  static const Curve easeOut = Curves.easeOut;
  
  /// Bounce animation
  static const Curve bounce = Curves.bounceOut;
  
  // ============================================================================
  // PARTICLE EFFECT CONSTANTS
  // ============================================================================
  
  /// Number of confetti particles for correct answers
  static const int confettiParticles = 50;
  
  /// Number of sparkle particles for achievements
  static const int sparkleParticles = 20;
  
  /// Number of explosion particles for incorrect answers
  static const int explosionParticles = 30;
  
  // ============================================================================
  // ANIMATION BUILDERS
  // ============================================================================
  
  /// Create a fade transition
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
  
  /// Create a scale transition with bounce
  static Widget bounceInTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: bounceIn,
    );
    return ScaleTransition(
      scale: curvedAnimation,
      child: child,
    );
  }
  
  /// Create a slide transition from bottom
  static Widget slideFromBottomTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: smoothInOut,
    ));
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
  
  /// Create a slide transition from right
  static Widget slideFromRightTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: smoothInOut,
    ));
    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
  
  /// Create a combined fade and scale transition
  static Widget fadeAndScaleTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}

/// Animated widget that bounces in on mount
class BounceInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const BounceInWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = GameAnimations.slowTransition,
  });

  @override
  State<BounceInWidget> createState() => _BounceInWidgetState();
}

class _BounceInWidgetState extends State<BounceInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: GameAnimations.bounceIn,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Animated widget that pulses continuously
class PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// Animated widget with glow effect for selected elements
class GlowWidget extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool isGlowing;
  final double glowRadius;

  const GlowWidget({
    super.key,
    required this.child,
    required this.glowColor,
    this.isGlowing = true,
    this.glowRadius = 20.0,
  });

  @override
  State<GlowWidget> createState() => _GlowWidgetState();
}

class _GlowWidgetState extends State<GlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isGlowing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _animation.value),
                blurRadius: widget.glowRadius,
                spreadRadius: widget.glowRadius / 4,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shake animation widget for incorrect answers
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback? onComplete;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.shake,
    this.onComplete,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}
