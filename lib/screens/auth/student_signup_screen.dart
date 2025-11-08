import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/auth_service.dart';

/// Student Signup Screen with Classroom Code option
class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _classroomCodeController = TextEditingController();
  final _schoolNameController = TextEditingController();
  
  String? _selectedAvatar;
  String? _selectedState;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _hasClassroomCode = false;
  
  final AuthService _authService = AuthService();
  
  final List<String> _avatarOptions = [
    'assets/stu_avatars/avatar1.png',
    'assets/stu_avatars/avatar2.png',
    'assets/stu_avatars/avatar3.png',
    'assets/stu_avatars/avatar4.png',
    'assets/stu_avatars/avatar5.png',
    'assets/stu_avatars/avatar6.png',
    'assets/stu_avatars/avatar7.png',
    'assets/stu_avatars/avatar8.png',
    'assets/stu_avatars/avatar9.png',
    'assets/stu_avatars/avatar10.png',
    'assets/stu_avatars/avatar11.png',
    'assets/stu_avatars/avatar12.png',
    'assets/stu_avatars/avatar13.png',
    'assets/stu_avatars/avatar14.png',
    'assets/stu_avatars/avatar15.png',
    'assets/stu_avatars/avatar16.png',
  ];
  
  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _classroomCodeController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an avatar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If no classroom code, state is required
    if (!_hasClassroomCode && _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your state'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? classroomId;
      String? fetchedState;
      String? fetchedSchool;
      
      // If classroom code provided, verify and fetch data
      if (_hasClassroomCode && _classroomCodeController.text.trim().isNotEmpty) {
        final code = _classroomCodeController.text.trim().toUpperCase();
        
        // Find classroom by code
        final classroomQuery = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('joinCode', isEqualTo: code)
            .limit(1)
            .get();
        
        if (classroomQuery.docs.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid classroom code. Continuing as solo learner...'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        
        final classroomDoc = classroomQuery.docs.first;
        classroomId = classroomDoc.id;
        
        // Fetch school data
        final schoolId = classroomDoc.data()['schoolId'];
        if (schoolId != null) {
          final schoolDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
          
          if (schoolDoc.exists) {
            fetchedState = schoolDoc.data()?['state'];
            fetchedSchool = schoolDoc.data()?['name'];
          }
        }
      }

      // Create Firebase user
      final userCredential = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'displayName': _nameController.text.trim(),
        'avatarUrl': _selectedAvatar,
        'role': 'student',
        'state': fetchedState ?? _selectedState ?? '',
        'schoolTag': fetchedSchool ?? _schoolNameController.text.trim(),
        'classroomIds': classroomId != null ? [classroomId] : [],
        'isPrincipal': false,
        'principalOfSchool': null,
        'totalXP': 0,
        'currentStreak': 0,
        'lastActiveDate': Timestamp.now(),
        'badges': [],
        'progressSummary': {},
        'pendingClassroomRequests': [],
        'storageUsedMB': 0.0,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // If joined classroom, update classroom's student list
      if (classroomId != null) {
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .update({
          'studentIds': FieldValue.arrayUnion([user.uid]),
        });
      }

      if (!mounted) return;

      // Navigate to student tutorial screen
      Navigator.pushReplacementNamed(context, '/student-tutorial');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to IPlay!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Student Sign Up'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/background1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const SizedBox(height: AppSpacing.md),
                
                // Title
                Text('Create Your Account', style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Start your IPR learning journey!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person, color: AppDesignSystem.primaryIndigo),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email, color: AppDesignSystem.primaryAmber),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Min 8 characters',
                    prefixIcon: const Icon(Icons.lock, color: AppDesignSystem.primaryPink),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppDesignSystem.primaryPink,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppDesignSystem.primaryPink),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppDesignSystem.primaryPink,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Avatar Selection
                Row(
                  children: [
                    Icon(Icons.face, size: 20, color: AppDesignSystem.primaryIndigo),
                    const SizedBox(width: 8),
                    Text(
                      'Select Avatar',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _avatarOptions.map((avatar) {
                    final isSelected = _selectedAvatar == avatar;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = avatar),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppDesignSystem.primaryIndigo : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.person, color: Colors.grey[600], size: 30),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Classroom Code Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppDesignSystem.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppDesignSystem.info.withValues(alpha: 0.3)),
                  ),
                  child: CheckboxListTile(
                    value: _hasClassroomCode,
                    onChanged: (value) => setState(() => _hasClassroomCode = value ?? false),
                    title: Text(
                      'I have a classroom code',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppDesignSystem.primaryIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _hasClassroomCode ? 'School & state will be auto-fetched' : 'You\'ll learn solo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                    activeColor: AppDesignSystem.primaryIndigo,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                
                if (_hasClassroomCode) ...[
                  const SizedBox(height: AppSpacing.md),
                  
                  // Classroom Code
                  TextFormField(
                    controller: _classroomCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Classroom Code',
                      hintText: 'CLS-XXXXX',
                      prefixIcon: Icon(Icons.class_, color: AppDesignSystem.success),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: AppDesignSystem.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your school and state will be auto-fetched from the classroom',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (!_hasClassroomCode) ...[
                  const SizedBox(height: AppSpacing.md),
                  
                  // State Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.location_on, color: AppDesignSystem.info),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedState = value),
                    validator: (value) {
                      if (value == null) return 'Please select your state';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // School Name (Optional)
                  TextFormField(
                    controller: _schoolNameController,
                    decoration: const InputDecoration(
                      labelText: 'School Name (Optional)',
                      hintText: 'Enter your school name',
                      prefixIcon: Icon(Icons.school, color: AppDesignSystem.warning),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.sm),
                
                // Sign Up Button
                PrimaryButton(
                  text: _isLoading ? 'Creating Account...' : 'Create Account',
                  onPressed: _isLoading ? null : () => _handleSignUp(),
                  fullWidth: true,
                ),
                
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


