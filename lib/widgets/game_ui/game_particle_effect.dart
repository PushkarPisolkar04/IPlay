import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/object_pool.dart';

/// Particle type enum
enum ParticleType {
  confetti,
  sparkle,
  explosion,
}

/// Global particle pool for reusing particle objects
final _particlePool = ParticlePool(initialSize: 50, maxSize: 200);

/// Particle effect widget for game feedback
/// Supports confetti, sparkles, and explosions
class GameParticleEffect extends StatefulWidget {
  final int particleCount;
  final ParticleType particleType;
  final Color? color;
  final Duration duration;
  final VoidCallback? onComplete;

  const GameParticleEffect({
    super.key,
    required this.particleCount,
    required this.particleType,
    this.color,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<GameParticleEffect> createState() => _GameParticleEffectState();
}

class _GameParticleEffectState extends State<GameParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _generateParticles();
    _controller.forward();
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      switch (widget.particleType) {
        case ParticleType.confetti:
          return _createConfettiParticle();
        case ParticleType.sparkle:
          return _createSparkleParticle();
        case ParticleType.explosion:
          return _createExplosionParticle();
      }
    });
  }

  Particle _createConfettiParticle() {
    return Particle(
      x: _random.nextDouble(),
      y: -0.1,
      color: _getRandomColor(),
      size: _random.nextDouble() * 8 + 4,
      velocityX: (_random.nextDouble() - 0.5) * 2,
      velocityY: _random.nextDouble() * 2 + 1,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      shape: ParticleShape.values[_random.nextInt(ParticleShape.values.length)],
    );
  }

  Particle _createSparkleParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 0.5 + 0.5;
    return Particle(
      x: 0.5,
      y: 0.5,
      color: widget.color ?? Colors.yellow,
      size: _random.nextDouble() * 6 + 3,
      velocityX: cos(angle) * speed,
      velocityY: sin(angle) * speed,
      rotation: 0,
      rotationSpeed: _random.nextDouble() * 2,
      shape: ParticleShape.star,
    );
  }

  Particle _createExplosionParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 1.5 + 0.5;
    return Particle(
      x: 0.5,
      y: 0.5,
      color: widget.color ?? Colors.red,
      size: _random.nextDouble() * 10 + 5,
      velocityX: cos(angle) * speed,
      velocityY: sin(angle) * speed,
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 3,
      shape: ParticleShape.circle,
    );
  }

  Color _getRandomColor() {
    if (widget.color != null) return widget.color!;
    
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            particleType: widget.particleType,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Particle shape enum
enum ParticleShape {
  square,
  circle,
  star,
  triangle,
}

/// Particle data class
class Particle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double velocityX;
  final double velocityY;
  final double rotation;
  final double rotationSpeed;
  final ParticleShape shape;

  Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });
}

/// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final ParticleType particleType;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.particleType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: _getAlpha())
        ..style = PaintingStyle.fill;

      final x = _calculateX(particle, size);
      final y = _calculateY(particle, size);
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (particle.shape) {
        case ParticleShape.square:
          _drawSquare(canvas, paint, particle.size);
          break;
        case ParticleShape.circle:
          _drawCircle(canvas, paint, particle.size);
          break;
        case ParticleShape.star:
          _drawStar(canvas, paint, particle.size);
          break;
        case ParticleShape.triangle:
          _drawTriangle(canvas, paint, particle.size);
          break;
      }

      canvas.restore();
    }
  }

  double _calculateX(Particle particle, Size size) {
    switch (particleType) {
      case ParticleType.confetti:
        return size.width * particle.x + particle.velocityX * progress * 100;
      case ParticleType.sparkle:
      case ParticleType.explosion:
        return size.width * particle.x + particle.velocityX * progress * size.width * 0.5;
    }
  }

  double _calculateY(Particle particle, Size size) {
    switch (particleType) {
      case ParticleType.confetti:
        return size.height * particle.y + particle.velocityY * progress * size.height;
      case ParticleType.sparkle:
      case ParticleType.explosion:
        return size.height * particle.y + particle.velocityY * progress * size.height * 0.5;
    }
  }

  double _getAlpha() {
    switch (particleType) {
      case ParticleType.confetti:
        return 1.0 - progress;
      case ParticleType.sparkle:
        return progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
      case ParticleType.explosion:
        return 1.0 - progress;
    }
  }

  void _drawSquare(Canvas canvas, Paint paint, double size) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size,
        height: size,
      ),
      paint,
    );
  }

  void _drawCircle(Canvas canvas, Paint paint, double size) {
    canvas.drawCircle(Offset.zero, size / 2, paint);
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;
    final points = 5;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, Paint paint, double size) {
    final path = Path();
    path.moveTo(0, -size / 2);
    path.lineTo(size / 2, size / 2);
    path.lineTo(-size / 2, size / 2);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
