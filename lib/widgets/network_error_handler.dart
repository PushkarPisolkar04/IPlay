import 'package:flutter/material.dart';

/// Widget for displaying network error messages with retry functionality
/// Provides user-friendly error messages and options to retry or view cached data
class NetworkErrorHandler extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool showCachedDataOption;
  final VoidCallback? onViewCachedData;
  final IconData? icon;

  const NetworkErrorHandler({
    super.key,
    required this.message,
    required this.onRetry,
    this.showCachedDataOption = false,
    this.onViewCachedData,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (showCachedDataOption && onViewCachedData != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onViewCachedData,
                icon: const Icon(Icons.storage),
                label: const Text('View Cached Data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error banner for showing network errors at the top of screens
class NetworkErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const NetworkErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.orange[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange[800],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Colors.orange[800],
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Snackbar helper for showing network error messages
class NetworkErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static void showOffline(BuildContext context) {
    show(
      context,
      message: 'You\'re offline. Some features may be unavailable.',
      duration: const Duration(seconds: 5),
    );
  }

  static void showOnline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 12),
            const Text('You\'re back online!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Helper class for common network error messages
class NetworkErrorMessages {
  static const String noConnection = 
      'No internet connection. Please check your network settings.';
  
  static const String timeout = 
      'Request timed out. Please check your connection and try again.';
  
  static const String serverError = 
      'Server error occurred. Please try again later.';
  
  static const String unknownError = 
      'An unexpected error occurred. Please try again.';
  
  static const String slowConnection = 
      'Your connection is slow. This may take a while.';
  
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return noConnection;
    } else if (errorString.contains('timeout')) {
      return timeout;
    } else if (errorString.contains('500') || 
               errorString.contains('502') ||
               errorString.contains('503')) {
      return serverError;
    } else {
      return unknownError;
    }
  }
}
