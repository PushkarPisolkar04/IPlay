import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_text_styles.dart';

/// Banner to remind users to verify their email
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isResending = false;
  bool _isDismissed = false;

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verification email sent! Please check your inbox.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppDesignSystem.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // print('Error resending verification email: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to send verification email. Please try again later.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppDesignSystem.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email verified successfully! 🎉',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppDesignSystem.success,
                duration: const Duration(seconds: 3),
              ),
            );
            
            setState(() {
              _isDismissed = true;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Email not verified yet. Please check your inbox.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppDesignSystem.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // print('Error checking verification status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Don't show if user is null, email is verified, or banner is dismissed
    if (user == null || user.emailVerified || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppDesignSystem.warning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppDesignSystem.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppDesignSystem.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Email Not Verified',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppDesignSystem.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please verify your email to access all features',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _isResending ? null : _resendVerificationEmail,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _isResending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppDesignSystem.warning,
                          ),
                        ),
                      )
                    : Text(
                        'Resend',
                        style: TextStyle(
                          color: AppDesignSystem.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
              TextButton(
                onPressed: _checkVerificationStatus,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'I Verified',
                  style: TextStyle(
                    color: AppDesignSystem.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: AppDesignSystem.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Compact email verification indicator for app bar
class CompactEmailVerificationIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactEmailVerificationIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppDesignSystem.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppDesignSystem.warning,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Verify Email',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignSystem.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
