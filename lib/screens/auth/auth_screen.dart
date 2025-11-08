import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'signin_screen.dart';

/// Auth Screen - Main authentication screen (NO SKIP BUTTON)
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // print('✅ AuthScreen: Building auth screen');
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(vertical: 40),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logos/logo.png',
                      width: 150,
                      height: 150,
                    ),
                
                    const SizedBox(height: AppSpacing.xl),
                
                    // Title
                    Text(
                      'Welcome to IPlay',
                      style: AppTextStyles.h1,
                      textAlign: TextAlign.center,
                    ),
                
                    const SizedBox(height: AppSpacing.sm),
                
                    // Subtitle
                    Text(
                      'Learn IPR through fun games',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                
                    const SizedBox(height: AppSpacing.xl),
                
                    // Sign Up button - Now goes to Role Selection FIRST
                    PrimaryButton(
                      text: 'Create Account',
                      onPressed: () {
                        Navigator.pushNamed(context, '/role-selection');
                      },
                      fullWidth: true,
                    ),
                
                    const SizedBox(height: AppSpacing.md),
                
                    // Sign In button
                    SecondaryButton(
                      text: 'Sign In',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                      fullWidth: true,
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
