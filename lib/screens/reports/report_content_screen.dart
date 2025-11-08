import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/report_service.dart';
import '../../providers/auth_provider.dart';

class ReportContentScreen extends StatefulWidget {
  final String reportType; // 'announcement' | 'assignment' | 'user' | 'other'
  final String reportedItemId;
  final String? reportedItemTitle; // Optional title for display

  const ReportContentScreen({
    super.key,
    required this.reportType,
    required this.reportedItemId,
    this.reportedItemTitle,
  });

  @override
  State<ReportContentScreen> createState() => _ReportContentScreenState();
}

class _ReportContentScreenState extends State<ReportContentScreen> {
  final ReportService _reportService = ReportService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'Inappropriate Content',
    'Spam or Misleading',
    'Harassment or Bullying',
    'Incorrect Information',
    'Privacy Violation',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      await _reportService.submitReport(
        reportType: widget.reportType,
        contentId: widget.reportedItemId,
        description: '${_selectedReason!}${_descriptionController.text.trim().isEmpty ? '' : ': ${_descriptionController.text.trim()}'}',
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Report Submitted'),
            content: const Text(
              'Thank you for helping keep IPlay safe. '
              'Our team will review this report shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Report Content'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppDesignSystem.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesignSystem.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppDesignSystem.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reports are confidential and help us maintain a safe learning environment.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reporting item info
              if (widget.reportedItemTitle != null) ...[
                Text(
                  'Reporting:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.reportedItemTitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Report reason
              Text(
                'Reason for Report *',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_reportReasons.length, (index) {
                final reason = _reportReasons[index];
                final isSelected = _selectedReason == reason;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedReason = reason);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.1)
                            : AppDesignSystem.backgroundWhite,
                        border: Border.all(
                          color: isSelected 
                              ? AppDesignSystem.primaryIndigo
                              : AppDesignSystem.backgroundWhite,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected 
                                ? Icons.radio_button_checked 
                                : Icons.radio_button_unchecked,
                            color: isSelected 
                                ? AppDesignSystem.primaryIndigo 
                                : AppDesignSystem.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            reason,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected 
                                  ? AppDesignSystem.textPrimary 
                                  : AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Additional details
              Text(
                'Additional Details (Optional)',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Provide any additional context that might help us understand the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppDesignSystem.backgroundWhite,
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

