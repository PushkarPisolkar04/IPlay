import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/assignment_service.dart';
import '../../core/models/assignment_model.dart';
import '../../widgets/loading_skeleton.dart';

class SubmissionsScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final int maxPoints;

  const SubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.maxPoints,
  });

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  
  List<AssignmentSubmissionModel> _submissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final submissions = await _assignmentService.getAssignmentSubmissions(
        widget.assignmentId,
      );
      
      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _gradeSubmission(AssignmentSubmissionModel submission) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GradeDialog(
        maxPoints: widget.maxPoints,
        currentScore: submission.score,
        currentFeedback: submission.feedback,
      ),
    );

    if (result == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _assignmentService.gradeSubmission(
        submissionId: submission.id,
        teacherId: user.uid,
        score: result['score'] as int,
        feedback: result['feedback'] as String?,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission graded successfully!')),
      );

      _loadSubmissions(); // Reload list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error grading submission: $e')),
      );
    }
  }

  void _viewSubmission(AssignmentSubmissionModel submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _SubmissionDetailSheet(
          submission: submission,
          scrollController: scrollController,
          onGrade: () {
            Navigator.pop(context);
            _gradeSubmission(submission);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submissions'),
            Text(
              widget.assignmentTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const ListSkeleton(itemCount: 5)
          : _error != null
              ? _buildErrorState()
              : _submissions.isEmpty
                  ? _buildEmptyState()
                  : _buildSubmissionsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSubmissions,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppDesignSystem.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Submissions Yet',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 16),
            Text(
              'Students haven\'t submitted their work yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList() {
    final graded = _submissions.where((s) => s.score != null).length;
    final pending = _submissions.length - graded;

    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppDesignSystem.backgroundWhite,
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total',
                  value: _submissions.length.toString(),
                  color: AppDesignSystem.primaryIndigo,
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: 'Graded',
                  value: graded.toString(),
                  color: AppDesignSystem.success,
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: pending.toString(),
                  color: AppDesignSystem.warning,
                ),
              ),
            ],
          ),
        ),

        // Submissions list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSubmissions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final submission = _submissions[index];
                return _SubmissionCard(
                  submission: submission,
                  maxPoints: widget.maxPoints,
                  onTap: () => _viewSubmission(submission),
                  onGrade: () => _gradeSubmission(submission),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final AssignmentSubmissionModel submission;
  final int maxPoints;
  final VoidCallback onTap;
  final VoidCallback onGrade;

  const _SubmissionCard({
    required this.submission,
    required this.maxPoints,
    required this.onTap,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.score != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                    child: Text(
                      submission.studentName[0].toUpperCase(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.studentName,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted ${DateFormat('MMM dd, yyyy').format(submission.submittedAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isGraded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${submission.score}/$maxPoints',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppDesignSystem.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pending',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                submission.submissionText,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isGraded) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onGrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.primaryIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Grade Submission'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionDetailSheet extends StatelessWidget {
  final AssignmentSubmissionModel submission;
  final ScrollController scrollController;
  final VoidCallback onGrade;

  const _SubmissionDetailSheet({
    required this.submission,
    required this.scrollController,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.score != null;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppDesignSystem.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Student info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                    child: Text(
                      submission.studentName[0].toUpperCase(),
                      style: AppTextStyles.h2.copyWith(color: AppDesignSystem.primaryIndigo),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.studentName,
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted ${DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(submission.submittedAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submission text
              Text(
                'Submission',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submission.submissionText,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              // Grading info
              if (isGraded) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppDesignSystem.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppDesignSystem.success),
                          const SizedBox(width: 12),
                          Text(
                            'Graded',
                            style: AppTextStyles.h3.copyWith(color: AppDesignSystem.success),
                          ),
                          const Spacer(),
                          Text(
                            '${submission.score}/100',
                            style: AppTextStyles.h2.copyWith(color: AppDesignSystem.success),
                          ),
                        ],
                      ),
                      if (submission.feedback != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Feedback',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          submission.feedback!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Graded ${DateFormat('MMM dd, yyyy').format(submission.gradedAt!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: onGrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.primaryIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Grade This Submission'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeDialog extends StatefulWidget {
  final int maxPoints;
  final int? currentScore;
  final String? currentFeedback;

  const _GradeDialog({
    required this.maxPoints,
    this.currentScore,
    this.currentFeedback,
  });

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: widget.currentScore?.toString() ?? '',
    );
    _feedbackController = TextEditingController(
      text: widget.currentFeedback ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grade Submission'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Score',
                hintText: '0-${widget.maxPoints}',
                suffixText: '/ ${widget.maxPoints}',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Score is required';
                }
                final score = int.tryParse(value);
                if (score == null) {
                  return 'Must be a number';
                }
                if (score < 0 || score > widget.maxPoints) {
                  return 'Score must be between 0 and ${widget.maxPoints}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Feedback (Optional)',
                hintText: 'Provide feedback to the student...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'score': int.parse(_scoreController.text),
                'feedback': _feedbackController.text.trim().isEmpty
                    ? null
                    : _feedbackController.text.trim(),
              });
            }
          },
          child: const Text('Submit Grade'),
        ),
      ],
    );
  }
}

