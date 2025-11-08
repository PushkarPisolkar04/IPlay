import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/services/crash_recovery_service.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_constants.dart';

/// Button widget for reporting problems
/// Collects error details and device info, then sends to support
class ReportProblemButton extends StatelessWidget {
  final String? errorMessage;
  final String? errorContext;
  final StackTrace? stackTrace;
  final VoidCallback? onReported;

  const ReportProblemButton({
    super.key,
    this.errorMessage,
    this.errorContext,
    this.stackTrace,
    this.onReported,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: const Icon(Icons.bug_report),
      label: const Text('Report Problem'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ReportProblemDialog(
        errorMessage: errorMessage,
        errorContext: errorContext,
        stackTrace: stackTrace,
      ),
    );

    if (result == true && onReported != null) {
      onReported!();
    }
  }
}

/// Dialog for reporting problems with detailed information
class ReportProblemDialog extends StatefulWidget {
  final String? errorMessage;
  final String? errorContext;
  final StackTrace? stackTrace;

  const ReportProblemDialog({
    super.key,
    this.errorMessage,
    this.errorContext,
    this.stackTrace,
  });

  @override
  State<ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<ReportProblemDialog> {
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _includeDeviceInfo = true;
  bool _includeErrorDetails = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 12),
          Text('Report Problem'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve IPlay by reporting this issue. Your feedback is valuable!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Describe what happened',
                hintText: 'What were you trying to do when this error occurred?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _includeDeviceInfo,
              onChanged: (value) {
                setState(() => _includeDeviceInfo = value ?? true);
              },
              title: const Text('Include device information'),
              subtitle: const Text('Helps us diagnose the issue'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (widget.errorMessage != null)
              CheckboxListTile(
                value: _includeErrorDetails,
                onChanged: (value) {
                  setState(() => _includeErrorDetails = value ?? true);
                },
                title: const Text('Include error details'),
                subtitle: const Text('Technical information about the error'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendReport,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Report'),
        ),
      ],
    );
  }

  Future<void> _sendReport() async {
    setState(() => _isLoading = true);

    try {
      // Collect device and app information
      final deviceInfo = _includeDeviceInfo ? await _getDeviceInfo() : '';
      final errorDetails = _includeErrorDetails ? _getErrorDetails() : '';
      
      // Build email content
      final emailBody = _buildEmailBody(
        description: _descriptionController.text,
        deviceInfo: deviceInfo,
        errorDetails: errorDetails,
      );

      // Send email
      final success = await _sendEmail(emailBody);

      if (!mounted) return;

      if (success) {
        // Log to Crashlytics
        await CrashRecoveryService().log('User reported problem: ${_descriptionController.text}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your report has been sent.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        // Copy to clipboard as fallback
        await _copyToClipboard(emailBody);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report copied to clipboard. Please email it to support@iplay.com'),
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String info = '';
      
      // App info
      info += 'App Version: ${packageInfo.version} (${packageInfo.buildNumber})\n';
      info += 'Package: ${packageInfo.packageName}\n\n';
      
      // Platform-specific device info
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info += 'Platform: Android ${androidInfo.version.release}\n';
        info += 'Device: ${androidInfo.manufacturer} ${androidInfo.model}\n';
        info += 'SDK: ${androidInfo.version.sdkInt}\n';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info += 'Platform: iOS ${iosInfo.systemVersion}\n';
        info += 'Device: ${iosInfo.model}\n';
        info += 'Name: ${iosInfo.name}\n';
      }
      
      return info;
    } catch (e) {
      return 'Unable to collect device info: $e';
    }
  }

  String _getErrorDetails() {
    String details = '';
    
    if (widget.errorContext != null) {
      details += 'Context: ${widget.errorContext}\n\n';
    }
    
    if (widget.errorMessage != null) {
      details += 'Error Message:\n${widget.errorMessage}\n\n';
    }
    
    if (widget.stackTrace != null) {
      details += 'Stack Trace:\n${widget.stackTrace.toString()}\n';
    }
    
    return details;
  }

  String _buildEmailBody({
    required String description,
    required String deviceInfo,
    required String errorDetails,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('IPlay Problem Report');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    if (description.isNotEmpty) {
      buffer.writeln('User Description:');
      buffer.writeln(description);
      buffer.writeln();
    }
    
    if (deviceInfo.isNotEmpty) {
      buffer.writeln('Device Information:');
      buffer.writeln(deviceInfo);
      buffer.writeln();
    }
    
    if (errorDetails.isNotEmpty) {
      buffer.writeln('Error Details:');
      buffer.writeln(errorDetails);
      buffer.writeln();
    }
    
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    
    return buffer.toString();
  }

  Future<bool> _sendEmail(String body) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: _encodeQueryParameters({
        'subject': 'IPlay Problem Report',
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri);
      }
      return false;
    } catch (e) {
      // print('Error launching email: $e');
      return false;
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

/// Compact report problem button for error screens
class CompactReportButton extends StatelessWidget {
  final String? errorMessage;
  final String? errorContext;

  const CompactReportButton({
    super.key,
    this.errorMessage,
    this.errorContext,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: const Icon(Icons.bug_report, size: 16),
      label: const Text('Report'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ReportProblemDialog(
        errorMessage: errorMessage,
        errorContext: errorContext,
      ),
    );
  }
}
