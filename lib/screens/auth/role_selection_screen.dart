import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';

/// Role Selection Screen - Choose between Student/Teacher (NOT Principal)
/// Note: Principal is NOT a signup role. Teachers become Principals by creating a school.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  /// Handle continue button - Navigate to role-specific signup
  void _handleContinue() {
    if (_selectedRole == null) return;

    // Navigate to role-specific signup screen (pass role as argument)
    if (_selectedRole == 'student') {
      Navigator.pushNamed(
        context,
        '/student-signup',
        arguments: {'role': 'student'},
      );
    } else if (_selectedRole == 'teacher') {
      Navigator.pushNamed(
        context,
        '/teacher-signup',
        arguments: {'role': 'teacher'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                padding: const EdgeInsets.all(28),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Select Your Role',
                      style: AppTextStyles.h1,
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    
                    Text(
                      'Choose how you want to use IPlay',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Helper text
                    Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select your role carefully. You can join classrooms or schools later!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Role cards
                    _RoleCard(
                title: 'Student',
                description: 'Learn IPR through games and challenges',
                helperText: '💡 Join a classroom or learn solo - your choice!',
                icon: Icons.school,
                color: AppColors.primary,
                isSelected: _selectedRole == 'student',
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
              
                    const SizedBox(height: AppSpacing.md),
                    
                    _RoleCard(
                title: 'Teacher',
                description: 'Manage classrooms and track student progress',
                helperText: '💡 First in your school? You\'ll become principal!',
                icon: Icons.person,
                color: AppColors.secondary,
                isSelected: _selectedRole == 'teacher',
                onTap: () => setState(() => _selectedRole = 'teacher'),
              ),
              
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Continue button
                    SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: AppTextStyles.buttonLarge,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Role selection card
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String helperText;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RoleCard({
    Key? key,
    required this.title,
    required this.description,
    required this.helperText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      color: isSelected
          ? color.withOpacity(0.1)
          : AppColors.background,
      border: Border.all(
        color: isSelected ? color : AppColors.border,
        width: isSelected ? 2 : 1,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  helperText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? color : AppColors.textPrimary.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: color,
              size: 28,
            ),
        ],
      ),
    );
  }
}
