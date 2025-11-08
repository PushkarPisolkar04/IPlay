import 'package:flutter/material.dart';
import 'report_problem_button.dart';
import '../core/utils/firebase_error_handler.dart';

/// Generic error screen that can be used throughout the app
/// Displays appropriate error messages and recovery options
class ErrorScreen extends StatelessWidget {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final bool showReportButton;

  const ErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    this.context,
    this.onRetry,
    this.onGoBack,
    this.showReportButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = FirebaseErrorHandler.getErrorMessage(error);
    final suggestedAction = FirebaseErrorHandler.getSuggestedAction(error);
    final isNetworkError = FirebaseErrorHandler.isNetworkError(error);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: onGoBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              Text(
                isNetworkError ? 'Connection Error' : 'Something Went Wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                suggestedAction,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              if (showReportButton) ...[
                const SizedBox(height: 16),
                ReportProblemButton(
                  errorMessage: errorMessage,
                  errorContext: this.context,
                  stackTrace: stackTrace,
                ),
              ],
              if (onGoBack != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onGoBack,
                  child: const Text('Go Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying errors inline (not full screen)
class InlineErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final bool compact;

  const InlineErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = FirebaseErrorHandler.getErrorMessage(error);
    final isNetworkError = FirebaseErrorHandler.isNetworkError(error);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              color: Colors.red[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red[900],
                  fontSize: 14,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                iconSize: 20,
                color: Colors.red[700],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Builder widget for handling async operations with error handling
class ErrorHandlerBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final VoidCallback? onRetry;

  const ErrorHandlerBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error) ??
              InlineErrorWidget(
                error: snapshot.error,
                onRetry: onRetry,
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const Center(child: Text('No data available'));
      },
    );
  }
}

/// Stream builder with error handling
class ErrorHandlerStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final VoidCallback? onRetry;

  const ErrorHandlerStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error) ??
              InlineErrorWidget(
                error: snapshot.error,
                onRetry: onRetry,
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return const Center(child: Text('No data available'));
      },
    );
  }
}
