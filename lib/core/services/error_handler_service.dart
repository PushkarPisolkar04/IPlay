import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error handling service
class ErrorHandlerService {
  /// Handle and format errors for user display
  static String handleError(dynamic error, {String? context}) {
    if (kDebugMode) {
      print('Error in $context: $error');
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _handleAuthError(error);
    }

    // Firestore errors
    if (error is FirebaseException) {
      return _handleFirestoreError(error);
    }

    // File operation errors
    if (error.toString().contains('FileSystemException')) {
      return 'File operation failed. Please check storage permissions.';
    }

    if (error.toString().contains('No space left')) {
      return 'Insufficient storage space. Please free up some space and try again.';
    }

    // Permission errors
    if (error.toString().contains('permission') ||
        error.toString().contains('Permission')) {
      return 'Permission denied. Please grant necessary permissions in settings.';
    }

    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle Firebase Auth errors
  static String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${error.message ?? "Unknown error"}';
    }
  }

  /// Handle Firestore errors
  static String _handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'Requested data not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'failed-precondition':
        return 'Operation cannot be performed in current state.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data range.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      default:
        return 'Database error: ${error.message ?? "Unknown error"}';
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  /// Check if error is permission-related
  static bool isPermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
        (error is FirebaseException && error.code == 'permission-denied');
  }

  /// Check if error requires authentication
  static bool requiresAuth(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unauthenticated' ||
          error.code == 'permission-denied';
    }
    return false;
  }

  /// Log error for debugging (can be extended to crash reporting)
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (kDebugMode) {
      print('=== ERROR LOG ===');
      print('Context: $context');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
      if (additionalInfo != null) {
        print('Additional info: $additionalInfo');
      }
      print('================');
    }

    // TODO: Add crash reporting service (e.g., Firebase Crashlytics)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
