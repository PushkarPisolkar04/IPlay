import 'dart:collection';

/// Generic object pool for reusing objects to reduce GC pressure
class ObjectPool<T> {
  final T Function() _factory;
  final void Function(T)? _reset;
  final int _maxSize;
  final Queue<T> _pool = Queue<T>();

  ObjectPool({
    required T Function() factory,
    void Function(T)? reset,
    int initialSize = 0,
    int maxSize = 100,
  })  : _factory = factory,
        _reset = reset,
        _maxSize = maxSize {
    for (int i = 0; i < initialSize; i++) {
      _pool.add(_factory());
    }
  }

  /// Acquire an object from the pool or create a new one
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }
    return _factory();
  }

  /// Release an object back to the pool
  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
  }

  /// Release all objects back to the pool
  void releaseAll(List<T> objects) {
    for (final object in objects) {
      release(object);
    }
  }

  /// Clear the pool
  void clear() {
    _pool.clear();
  }

  /// Current pool size
  int get size => _pool.length;
}

/// Pooled particle class for particle effects
class PooledParticle {
  double x = 0;
  double y = 0;
  double velocityX = 0;
  double velocityY = 0;
  double size = 0;
  double rotation = 0;
  double rotationSpeed = 0;
  int colorValue = 0;
  int shape = 0;
  double life = 1.0;

  void reset() {
    x = 0;
    y = 0;
    velocityX = 0;
    velocityY = 0;
    size = 0;
    rotation = 0;
    rotationSpeed = 0;
    colorValue = 0;
    shape = 0;
    life = 1.0;
  }
}

/// Particle pool specifically for particle effects
class ParticlePool {
  final ObjectPool<PooledParticle> _pool;

  ParticlePool({int initialSize = 50, int maxSize = 200})
      : _pool = ObjectPool<PooledParticle>(
          factory: () => PooledParticle(),
          reset: (p) => p.reset(),
          initialSize: initialSize,
          maxSize: maxSize,
        );

  PooledParticle acquire() => _pool.acquire();

  void release(PooledParticle particle) => _pool.release(particle);

  void releaseAll(List<PooledParticle> particles) => _pool.releaseAll(particles);

  void clear() => _pool.clear();

  int get size => _pool.size;
}
