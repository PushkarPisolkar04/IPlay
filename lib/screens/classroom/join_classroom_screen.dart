import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/clean_card.dart';

/// Join Classroom Screen - For students to join classrooms using codes
class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({Key? key}) : super(key: key);

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundClassroom;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchClassroom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      
      final query = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid classroom code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      setState(() {
        _foundClassroom = query.docs.first.data();
        _isLoading = false;
      });
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

  Future<void> _joinClassroom() async {
    if (_foundClassroom == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Get student's name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('User not found');
      
      final studentName = userDoc.data()?['displayName'] ?? 'Student';
      final classroomId = _foundClassroom!['id'];
      final requiresApproval = _foundClassroom!['requiresApproval'] ?? false;

      if (requiresApproval) {
        // Create join request
        await FirebaseFirestore.instance
            .collection('join_requests')
            .add({
          'classroomId': classroomId,
          'classroomName': _foundClassroom!['name'],
          'studentId': user.uid,
          'studentName': studentName,
          'status': 'pending',
          'reviewedBy': null,
          'reviewNote': null,
          'requestedAt': Timestamp.now(),
          'resolvedAt': null,
        });

        // Add student to pending list
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .update({
          'pendingStudentIds': FieldValue.arrayUnion([user.uid]),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent! Wait for teacher approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // Direct join (no approval needed)
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .update({
          'studentIds': FieldValue.arrayUnion([user.uid]),
          'updatedAt': Timestamp.now(),
        });

        // Update student's profile
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'classroomId': classroomId,
          'updatedAt': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined classroom!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
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
        title: const Text('Join Classroom'),
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
                color: AppColors.secondary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_add,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter the join code provided by your teacher',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Classroom Code',
                  hintText: 'CLS-XXXXX',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a classroom code';
                  }
                  if (!RegExp(r'^CLS-[A-Z0-9]{5}$').hasMatch(value.toUpperCase())) {
                    return 'Invalid code format (CLS-XXXXX)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() => _foundClassroom = null);
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              if (_foundClassroom == null)
                PrimaryButton(
                  text: _isLoading ? 'Searching...' : 'Search Classroom',
                  onPressed: _isLoading ? () {} : _searchClassroom,
                  fullWidth: true,
                ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Found classroom
              if (_foundClassroom != null) ...[
                Text(
                  'Classroom Found',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                CleanCard(
                  color: AppColors.success.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundClassroom!['name'],
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Teacher: ${_foundClassroom!['teacherName']}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (_foundClassroom!['schoolTag'] != null) ...[
                        const Divider(),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _foundClassroom!['schoolTag'],
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      
                      const Divider(),
                      
                      Row(
                        children: [
                          Icon(
                            _foundClassroom!['requiresApproval'] 
                                ? Icons.lock 
                                : Icons.lock_open,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _foundClassroom!['requiresApproval']
                                ? 'Requires teacher approval'
                                : 'Join instantly',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                PrimaryButton(
                  text: _isLoading ? 'Joining...' : 'Join Classroom',
                  onPressed: _isLoading ? () {} : _joinClassroom,
                  fullWidth: true,
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

