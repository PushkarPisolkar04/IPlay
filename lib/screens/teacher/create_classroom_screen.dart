import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/clean_card.dart';

/// Create Classroom Screen - For teachers to create new classrooms
/// Features: School affiliation (independent or under school)
class CreateClassroomScreen extends StatefulWidget {
  const CreateClassroomScreen({Key? key}) : super(key: key);

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _schoolCodeController = TextEditingController();
  bool _requiresApproval = true;
  bool _isLoading = false;
  bool _isIndependent = true; // Independent classroom or under school
  String? _selectedSchoolId;
  String? _selectedSchoolName;

  @override
  void initState() {
    super.initState();
    _checkExistingSchool();
  }

  Future<void> _checkExistingSchool() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final schoolId = userDoc.data()?['schoolId'] as String?;
        
        if (schoolId != null) {
          // Teacher already has a school, fetch it
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();

          if (schoolDoc.exists) {
            setState(() {
              _selectedSchoolId = schoolId;
              _selectedSchoolName = schoolDoc.data()?['name'];
              _isIndependent = false; // Automatically set to under school
            });
          }
        }
      }
    } catch (e) {
      print('Error checking existing school: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _subjectController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  String _generateClassroomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'CLS-${List.generate(5, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  Future<bool> _isCodeUnique(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('classrooms')
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get();
    
    return query.docs.isEmpty;
  }

  Future<String> _generateUniqueCode() async {
    String code;
    bool isUnique = false;
    
    do {
      code = _generateClassroomCode();
      isUnique = await _isCodeUnique(code);
    } while (!isUnique);
    
    return code;
  }

  Future<void> _findSchool() async {
    final schoolCode = _schoolCodeController.text.trim();
    if (schoolCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a school code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolCode', isEqualTo: schoolCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School not found')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final schoolDoc = query.docs.first;
      final schoolData = schoolDoc.data();
      
      setState(() {
        _selectedSchoolId = schoolDoc.id;
        _selectedSchoolName = schoolData['name'];
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('School found: ${schoolData['name']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createClassroom() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate school affiliation if not independent
    if (!_isIndependent && _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please find and select a school first')),
      );
      return;
    }

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
      
      // Generate unique classroom code
      final joinCode = await _generateUniqueCode();
      
      // Create classroom document
      final classroomRef = FirebaseFirestore.instance.collection('classrooms').doc();
      
      final classroomData = {
        'id': classroomRef.id,
        'name': _nameController.text.trim(),
        'grade': _gradeController.text.trim(),
        'subject': _subjectController.text.trim().isNotEmpty 
            ? _subjectController.text.trim() 
            : null,
        'teacherId': user.uid,
        'teacherName': teacherName,
        'schoolId': _isIndependent ? null : _selectedSchoolId,
        'isIndependent': _isIndependent,
        'joinCode': joinCode,
        'requiresApproval': _requiresApproval,
        'studentIds': [],
        'pendingStudentIds': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      // Use batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();
      
      batch.set(classroomRef, classroomData);
      
      // Update teacher's profile
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'classroomIds': FieldValue.arrayUnion([classroomRef.id]),
          'updatedAt': Timestamp.now(),
        },
      );
      
      // If under a school, update school document
      if (!_isIndependent && _selectedSchoolId != null) {
        batch.update(
          FirebaseFirestore.instance.collection('schools').doc(_selectedSchoolId),
          {
            'classroomIds': FieldValue.arrayUnion([classroomRef.id]),
            'teacherIds': FieldValue.arrayUnion([user.uid]),
            'updatedAt': Timestamp.now(),
          },
        );
      }
      
      // Debug: Check user role
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userRole = currentUserDoc.data()?['role'];
      final isPrincipal = currentUserDoc.data()?['isPrincipal'] ?? false;
      print('User role: $userRole, isPrincipal: $isPrincipal');
      
      print('Creating classroom with data: $classroomData');
      print('User UID: ${user.uid}');
      print('School ID: $_selectedSchoolId');
      print('Is Independent: $_isIndependent');
      
      await batch.commit();

      print('Classroom created successfully!');

      if (!mounted) return;

      // Show success dialog with join code
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Classroom Created!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your classroom has been created successfully.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Join Code',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      joinCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share this code with your students so they can join.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, {'classroomId': classroomRef.id, 'joinCode': joinCode}); // Close screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error creating classroom: $e');
      print('Error details: ${e.toString()}');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Create Classroom',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              CleanCard(
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create a classroom to manage your students and track their progress!',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // School Affiliation Toggle
              Text(
                'Classroom Type',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.md),
              
              CleanCard(
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Text('Independent', style: AppTextStyles.cardTitle),
                      subtitle: Text(
                        'Not affiliated with any school',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      value: true,
                      groupValue: _isIndependent,
                      onChanged: (value) {
                        setState(() {
                          _isIndependent = value!;
                          _selectedSchoolId = null;
                          _selectedSchoolName = null;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1),
                    RadioListTile<bool>(
                      title: Text('Under School', style: AppTextStyles.cardTitle),
                      subtitle: Text(
                        'Part of a school system',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      value: false,
                      groupValue: _isIndependent,
                      onChanged: (value) {
                        setState(() => _isIndependent = value!);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              // School Selection (if under school)
              if (!_isIndependent) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Find School',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.md),
                
                if (_selectedSchoolName != null)
                  CleanCard(
                    color: AppColors.success.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected School',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _selectedSchoolName!,
                                style: AppTextStyles.cardTitle,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedSchoolId = null;
                              _selectedSchoolName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                
                if (_selectedSchoolName == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _schoolCodeController,
                          decoration: const InputDecoration(
                            labelText: 'School Code',
                            hintText: 'e.g., SCH-XXXXX',
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _findSchool,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Find'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask your school principal for the school code',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Classroom Details',
                style: AppTextStyles.sectionHeader,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Classroom Name',
                  hintText: 'e.g., Grade 10 - Section A',
                  prefixIcon: Icon(Icons.class_),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a classroom name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade/Class',
                  hintText: 'e.g., 10, 11, 12',
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a grade/class';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject (Optional)',
                  hintText: 'e.g., Social Science, Computer Science',
                  prefixIcon: Icon(Icons.book),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              Text(
                'Settings',
                style: AppTextStyles.sectionHeader,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              CleanCard(
                child: SwitchListTile(
                  title: Text(
                    'Require Approval',
                    style: AppTextStyles.cardTitle,
                  ),
                  subtitle: Text(
                    'Students need your approval before joining',
                    style: AppTextStyles.bodySmall,
                  ),
                  value: _requiresApproval,
                  onChanged: (value) {
                    setState(() => _requiresApproval = value);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              PrimaryButton(
                text: _isLoading ? 'Creating...' : 'Create Classroom',
                onPressed: _isLoading ? () {} : _createClassroom,
                fullWidth: true,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              Center(
                child: Text(
                  'A unique join code will be generated',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
