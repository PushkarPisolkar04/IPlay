import 'dart:async';

/// Debouncer utility to delay execution of a function
/// Useful for reducing Firebase writes by batching rapid updates
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({required this.delay});
  
  /// Call the action after the delay
  /// If called again before delay expires, resets the timer
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }
  
  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility to limit execution frequency
/// Ensures function is called at most once per duration
class Throttler {
  final Duration duration;
  DateTime? _lastExecutionTime;
  
  Throttler({required this.duration});
  
  /// Execute action only if enough time has passed since last execution
  void call(void Function() action) {
    final now = DateTime.now();
    
    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
    }
  }
  
  /// Reset the throttler
  void reset() {
    _lastExecutionTime = null;
  }
}
