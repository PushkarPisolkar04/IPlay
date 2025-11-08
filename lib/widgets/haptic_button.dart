import 'package:flutter/material.dart';
import '../utils/haptic_feedback_util.dart';

/// Button with haptic feedback
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enableHaptic;

  const HapticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (enableHaptic) {
                HapticFeedbackUtil.lightImpact();
              }
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}

/// Text button with haptic feedback
class HapticTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enableHaptic;

  const HapticTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (enableHaptic) {
                HapticFeedbackUtil.lightImpact();
              }
              onPressed!();
            },
      style: style,
      child: child,
    );
  }
}

/// Icon button with haptic feedback
class HapticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;
  final bool enableHaptic;

  const HapticIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size,
    this.tooltip,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed == null
          ? null
          : () {
              if (enableHaptic) {
                HapticFeedbackUtil.lightImpact();
              }
              onPressed!();
            },
      color: color,
      iconSize: size,
      tooltip: tooltip,
    );
  }
}

/// Floating action button with haptic feedback
class HapticFloatingActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool enableHaptic;

  const HapticFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (enableHaptic) {
                HapticFeedbackUtil.mediumImpact();
              }
              onPressed!();
            },
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      child: child,
    );
  }
}

/// Card with haptic feedback on tap
class HapticCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool enableHaptic;

  const HapticCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  if (enableHaptic) {
                    HapticFeedbackUtil.lightImpact();
                  }
                  onTap!();
                },
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Switch with haptic feedback
class HapticSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final bool enableHaptic;

  const HapticSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              if (enableHaptic) {
                HapticFeedbackUtil.selectionClick();
              }
              onChanged!(newValue);
            },
      activeColor: activeColor,
    );
  }
}

/// Checkbox with haptic feedback
class HapticCheckbox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final bool enableHaptic;

  const HapticCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              if (enableHaptic) {
                HapticFeedbackUtil.selectionClick();
              }
              onChanged!(newValue);
            },
      activeColor: activeColor,
    );
  }
}

/// Radio button with haptic feedback
class HapticRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;
  final bool enableHaptic;

  const HapticRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.activeColor,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged == null
          ? null
          : (newValue) {
              if (enableHaptic) {
                HapticFeedbackUtil.selectionClick();
              }
              onChanged!(newValue);
            },
      activeColor: activeColor,
    );
  }
}
