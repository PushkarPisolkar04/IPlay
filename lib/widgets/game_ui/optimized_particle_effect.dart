import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/object_pool.dart';
import '../../services/performance_monitor_service.dart';

/// Optimized particle effect widget using object pooling
/// Automatically reduces particle count on low-end devices
class OptimizedParticleEffect extends StatefulWidget {
  final int maxParticleCount;
  final ParticleEffectType effectType;
  final Color? color;
  final Duration duration;
  final VoidCallback? onComplete;

  const OptimizedParticleEffect({
    super.key,
    required this.maxParticleCount,
    required this.effectType,
    this.color,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<OptimizedParticleEffect> createState() => _OptimizedParticleEffectState();
}

class _OptimizedParticleEffectState extends State<OptimizedParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<PooledParticle> _particles;
  final _particlePool = ParticlePool();
  final _performanceMonitor = PerformanceMonitorService();
  final Random _random = Random();
  int _actualParticleCount = 0;

  @override
  void initState() {
    super.initState();
    
    // Adjust particle count based on performance level
    _actualParticleCount = _getAdjustedParticleCount();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        _releaseParticles();
      }
    });

    _generateParticles();
    _controller.forward();
  }

  int _getAdjustedParticleCount() {
    final level = _performanceMonitor.performanceLevel;
    
    switch (level) {
      case PerformanceLevel.high:
        return widget.maxParticleCount;
      case PerformanceLevel.medium:
        return (widget.maxParticleCount * 0.6).round();
      case PerformanceLevel.low:
        return (widget.maxParticleCount * 0.3).round();
    }
  }

  void _generateParticles() {
    _particles = [];
    
    for (int i = 0; i < _actualParticleCount; i++) {
      final particle = _particlePool.acquire();
      
      switch (widget.effectType) {
        case ParticleEffectType.confetti:
          _initConfettiParticle(particle);
          break;
        case ParticleEffectType.sparkle:
          _initSparkleParticle(particle);
          break;
        case ParticleEffectType.explosion:
          _initExplosionParticle(particle);
          break;
      }
      
      _particles.add(particle);
    }
  }

  void _initConfettiParticle(PooledParticle particle) {
    particle.x = _random.nextDouble();
    particle.y = -0.1;
    particle.velocityX = (_random.nextDouble() - 0.5) * 2;
    particle.velocityY = _random.nextDouble() * 2 + 1;
    particle.size = _random.nextDouble() * 8 + 4;
    particle.rotation = _random.nextDouble() * 2 * pi;
    particle.rotationSpeed = (_random.nextDouble() - 0.5) * 4;
    particle.colorValue = _getRandomColor().value;
    particle.shape = _random.nextInt(4);
    particle.life = 1.0;
  }

  void _initSparkleParticle(PooledParticle particle) {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 0.5 + 0.5;
    
    particle.x = 0.5;
    particle.y = 0.5;
    particle.velocityX = cos(angle) * speed;
    particle.velocityY = sin(angle) * speed;
    particle.size = _random.nextDouble() * 6 + 3;
    particle.rotation = 0;
    particle.rotationSpeed = _random.nextDouble() * 2;
    particle.colorValue = (widget.color ?? Colors.yellow).value;
    particle.shape = 2; // star
    particle.life = 1.0;
  }

  void _initExplosionParticle(PooledParticle particle) {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = _random.nextDouble() * 1.5 + 0.5;
    
    particle.x = 0.5;
    particle.y = 0.5;
    particle.velocityX = cos(angle) * speed;
    particle.velocityY = sin(angle) * speed;
    particle.size = _random.nextDouble() * 10 + 5;
    particle.rotation = _random.nextDouble() * 2 * pi;
    particle.rotationSpeed = (_random.nextDouble() - 0.5) * 3;
    particle.colorValue = (widget.color ?? Colors.red).value;
    particle.shape = 0; // circle
    particle.life = 1.0;
  }

  Color _getRandomColor() {
    if (widget.color != null) return widget.color!;
    
    const colors = [
      Color(0xFFFF0000), // red
      Color(0xFF0000FF), // blue
      Color(0xFF00FF00), // green
      Color(0xFFFFFF00), // yellow
      Color(0xFFFF8800), // orange
      Color(0xFF8800FF), // purple
      Color(0xFFFF0088), // pink
      Color(0xFF00FFFF), // cyan
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _releaseParticles() {
    _particlePool.releaseAll(_particles);
    _particles.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _releaseParticles();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: OptimizedParticlePainter(
            particles: _particles,
            progress: _controller.value,
            effectType: widget.effectType,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Particle effect type enum
enum ParticleEffectType {
  confetti,
  sparkle,
  explosion,
}

/// Optimized particle painter using pooled particles
class OptimizedParticlePainter extends CustomPainter {
  final List<PooledParticle> particles;
  final double progress;
  final ParticleEffectType effectType;

  OptimizedParticlePainter({
    required this.particles,
    required this.progress,
    required this.effectType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = Color(particle.colorValue).withValues(alpha: _getAlpha(particle))
        ..style = PaintingStyle.fill;

      final x = _calculateX(particle, size);
      final y = _calculateY(particle, size);
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      _drawParticle(canvas, paint, particle);

      canvas.restore();
    }
  }

  double _calculateX(PooledParticle particle, Size size) {
    switch (effectType) {
      case ParticleEffectType.confetti:
        return size.width * particle.x + particle.velocityX * progress * 100;
      case ParticleEffectType.sparkle:
      case ParticleEffectType.explosion:
        return size.width * particle.x + particle.velocityX * progress * size.width * 0.5;
    }
  }

  double _calculateY(PooledParticle particle, Size size) {
    switch (effectType) {
      case ParticleEffectType.confetti:
        return size.height * particle.y + particle.velocityY * progress * size.height;
      case ParticleEffectType.sparkle:
      case ParticleEffectType.explosion:
        return size.height * particle.y + particle.velocityY * progress * size.height * 0.5;
    }
  }

  double _getAlpha(PooledParticle particle) {
    switch (effectType) {
      case ParticleEffectType.confetti:
        return 1.0 - progress;
      case ParticleEffectType.sparkle:
        return progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;
      case ParticleEffectType.explosion:
        return 1.0 - progress;
    }
  }

  void _drawParticle(Canvas canvas, Paint paint, PooledParticle particle) {
    switch (particle.shape) {
      case 0: // circle
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        break;
      case 1: // square
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          paint,
        );
        break;
      case 2: // star
        _drawStar(canvas, paint, particle.size);
        break;
      case 3: // triangle
        _drawTriangle(canvas, paint, particle.size);
        break;
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;
    const points = 5;

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
  bool shouldRepaint(OptimizedParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
