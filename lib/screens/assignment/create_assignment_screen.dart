import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:io';
import 'dart:convert';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/assignment_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/upload_progress_indicator.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classroomId;
  final String classroomName;

  const CreateAssignmentScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _maxPointsController = TextEditingController(text: '100');
  
  // Rich text editor
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final bool _useRichTextEditor = true;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isCreating = false;
  final List<Map<String, dynamic>> _attachments = []; // {name, url, size, type}
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxPointsController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate description
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      final attachmentUrls = _attachments.map((a) => a['url'] as String).toList();

      // Convert Quill document to JSON for storage (for future use)
      // final descriptionJson = jsonEncode(_quillController.document.toDelta().toJson());

      await _assignmentService.createAssignment(
        classroomId: widget.classroomId,
        teacherId: user.uid,
        teacherName: user.displayName,
        title: _titleController.text.trim(),
        description: plainText, // Store plain text for backward compatibility
        dueDate: _selectedDate,
        maxPoints: int.parse(_maxPointsController.text),
        attachmentUrls: attachmentUrls.isEmpty ? null : attachmentUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating assignment: $e')),
      );
    }
  }

  void _applyTemplate(String templateType) {
    switch (templateType) {
      case 'essay':
        _titleController.text = 'Essay Assignment';
        _quillController.document = quill.Document.fromJson([
          {'insert': 'Write a detailed essay on the following topic:\n\n'},
          {'insert': 'Topic: [Enter topic here]\n\n', 'attributes': {'bold': true}},
          {'insert': 'Requirements:\n'},
          {'insert': '• Minimum 500 words\n'},
          {'insert': '• Include introduction, body, and conclusion\n'},
          {'insert': '• Cite at least 3 sources\n'},
          {'insert': '• Use proper formatting\n\n'},
          {'insert': 'Grading Criteria:\n'},
          {'insert': '• Content and understanding (40%)\n'},
          {'insert': '• Organization and structure (30%)\n'},
          {'insert': '• Grammar and style (20%)\n'},
          {'insert': '• Citations and references (10%)\n'},
        ]);
        break;
      case 'quiz':
        _titleController.text = 'Quiz Assignment';
        _quillController.document = quill.Document.fromJson([
          {'insert': 'Complete the following quiz:\n\n', 'attributes': {'bold': true}},
          {'insert': 'Question 1: [Enter question]\n'},
          {'insert': 'a) Option A\n'},
          {'insert': 'b) Option B\n'},
          {'insert': 'c) Option C\n'},
          {'insert': 'd) Option D\n\n'},
          {'insert': 'Question 2: [Enter question]\n'},
          {'insert': 'a) Option A\n'},
          {'insert': 'b) Option B\n'},
          {'insert': 'c) Option C\n'},
          {'insert': 'd) Option D\n\n'},
          {'insert': 'Instructions:\n'},
          {'insert': '• Answer all questions\n'},
          {'insert': '• Submit before the due date\n'},
        ]);
        break;
      case 'project':
        _titleController.text = 'Project Assignment';
        _quillController.document = quill.Document.fromJson([
          {'insert': 'Project Title: [Enter title]\n\n', 'attributes': {'bold': true}},
          {'insert': 'Objective:\n'},
          {'insert': '[Describe the project objective]\n\n'},
          {'insert': 'Deliverables:\n'},
          {'insert': '1. [Deliverable 1]\n'},
          {'insert': '2. [Deliverable 2]\n'},
          {'insert': '3. [Deliverable 3]\n\n'},
          {'insert': 'Timeline:\n'},
          {'insert': '• Week 1: [Milestone]\n'},
          {'insert': '• Week 2: [Milestone]\n'},
          {'insert': '• Week 3: Final submission\n\n'},
          {'insert': 'Submission Format:\n'},
          {'insert': '• PDF document\n'},
          {'insert': '• Include all supporting materials\n'},
        ]);
        break;
      case 'reading':
        _titleController.text = 'Reading Assignment';
        _quillController.document = quill.Document.fromJson([
          {'insert': 'Reading Assignment\n\n', 'attributes': {'bold': true}},
          {'insert': 'Read the following material:\n'},
          {'insert': '[Enter reading material or link]\n\n'},
          {'insert': 'After reading, answer these questions:\n\n'},
          {'insert': '1. What is the main idea of the text?\n'},
          {'insert': '2. List three key points discussed.\n'},
          {'insert': '3. How does this relate to what we learned in class?\n'},
          {'insert': '4. What questions do you still have?\n\n'},
          {'insert': 'Your response should be:\n'},
          {'insert': '• Well-organized\n'},
          {'insert': '• Include specific examples from the text\n'},
          {'insert': '• Demonstrate critical thinking\n'},
        ]);
        break;
    }
    setState(() {});
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assignment Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty ? 'Untitled Assignment' : _titleController.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Due: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Points: ${_maxPointsController.text}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: quill.QuillEditor.basic(
                          controller: _quillController,
                        ),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Attachments:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._attachments.map((attachment) => ListTile(
                          leading: Icon(
                            attachment['type'] == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                            color: attachment['type'] == 'pdf' ? Colors.red : Colors.blue,
                          ),
                          title: Text(attachment['name']),
                          subtitle: Text(_formatFileSize(attachment['size'])),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose a Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article, color: AppDesignSystem.primaryIndigo),
              title: const Text('Essay Assignment'),
              subtitle: const Text('For written essays and reports'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('essay');
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: AppDesignSystem.success),
              title: const Text('Quiz Assignment'),
              subtitle: const Text('Multiple choice or short answer'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('quiz');
              },
            ),
            ListTile(
              leading: const Icon(Icons.work, color: AppDesignSystem.warning),
              title: const Text('Project Assignment'),
              subtitle: const Text('For long-term projects'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('project');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book, color: AppDesignSystem.info),
              title: const Text('Reading Assignment'),
              subtitle: const Text('Reading comprehension'),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('reading');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getTeacherStorageUsage() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return 0;

    try {
      final ref = FirebaseStorage.instance.ref('assignments/${user.uid}');
      final result = await ref.listAll();
      int totalSize = 0;
      
      for (var item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF file must be less than 5MB')),
            );
          }
          return;
        }

        // Check teacher storage limit (25MB total)
        final currentUsage = await _getTeacherStorageUsage();
        if (currentUsage + fileSize > 25 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage limit exceeded (25MB max per teacher)')),
            );
          }
          return;
        }

        await _uploadFile(file, result.files.single.name, 'pdf');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking PDF: $e')),
        );
      }
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

        final compressedSize = await compressedFile.length();

        // Check teacher storage limit (25MB total)
        final currentUsage = await _getTeacherStorageUsage();
        if (currentUsage + compressedSize > 25 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage limit exceeded (25MB max per teacher)')),
            );
          }
          return;
        }

        await _uploadFile(compressedFile, pickedFile.name, 'image');
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

  Future<void> _uploadFile(File file, String fileName, String fileType) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref('assignments/${user.uid}/${timestamp}_$fileName');

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
          'type': fileType,
        });
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppDesignSystem.error),
              title: const Text('Upload PDF'),
              subtitle: const Text('Max 5MB'),
              onTap: () {
                Navigator.pop(context);
                _pickPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppDesignSystem.primaryIndigo),
              title: const Text('Upload Image'),
              subtitle: const Text('Max 2MB, will be compressed to 500KB'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Assignment'),
            Text(
              widget.classroomName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showPreview,
            tooltip: 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _showTemplateSelector,
            tooltip: 'Use Template',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Assignment Title *',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Copyright Quiz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description with Rich Text Editor
              Text(
                'Description *',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Editor
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _editorFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your assignment description above.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Due Date
              Text(
                'Due Date *',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppDesignSystem.primaryIndigo),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Max Points
              Text(
                'Maximum Points *',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxPointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '100',
                  prefixIcon: const Icon(Icons.grade),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Max points is required';
                  }
                  final points = int.tryParse(value);
                  if (points == null || points <= 0) {
                    return 'Must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Attachments
              Text(
                'Attachments (Optional)',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _showAttachmentOptions,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Attachment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              // Upload progress
              if (_isUploading) ...[
                const SizedBox(height: 12),
                UploadProgressIndicator(
                  progress: _uploadProgress,
                  statusText: 'Uploading file...',
                ),
              ],
              
              // Attached files
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_attachments.length, (index) {
                  final attachment = _attachments[index];
                  final isPDF = attachment['type'] == 'pdf';
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
                        Icon(
                          isPDF ? Icons.picture_as_pdf : Icons.image,
                          size: 24,
                          color: isPDF ? AppDesignSystem.error : AppDesignSystem.primaryIndigo,
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
              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppDesignSystem.primaryIndigo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Students will be able to submit text responses and attachments. You can grade submissions and provide feedback.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Create button
              ElevatedButton(
                onPressed: _isCreating ? null : _createAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Assignment',
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

