import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../utils/accessibility_helper.dart';

/// AppButton - Reusable button widget with 5 types
/// Types: primary, secondary, accent, outline, text
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  });

  /// Primary button with gradient background and white text
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  })  : type = AppButtonType.primary;

  /// Secondary button with solid color and white text
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  })  : type = AppButtonType.secondary;

  /// Accent button with accent color and white text
  const AppButton.accent({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  })  : type = AppButtonType.accent;

  /// Outline button with border only and colored text
  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  })  : type = AppButtonType.outline;

  /// Text button with no background and colored text
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  })  : type = AppButtonType.text;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacingLG,
          vertical: AppDesignSystem.spacingMD,
        );

    Widget buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppDesignSystem.spacingSM),
          ],
          Text(
            text,
            style: AppDesignSystem.button,
          ),
        ],
      ],
    );

    // Wrap with Semantics for screen reader support
    Widget accessibleButton;

    switch (type) {
      case AppButtonType.primary:
        accessibleButton = _buildGradientButton(
          context,
          buttonChild,
          effectivePadding,
          AppDesignSystem.gradientPrimary,
        );
        break;

      case AppButtonType.secondary:
        accessibleButton = _buildSolidButton(
          context,
          buttonChild,
          effectivePadding,
          AppDesignSystem.secondaryPurple,
        );
        break;

      case AppButtonType.accent:
        accessibleButton = _buildSolidButton(
          context,
          buttonChild,
          effectivePadding,
          AppDesignSystem.primaryPink,
        );
        break;

      case AppButtonType.outline:
        accessibleButton = _buildOutlineButton(
          context,
          buttonChild,
          effectivePadding,
        );
        break;

      case AppButtonType.text:
        accessibleButton = _buildTextButton(
          context,
          buttonChild,
          effectivePadding,
        );
        break;
    }

    // Add Semantics wrapper for accessibility
    return AccessibilityHelper.withSemantics(
      label: AccessibilityHelper.buttonLabel(text, isLoading: isLoading),
      hint: onPressed == null ? 'Button is disabled' : null,
      button: true,
      enabled: onPressed != null && !isLoading,
      onTap: onPressed,
      child: accessibleButton,
    );
  }

  Widget _buildGradientButton(
    BuildContext context,
    Widget child,
    EdgeInsets padding,
    LinearGradient gradient,
  ) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? AppDesignSystem.textTertiary : null,
        borderRadius: AppDesignSystem.borderRadiusMD,
        boxShadow: onPressed != null ? AppDesignSystem.shadowMD : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppDesignSystem.borderRadiusMD,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: AppDesignSystem.button.copyWith(
                color: AppDesignSystem.backgroundWhite,
              ),
              child: IconTheme(
                data: const IconThemeData(
                  color: AppDesignSystem.backgroundWhite,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolidButton(
    BuildContext context,
    Widget child,
    EdgeInsets padding,
    Color color,
  ) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: onPressed != null ? color : AppDesignSystem.textTertiary,
        borderRadius: AppDesignSystem.borderRadiusMD,
        boxShadow: onPressed != null ? AppDesignSystem.shadowSM : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppDesignSystem.borderRadiusMD,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: AppDesignSystem.button.copyWith(
                color: AppDesignSystem.backgroundWhite,
              ),
              child: IconTheme(
                data: const IconThemeData(
                  color: AppDesignSystem.backgroundWhite,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
    BuildContext context,
    Widget child,
    EdgeInsets padding,
  ) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundWhite,
        borderRadius: AppDesignSystem.borderRadiusMD,
        border: Border.all(
          color: onPressed != null
              ? AppDesignSystem.primaryIndigo
              : AppDesignSystem.textTertiary,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppDesignSystem.borderRadiusMD,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle(
              style: AppDesignSystem.button.copyWith(
                color: onPressed != null
                    ? AppDesignSystem.primaryIndigo
                    : AppDesignSystem.textTertiary,
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: onPressed != null
                      ? AppDesignSystem.primaryIndigo
                      : AppDesignSystem.textTertiary,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    Widget child,
    EdgeInsets padding,
  ) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: AppDesignSystem.borderRadiusMD,
      child: Padding(
        padding: padding,
        child: DefaultTextStyle(
          style: AppDesignSystem.button.copyWith(
            color: onPressed != null
                ? AppDesignSystem.primaryIndigo
                : AppDesignSystem.textTertiary,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: onPressed != null
                  ? AppDesignSystem.primaryIndigo
                  : AppDesignSystem.textTertiary,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum AppButtonType {
  primary,
  secondary,
  accent,
  outline,
  text,
}
