import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class RoleSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? signupData;

  const RoleSetupScreen({super.key, this.signupData});

  @override
  State<RoleSetupScreen> createState() => _RoleSetupScreenState();
}

class _RoleSetupScreenState extends State<RoleSetupScreen> {
  String? _selectedRole;
  String _selectedState = 'Delhi';
  final _schoolController = TextEditingController();
  
  // Student-specific fields
  final _classroomCodeController = TextEditingController();
  
  // Principal-specific fields
  final _schoolNameController = TextEditingController();
  final _schoolCityController = TextEditingController();

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  @override
  void dispose() {
    _schoolController.dispose();
    _classroomCodeController.dispose();
    _schoolNameController.dispose();
    _schoolCityController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate principal-specific fields
    if (_selectedRole == 'principal') {
      if (_schoolNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School name is required for principals'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // If coming from email signup, create the account first
    if (widget.signupData != null) {
      final success = await authProvider.signUp(
        email: widget.signupData!['email'],
        password: widget.signupData!['password'],
        displayName: widget.signupData!['name'],
        role: _selectedRole!,
        state: _selectedState,
        schoolTag: _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        final user = FirebaseAuth.instance.currentUser;
        
        // Handle principal: Create school
        if (_selectedRole == 'principal' && user != null) {
          await _createSchoolForPrincipal(user.uid);
        }
        
        // Handle student: Join classroom if code provided
        if (_selectedRole == 'student' && user != null) {
          final classroomCode = _classroomCodeController.text.trim();
          if (classroomCode.isNotEmpty) {
            await _joinClassroomWithCode(user.uid, classroomCode);
          }
        }
        
        if (mounted) {
          if (_selectedRole == 'student') {
            Navigator.pushReplacementNamed(context, '/onboarding');
          } else {
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Setup failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // For Google sign-in, just update the role
      await authProvider.updateUserRole(
        _selectedRole!,
        _selectedState,
        _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
      );

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      
      // Handle principal: Create school
      if (_selectedRole == 'principal' && user != null) {
        await _createSchoolForPrincipal(user.uid);
      }
      
      // Handle student: Join classroom if code provided
      if (_selectedRole == 'student' && user != null) {
        final classroomCode = _classroomCodeController.text.trim();
        if (classroomCode.isNotEmpty) {
          await _joinClassroomWithCode(user.uid, classroomCode);
        }
      }

      if (mounted) {
        if (_selectedRole == 'student') {
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    }
  }

  Future<void> _createSchoolForPrincipal(String userId) async {
    try {
      // Generate school code
      final schoolCode = await _generateSchoolCode();
      
      // Create school document
      final schoolDoc = await FirebaseFirestore.instance.collection('schools').add({
        'name': _schoolNameController.text.trim(),
        'state': _selectedState,
        'city': _schoolCityController.text.trim().isEmpty ? null : _schoolCityController.text.trim(),
        'schoolCode': schoolCode,
        'principalId': userId,
        'teacherIds': [userId],
        'pendingTeacherIds': [],
        'classroomIds': [],
        'studentCount': 0,
        'isPublic': true,
        'description': null,
        'logoUrl': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Update user to be principal
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isPrincipal': true,
        'principalOfSchool': schoolDoc.id,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School created! Code: $schoolCode'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error creating school: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating school: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String> _generateSchoolCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;
    bool exists = true;
    
    while (exists) {
      code = 'SCH-';
      for (int i = 0; i < 5; i++) {
        code += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
      }
      
      // Check if code already exists
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('schoolCode', isEqualTo: code)
          .limit(1)
          .get();
      
      exists = snapshot.docs.isNotEmpty;
      
      if (!exists) return code;
    }
    
    return 'SCH-ERROR';
  }

  Future<void> _joinClassroomWithCode(String userId, String code) async {
    try {
      // Find classroom with this code
      final snapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('joinCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid classroom code'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      final classroomDoc = snapshot.docs.first;
      final classroomData = classroomDoc.data();
      final requiresApproval = classroomData['requiresApproval'] ?? true;
      
      if (requiresApproval) {
        // Create join request
        await FirebaseFirestore.instance.collection('join_requests').add({
          'classroomId': classroomDoc.id,
          'classroomName': classroomData['name'],
          'studentId': userId,
          'studentName': FirebaseAuth.instance.currentUser?.displayName ?? 'Student',
          'status': 'pending',
          'reviewedBy': null,
          'reviewNote': null,
          'requestedAt': Timestamp.now(),
          'resolvedAt': null,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request sent to teacher'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } else {
        // Join directly
        await FirebaseFirestore.instance.collection('classrooms').doc(classroomDoc.id).update({
          'studentIds': FieldValue.arrayUnion([userId]),
          'studentCount': FieldValue.increment(1),
        });
        
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'classroomIds': FieldValue.arrayUnion([classroomDoc.id]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${classroomData['name']}!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print('Error joining classroom: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining classroom: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/backgrounds/background2.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // Role Cards
                _RoleCard(
                  title: AppStrings.student,
                  description: 'Learn IPR through games and quizzes',
                  icon: Icons.school,
                  gradient: AppColors.primaryGradient,
                  isSelected: _selectedRole == 'student',
                  onTap: () {
                    setState(() {
                      _selectedRole = 'student';
                    });
                  },
                ),

                const SizedBox(height: 16),

                _RoleCard(
                  title: AppStrings.teacher,
                  description: 'Create classrooms and track progress',
                  icon: Icons.person,
                  gradient: AppColors.secondaryGradient,
                  isSelected: _selectedRole == 'teacher',
                  onTap: () {
                    setState(() {
                      _selectedRole = 'teacher';
                    });
                  },
                ),

                const SizedBox(height: 16),

                _RoleCard(
                  title: AppStrings.principal,
                  description: 'Manage school and view analytics',
                  icon: Icons.admin_panel_settings,
                  gradient: AppColors.accentGradient,
                  isSelected: _selectedRole == 'principal',
                  onTap: () {
                    setState(() {
                      _selectedRole = 'principal';
                    });
                  },
                ),

                const SizedBox(height: 30),

                // Additional Info Card - Role-specific fields
                if (_selectedRole != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // STATE SELECTOR (for all roles)
                        const Text(
                          'State',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _indianStates
                              .map((state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(state),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedState = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // STUDENT-SPECIFIC: Classroom Code
                        if (_selectedRole == 'student') ...[
                          const Text(
                            'Classroom Code (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter a code to join a classroom immediately',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _classroomCodeController,
                            decoration: InputDecoration(
                              hintText: 'CLS-XXXXX',
                              prefixIcon: const Icon(Icons.class_),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'School Name (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolController,
                            decoration: InputDecoration(
                              hintText: 'Enter your school name',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        // TEACHER-SPECIFIC: School Tag
                        if (_selectedRole == 'teacher') ...[
                          const Text(
                            'School Tag (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolController,
                            decoration: InputDecoration(
                              hintText: 'Enter your school name',
                              prefixIcon: const Icon(Icons.school),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        // PRINCIPAL-SPECIFIC: School Creation
                        if (_selectedRole == 'principal') ...[
                          const Text(
                            'School Name (Required)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter school name',
                              prefixIcon: const Icon(Icons.account_balance),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'City (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _schoolCityController,
                            decoration: InputDecoration(
                              hintText: 'Enter city',
                              prefixIcon: const Icon(Icons.location_city),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: AppColors.info, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You\'ll receive a school code after registration',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        authProvider.isLoading ? null : _completeSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Check Icon
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

