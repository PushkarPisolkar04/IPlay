import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';

/// Role Selection Screen - Choose between Student/Teacher (NOT Principal)
/// Note: Principal is NOT a signup role. Teachers become Principals by creating a school.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppDesignSystem.primaryIndigo,
              AppDesignSystem.secondaryPurple,
              AppDesignSystem.primaryPink,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppDesignSystem.primaryIndigo,
                                AppDesignSystem.primaryPink,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome!',
                                style: AppTextStyles.h1.copyWith(fontSize: 28),
                              ),
                              Text(
                                'Let\'s get started',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppDesignSystem.info.withValues(alpha: 0.1),
                            AppDesignSystem.primaryTeal.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesignSystem.info.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppDesignSystem.info, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose your role to unlock a personalized experience!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppDesignSystem.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    _RoleCard(
                      title: 'Student',
                      description: 'Learn IPR through games and challenges',
                      helperText: 'Join a classroom or learn solo - your choice!',
                      icon: Icons.school,
                      color: AppDesignSystem.primaryIndigo,
                      isSelected: _selectedRole == 'student',
                      onTap: () => setState(() => _selectedRole = 'student'),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    _RoleCard(
                      title: 'Teacher',
                      description: 'Manage classrooms and track student progress',
                      helperText: 'First in your school? You\'ll become principal!',
                      icon: Icons.person,
                      color: AppDesignSystem.primaryPink,
                      isSelected: _selectedRole == 'teacher',
                      onTap: () => setState(() => _selectedRole = 'teacher'),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: _selectedRole != null ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'student'
                              ? AppDesignSystem.primaryIndigo
                              : AppDesignSystem.primaryPink,
                          disabledBackgroundColor: AppDesignSystem.textTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          elevation: 5,
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String helperText;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RoleCard({
    required this.title,
    required this.description,
    required this.helperText,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isSelected ? null : AppDesignSystem.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : AppDesignSystem.backgroundGrey,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                          )
                        : null,
                    color: isSelected ? null : color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 32,
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
                          color: isSelected ? color : AppDesignSystem.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: isSelected ? color : AppDesignSystem.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              helperText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? color : AppDesignSystem.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
