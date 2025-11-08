import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

/// Primary button with clean design
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool fullWidth;
  final bool isLoading;
  final IconData? icon;
  
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppDesignSystem.primaryIndigo,
          foregroundColor: AppDesignSystem.backgroundWhite,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          disabledBackgroundColor: AppDesignSystem.textTertiary,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.backgroundWhite),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: AppTextStyles.buttonLarge),
                ],
              ),
      ),
    );
  }
}

/// Secondary button (outlined)
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool fullWidth;
  final IconData? icon;
  
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.fullWidth = false,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppDesignSystem.primaryIndigo;
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTextStyles.buttonLarge.copyWith(color: buttonColor),
            ),
          ],
        ),
      ),
    );
  }
}

