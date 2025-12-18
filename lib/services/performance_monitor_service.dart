import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance level enum for adaptive quality
enum PerformanceLevel { high, medium, low }

/// Service for monitoring app performance and adapting quality settings
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  PerformanceLevel _performanceLevel = PerformanceLevel.high;
  final List<double> _frameTimes = [];
  static const int _sampleSize = 60;
  Timer? _monitorTimer;
  bool _isMonitoring = false;

  /// Current performance level
  PerformanceLevel get performanceLevel => _performanceLevel;

  /// Start monitoring performance
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  DateTime? _lastFrameTime;

  void _onFrame(Duration timestamp) {
    if (!_isMonitoring) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      _frameTimes.add(frameTime);

      if (_frameTimes.length > _sampleSize) {
        _frameTimes.removeAt(0);
      }

      _updatePerformanceLevel();
    }
    _lastFrameTime = now;

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _updatePerformanceLevel() {
    if (_frameTimes.length < _sampleSize ~/ 2) return;

    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgFrameTime;

    if (fps >= 55) {
      _performanceLevel = PerformanceLevel.high;
    } else if (fps >= 40) {
      _performanceLevel = PerformanceLevel.medium;
    } else {
      _performanceLevel = PerformanceLevel.low;
    }

    if (kDebugMode) {
      // Uncomment for debugging
      // print('Performance: ${fps.toStringAsFixed(1)} FPS - Level: $_performanceLevel');
    }
  }

  /// Get recommended particle count based on performance
  int getRecommendedParticleCount(int maxCount) {
    switch (_performanceLevel) {
      case PerformanceLevel.high:
        return maxCount;
      case PerformanceLevel.medium:
        return (maxCount * 0.6).round();
      case PerformanceLevel.low:
        return (maxCount * 0.3).round();
    }
  }

  /// Check if high quality effects should be enabled
  bool get shouldUseHighQualityEffects =>
      _performanceLevel == PerformanceLevel.high;

  /// Check if animations should be reduced
  bool get shouldReduceAnimations => _performanceLevel == PerformanceLevel.low;

  /// Reset performance tracking
  void reset() {
    _frameTimes.clear();
    _performanceLevel = PerformanceLevel.high;
    _lastFrameTime = null;
  }
}
