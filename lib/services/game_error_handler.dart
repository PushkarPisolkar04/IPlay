/// Error handler for game content loading
/// Provides retry mechanisms and error logging
class GameErrorHandler {
  /// Retry an operation with exponential backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Double the delay for next attempt
      }
    }

    throw Exception('Max retry attempts reached');
  }

  /// Log error with context
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    String? gameId,
  }) {
    final contextStr = context != null ? '[$context]' : '';
    final gameIdStr = gameId != null ? '[Game: $gameId]' : '';
    
    print('❌ Game Error $contextStr $gameIdStr: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
