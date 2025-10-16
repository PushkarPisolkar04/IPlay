import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/clean_card.dart';

/// Create Announcement Screen - For teachers to create announcements
class CreateAnnouncementScreen extends StatefulWidget {
  final String classroomId;
  final String classroomName;

  const CreateAnnouncementScreen({
    Key? key,
    required this.classroomId,
    required this.classroomName,
  }) : super(key: key);

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _priority = 'normal';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Get teacher's name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('User not found');
      
      final teacherName = userDoc.data()?['displayName'] ?? 'Teacher';

      // Create announcement document
      await FirebaseFirestore.instance
          .collection('announcements')
          .add({
        'classroomId': widget.classroomId,
        'classroomName': widget.classroomName,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'priority': _priority,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement posted!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Announcement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CleanCard(
                color: AppColors.accent.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.classroomName,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Announce to all students',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Quiz Tomorrow',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter your announcement...',
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                'Priority',
                style: AppTextStyles.sectionHeader,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              CleanCard(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('🔵 Normal'),
                      subtitle: const Text('Standard announcement'),
                      value: 'normal',
                      groupValue: _priority,
                      onChanged: (value) {
                        setState(() => _priority = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('🟢 Important'),
                      subtitle: const Text('Highlighted for students'),
                      value: 'important',
                      groupValue: _priority,
                      onChanged: (value) {
                        setState(() => _priority = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text('🔴 Urgent'),
                      subtitle: const Text('Requires immediate attention'),
                      value: 'urgent',
                      groupValue: _priority,
                      onChanged: (value) {
                        setState(() => _priority = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              PrimaryButton(
                text: _isLoading ? 'Posting...' : 'Post Announcement',
                onPressed: _isLoading ? () {} : _createAnnouncement,
                fullWidth: true,
              ),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

