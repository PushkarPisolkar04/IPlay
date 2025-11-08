import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/assignment_service.dart';
import '../../core/models/assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/cache_manager.dart';
import '../../widgets/upload_progress_indicator.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

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
  final List<Map<String, dynamic>> _attachments = []; // {name, url, size}
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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
          // Load existing attachments if any
          if (submission.attachmentUrls != null) {
            for (var url in submission.attachmentUrls!) {
              _attachments.add({
                'name': url.split('/').last.split('?').first,
                'url': url,
                'size': 0, // Size unknown for existing attachments
              });
            }
          }
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

      final attachmentUrls = _attachments.map((a) => a['url'] as String).toList();

      if (_submission == null) {
        // Create new submission
        await _assignmentService.submitAssignment(
          assignmentId: widget.assignmentId,
          studentId: user.uid,
          studentName: user.displayName,
          submissionText: _submissionController.text.trim(),
          attachmentUrls: attachmentUrls.isEmpty ? null : attachmentUrls,
        );
      } else {
        // Update existing submission
        await _assignmentService.updateSubmission(
          _submission!.id,
          submissionText: _submissionController.text.trim(),
          attachmentUrls: attachmentUrls.isEmpty ? null : attachmentUrls,
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // Check original file size (max 2MB before compression)
        if (fileSize > 2 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image must be less than 2MB')),
            );
          }
          return;
        }

        // Compress image to max 500KB
        final compressedFile = await _compressImage(file);
        if (compressedFile == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error compressing image')),
            );
          }
          return;
        }

        await _uploadFile(compressedFile, pickedFile.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed${filePath.substring(lastIndex)}';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result == null) return null;

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // If still larger than 500KB, compress more aggressively
      if (compressedSize > 500 * 1024) {
        final result2 = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          outPath,
          quality: 70,
          minWidth: 1280,
          minHeight: 720,
        );
        return result2 != null ? File(result2.path) : compressedFile;
      }

      return compressedFile;
    } catch (e) {
      return null;
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref('submissions/${user.uid}/${timestamp}_$fileName');

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();
      final fileSize = await file.length();

      setState(() {
        _attachments.add({
          'name': fileName,
          'url': downloadUrl,
          'size': fileSize,
        });
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        backgroundColor: AppDesignSystem.primaryIndigo,
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
            const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.textSecondary),
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
              color: AppDesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Due date card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppDesignSystem.error.withValues(alpha: 0.1)
                  : AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverdue
                    ? AppDesignSystem.error.withValues(alpha: 0.3)
                    : AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.schedule,
                  color: isOverdue ? AppDesignSystem.error : AppDesignSystem.primaryIndigo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOverdue ? 'Overdue' : 'Due Date',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOverdue ? AppDesignSystem.error : AppDesignSystem.primaryIndigo,
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
                    color: AppDesignSystem.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_assignment!.maxPoints} pts',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppDesignSystem.success,
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
                  color: AppDesignSystem.backgroundWhite,
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
                    ? AppDesignSystem.success.withValues(alpha: 0.1)
                    : AppDesignSystem.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGraded
                      ? AppDesignSystem.success.withValues(alpha: 0.3)
                      : AppDesignSystem.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGraded ? Icons.check_circle : Icons.pending,
                        color: isGraded ? AppDesignSystem.success : AppDesignSystem.warning,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isGraded ? 'Graded' : 'Submitted',
                        style: AppTextStyles.h3.copyWith(
                          color: isGraded ? AppDesignSystem.success : AppDesignSystem.warning,
                        ),
                      ),
                      const Spacer(),
                      if (isGraded)
                        Text(
                          '${_submission!.score}/${_assignment!.maxPoints}',
                          style: AppTextStyles.h2.copyWith(
                            color: AppDesignSystem.success,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted ${DateFormat('MMM dd, yyyy').format(_submission!.submittedAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppDesignSystem.textSecondary,
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
                    onPressed: (!isOverdue || hasSubmission) && !_isUploading ? _pickImage : null,
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                  ),
                  
                  // Upload progress
                  if (_isUploading) ...[
                    const SizedBox(height: 12),
                    UploadProgressIndicator(
                      progress: _uploadProgress,
                      statusText: 'Uploading image...',
                    ),
                  ],
                  
                  // Attached images
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...List.generate(_attachments.length, (index) {
                      final attachment = _attachments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: attachment['url'],
                                cacheManager: IPlayCacheManager.staticContentCache,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 24),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attachment['name'],
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFileSize(attachment['size']),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppDesignSystem.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isGraded)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _attachments.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (isOverdue && !hasSubmission) || _isSubmitting
                        ? null
                        : _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignSystem.primaryIndigo,
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

