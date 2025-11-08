import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Firebase error handling utility
/// Maps Firebase error codes to user-friendly messages and provides logging
class FirebaseErrorHandler {
  /// Get user-friendly error message from Firebase exception
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      return _getFirebaseExceptionMessage(error);
    } else if (error is FirebaseAuthException) {
      return _getAuthExceptionMessage(error);
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle Firebase Firestore errors
  static String _getFirebaseExceptionMessage(FirebaseException error) {
    switch (error.code) {
      // Permission errors
      case 'permission-denied':
        return 'You don\'t have permission to access this data.';
      
      // Not found errors
      case 'not-found':
        return 'The requested data was not found.';
      
      // Already exists errors
      case 'already-exists':
        return 'This data already exists.';
      
      // Resource exhausted (quota exceeded)
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      
      // Cancelled
      case 'cancelled':
        return 'The operation was cancelled.';
      
      // Unknown error
      case 'unknown':
        return 'An unknown error occurred. Please try again.';
      
      // Invalid argument
      case 'invalid-argument':
        return 'Invalid data provided. Please check your input.';
      
      // Deadline exceeded (timeout)
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      
      // Unavailable (network issues)
      case 'unavailable':
        return 'Service temporarily unavailable. Please check your connection.';
      
      // Unauthenticated
      case 'unauthenticated':
        return 'You must be logged in to perform this action.';
      
      // Aborted
      case 'aborted':
        return 'Operation aborted. Please try again.';
      
      // Out of range
      case 'out-of-range':
        return 'Operation out of valid range.';
      
      // Unimplemented
      case 'unimplemented':
        return 'This feature is not yet implemented.';
      
      // Internal error
      case 'internal':
        return 'Internal server error. Please try again later.';
      
      // Data loss
      case 'data-loss':
        return 'Data loss or corruption detected.';
      
      default:
        return 'An error occurred: ${error.message ?? error.code}';
    }
  }

  /// Handle Firebase Authentication errors
  static String _getAuthExceptionMessage(FirebaseAuthException error) {
    switch (error.code) {
      // Email/Password errors
      case 'invalid-email':
        return 'The email address is not valid.';
      
      case 'user-disabled':
        return 'This account has been disabled.';
      
      case 'user-not-found':
        return 'No account found with this email.';
      
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      
      // Account management errors
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      
      // Network errors
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      
      // Token errors
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      
      // Session errors
      case 'session-expired':
        return 'Your session has expired. Please log in again.';
      
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      
      default:
        return 'Authentication error: ${error.message ?? error.code}';
    }
  }

  /// Handle Firebase Storage errors
  static String getStorageErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'storage/unauthorized':
        return 'You don\'t have permission to access this file.';
      
      case 'storage/canceled':
        return 'Upload cancelled.';
      
      case 'storage/unknown':
        return 'An unknown error occurred during upload.';
      
      case 'storage/object-not-found':
        return 'File not found.';
      
      case 'storage/bucket-not-found':
        return 'Storage bucket not found.';
      
      case 'storage/project-not-found':
        return 'Project not found.';
      
      case 'storage/quota-exceeded':
        return 'Storage quota exceeded.';
      
      case 'storage/unauthenticated':
        return 'You must be logged in to upload files.';
      
      case 'storage/retry-limit-exceeded':
        return 'Upload retry limit exceeded. Please try again.';
      
      case 'storage/invalid-checksum':
        return 'File upload failed. Please try again.';
      
      case 'storage/invalid-event-name':
        return 'Invalid event name.';
      
      case 'storage/invalid-url':
        return 'Invalid file URL.';
      
      case 'storage/invalid-argument':
        return 'Invalid argument provided.';
      
      case 'storage/no-default-bucket':
        return 'No default storage bucket configured.';
      
      case 'storage/cannot-slice-blob':
        return 'File upload failed. Please try again.';
      
      case 'storage/server-file-wrong-size':
        return 'File size mismatch. Please try again.';
      
      default:
        return 'Storage error: ${error.message ?? error.code}';
    }
  }

  /// Log error for debugging and monitoring
  static void logError(dynamic error, {StackTrace? stackTrace, String? context}) {
    // print('=== Firebase Error Log ===');
    // print('Timestamp: ${DateTime.now().toIso8601String()}');
    if (context != null) {
      // print('Context: $context');
    }
    // print('Error Type: ${error.runtimeType}');
    // print('Error Message: ${getErrorMessage(error)}');
    if (error is FirebaseException) {
      // print('Error Code: ${error.code}');
      // print('Plugin: ${error.plugin}');
    }
    // print('Raw Error: $error');
    if (stackTrace != null) {
      // print('Stack Trace: $stackTrace');
    }
    // print('========================');
    
    // TODO: Send to crash reporting service (Firebase Crashlytics)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
  }

  /// Check if error is due to network issues
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'network-request-failed';
    }
    return false;
  }

  /// Check if error is due to permission issues
  static bool isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
             error.code == 'unauthenticated';
    }
    return false;
  }

  /// Check if error requires user to re-authenticate
  static bool requiresReauth(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'requires-recent-login' ||
             error.code == 'session-expired';
    }
    return false;
  }

  /// Get suggested action for error
  static String getSuggestedAction(dynamic error) {
    if (isNetworkError(error)) {
      return 'Please check your internet connection and try again.';
    } else if (isPermissionError(error)) {
      return 'Please contact your teacher or administrator for access.';
    } else if (requiresReauth(error)) {
      return 'Please log out and log in again.';
    } else if (error is FirebaseException && error.code == 'resource-exhausted') {
      return 'Please wait a few minutes before trying again.';
    } else {
      return 'Please try again. If the problem persists, contact support.';
    }
  }
}

/// Extension for easier error handling in try-catch blocks
extension FirebaseErrorHandlerExtension on dynamic {
  String toUserFriendlyMessage() {
    return FirebaseErrorHandler.getErrorMessage(this);
  }
  
  void logFirebaseError({StackTrace? stackTrace, String? context}) {
    FirebaseErrorHandler.logError(this, stackTrace: stackTrace, context: context);
  }
}
