import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/assignment_service.dart';
import '../../core/models/assignment_model.dart';
import '../../providers/auth_provider.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    Key? key,
    required this.assignmentId,
  }) : super(key: key);

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final _formKey = GlobalKey<FormState>();
  final _submissionController = TextEditingController();
  
  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _submission;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final List<String> _attachmentUrls = [];

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final assignment = await _assignmentService.getAssignmentById(widget.assignmentId);
      final submission = await _assignmentService.getStudentSubmission(
        assignmentId: widget.assignmentId,
        studentId: userId,
      );

      setState(() {
        _assignment = assignment;
        _submission = submission;
        if (submission != null) {
          _submissionController.text = submission.submissionText;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      if (_submission == null) {
        // Create new submission
        await _assignmentService.submitAssignment(
          assignmentId: widget.assignmentId,
          studentId: user.uid,
          studentName: user.displayName,
          submissionText: _submissionController.text.trim(),
          attachmentUrls: _attachmentUrls.isEmpty ? null : _attachmentUrls,
        );
      } else {
        // Update existing submission
        await _assignmentService.updateSubmission(
          submissionId: _submission!.id,
          submissionText: _submissionController.text.trim(),
          attachmentUrls: _attachmentUrls.isEmpty ? null : _attachmentUrls,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
        _loadAssignment(); // Reload to get updated submission
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting: $e')),
      );
    }
  }

  void _addAttachment() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File upload coming soon!')),
    );
  }

  bool _isOverdue() {
    if (_assignment == null) return false;
    return DateTime.now().isAfter(_assignment!.dueDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAssignment,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isOverdue = _isOverdue();
    final hasSubmission = _submission != null;
    final isGraded = hasSubmission && _submission!.score != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assignment header
          Text(
            _assignment!.title,
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 8),
          Text(
            'By ${_assignment!.teacherName}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Due date card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverdue
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.schedule,
                  color: isOverdue ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOverdue ? 'Overdue' : 'Due Date',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOverdue ? AppColors.error : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(_assignment!.dueDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_assignment!.maxPoints} pts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Description',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            _assignment!.description,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Attachments (if any)
          if (_assignment!.attachmentUrls != null && _assignment!.attachmentUrls!.isNotEmpty) ...[
            Text(
              'Attachments',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            ...List.generate(_assignment!.attachmentUrls!.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attachment ${index + 1}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () {
                        // TODO: Implement download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Submission status card
          if (hasSubmission) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGraded
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGraded
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGraded ? Icons.check_circle : Icons.pending,
                        color: isGraded ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isGraded ? 'Graded' : 'Submitted',
                        style: AppTextStyles.h3.copyWith(
                          color: isGraded ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const Spacer(),
                      if (isGraded)
                        Text(
                          '${_submission!.score}/${_assignment!.maxPoints}',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted ${DateFormat('MMM dd, yyyy').format(_submission!.submittedAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isGraded && _submission!.feedback != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Teacher Feedback',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _submission!.feedback!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Submission form (if not graded)
          if (!isGraded) ...[
            Text(
              hasSubmission ? 'Update Your Submission' : 'Your Submission',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _submissionController,
                    maxLines: 8,
                    maxLength: 2000,
                    enabled: !isOverdue || hasSubmission,
                    decoration: InputDecoration(
                      hintText: 'Type your answer here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Submission text is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: (!isOverdue || hasSubmission) ? _addAttachment : null,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Attachment'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (isOverdue && !hasSubmission) || _isSubmitting
                        ? null
                        : _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                        : Text(
                            hasSubmission ? 'Update Submission' : 'Submit Assignment',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

