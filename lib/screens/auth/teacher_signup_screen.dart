import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/auth_service.dart';
import 'dart:math';

/// Teacher Signup Screen with School Code option
class TeacherSignupScreen extends StatefulWidget {
  const TeacherSignupScreen({Key? key}) : super(key: key);

  @override
  State<TeacherSignupScreen> createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _cityController = TextEditingController();
  
  String? _selectedAvatar;
  String? _selectedState;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _hasSchoolCode = false;
  
  final AuthService _authService = AuthService();
  
  final List<String> _avatarOptions = [
    'assets/tea_avatars/avatar1.png',
    'assets/tea_avatars/avatar2.png',
    'assets/tea_avatars/avatar3.png',
    'assets/tea_avatars/avatar4.png',
    'assets/tea_avatars/avatar5.png',
    'assets/tea_avatars/avatar6.png',
    'assets/tea_avatars/avatar7.png',
    'assets/tea_avatars/avatar8.png',
    'assets/tea_avatars/avatar9.png',
    'assets/tea_avatars/avatar10.png',
    'assets/tea_avatars/avatar11.png',
    'assets/tea_avatars/avatar12.png',
    'assets/tea_avatars/avatar13.png',
    'assets/tea_avatars/avatar14.png',
    'assets/tea_avatars/avatar15.png',
    'assets/tea_avatars/avatar16.png',
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
    _schoolCodeController.dispose();
    _schoolNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Generate unique school code
  String _generateSchoolCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    return 'SCH-$code';
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

    setState(() => _isLoading = true);

    try {
      String? schoolId;
      String? fetchedState;
      String? fetchedSchoolName;
      bool isPrincipal = false;

      // OPTION A: Has school code (join existing school)
      if (_hasSchoolCode && _schoolCodeController.text.trim().isNotEmpty) {
        final code = _schoolCodeController.text.trim().toUpperCase();
        
        // Find school by code
        final schoolQuery = await FirebaseFirestore.instance
            .collection('schools')
            .where('schoolCode', isEqualTo: code)
            .limit(1)
            .get();
        
        if (schoolQuery.docs.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid school code'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        
        schoolId = schoolQuery.docs.first.id;
        final schoolData = schoolQuery.docs.first.data();
        fetchedState = schoolData['state'];
        fetchedSchoolName = schoolData['name'];
        isPrincipal = false; // Not principal if joining
      }
      // OPTION B: Creating new school (become principal)
      else {
        if (_selectedState == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select state'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        
        if (_schoolNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter school name'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        
        // Will create school after user creation
        fetchedState = _selectedState;
        fetchedSchoolName = _schoolNameController.text.trim();
        isPrincipal = true; // First teacher = principal
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

      // If creating new school, do it now
      if (isPrincipal) {
        final schoolCode = _generateSchoolCode();
        final schoolRef = FirebaseFirestore.instance.collection('schools').doc();
        schoolId = schoolRef.id;
        
        await schoolRef.set({
          'id': schoolId,
          'name': fetchedSchoolName,
          'state': fetchedState,
          'city': _cityController.text.trim(),
          'schoolCode': schoolCode,
          'principalId': user.uid,
          'teacherIds': [user.uid],
          'classroomIds': [],
          'studentCount': 0,
          'logoUrl': null,
          'description': '',
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      } else if (schoolId != null) {
        // If joining existing school, add to PENDING list (requires principal approval)
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .update({
          'pendingTeacherIds': FieldValue.arrayUnion([user.uid]),
        });
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
        'role': 'teacher',
        'state': fetchedState,
        'schoolTag': fetchedSchoolName,
        'isPrincipal': isPrincipal,
        'principalOfSchool': isPrincipal ? schoolId : null,
        'classroomIds': [],
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

      if (!mounted) return;

      // Navigate to main screen (Teacher Dashboard)
      Navigator.pushReplacementNamed(context, '/main');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPrincipal 
              ? 'School created! You are now a Principal.' 
              : 'Join request sent! Waiting for principal approval.'),
          backgroundColor: isPrincipal ? Colors.green : Colors.orange,
          duration: Duration(seconds: isPrincipal ? 3 : 5),
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
        title: const Text('Teacher Sign Up'),
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
                      color: Colors.black.withOpacity(0.1),
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
                  'Start teaching IPR!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person, color: AppColors.secondary),
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
                    prefixIcon: Icon(Icons.email, color: AppColors.accent),
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
                    prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.primary,
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
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.primary,
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
                    Icon(Icons.face, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Select Avatar',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.secondary,
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
                          color: isSelected ? AppColors.secondary.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.3),
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
                
                // School Option
                Row(
                  children: [
                    Icon(Icons.school, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'School Setup',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                
                // Has School Code Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasSchoolCode ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: _hasSchoolCode,
                    onChanged: (value) => setState(() => _hasSchoolCode = value ?? false),
                    title: Text(
                      'Join Existing School',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'I have a school code',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_hasSchoolCode ? AppColors.secondary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<bool>(
                    value: false,
                    groupValue: _hasSchoolCode,
                    onChanged: (value) => setState(() => _hasSchoolCode = value ?? true),
                    title: Row(
                      children: [
                        Text(
                          'Create New School',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('👑', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    subtitle: Text(
                      'Become principal of your school',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    activeColor: AppColors.secondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                if (_hasSchoolCode) ...[
                  // School Code Input
                  TextFormField(
                    controller: _schoolCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'School Code',
                      hintText: 'SCH-XXXXX',
                      prefixIcon: Icon(Icons.school, color: AppColors.success),
                    ),
                    validator: (value) {
                      if (_hasSchoolCode && (value == null || value.isEmpty)) {
                        return 'Please enter school code';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
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
                            'You\'ll join as a teacher (not principal)',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (!_hasSchoolCode) ...[
                  // School Name
                  TextFormField(
                    controller: _schoolNameController,
                    decoration: const InputDecoration(
                      labelText: 'School Name (Required)',
                      hintText: 'Enter school name',
                      prefixIcon: Icon(Icons.account_balance, color: AppColors.secondary),
                    ),
                    validator: (value) {
                      if (!_hasSchoolCode && (value == null || value.isEmpty)) {
                        return 'Please enter school name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // State Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.info),
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
                      if (!_hasSchoolCode && value == null) {
                        return 'Please select state';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // City (Optional)
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City (Optional)',
                      hintText: 'Enter city',
                      prefixIcon: Icon(Icons.location_city, color: AppColors.warning),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll become the principal of this school',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.xl),
                
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

