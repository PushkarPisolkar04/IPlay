import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/theme/game_colors.dart';
import '../../utils/haptic_feedback_util.dart';

/// Game button with automatic haptic feedback
/// Provides visual and haptic feedback on tap
class GameHapticButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isOutlined;
  final bool isDisabled;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const GameHapticButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isOutlined = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<GameHapticButton> createState() => _GameHapticButtonState();
}

class _GameHapticButtonState extends State<GameHapticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedbackUtil.buttonTap();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? GameColors.quizMaster;
    final buttonTextColor = widget.textColor ??
        GameColors.getTextColorForBackground(buttonColor);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 50,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingLG,
                    vertical: AppDesignSystem.spacingMD,
                  ),
              decoration: BoxDecoration(
                color: widget.isOutlined
                    ? Colors.transparent
                    : (widget.isDisabled
                        ? AppDesignSystem.backgroundGrey
                        : buttonColor),
                borderRadius: AppDesignSystem.borderRadiusLG,
                border: widget.isOutlined
                    ? Border.all(
                        color: widget.isDisabled
                            ? AppDesignSystem.backgroundGrey
                            : buttonColor,
                        width: 2,
                      )
                    : null,
                boxShadow: widget.isDisabled || _isPressed
                    ? null
                    : AppDesignSystem.shadowMD,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isOutlined
                          ? (widget.isDisabled
                              ? AppDesignSystem.textTertiary
                              : buttonColor)
                          : (widget.isDisabled
                              ? AppDesignSystem.textTertiary
                              : buttonTextColor),
                      size: 20,
                    ),
                    const SizedBox(width: AppDesignSystem.spacingSM),
                  ],
                  Text(
                    widget.text,
                    style: AppDesignSystem.button.copyWith(
                      color: widget.isOutlined
                          ? (widget.isDisabled
                              ? AppDesignSystem.textTertiary
                              : buttonColor)
                          : (widget.isDisabled
                              ? AppDesignSystem.textTertiary
                              : buttonTextColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Icon button with haptic feedback
class GameHapticIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const GameHapticIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: size),
      color: color ?? AppDesignSystem.textPrimary,
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedbackUtil.buttonTap();
              onPressed!();
            },
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Floating action button with haptic feedback
class GameHapticFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool mini;

  const GameHapticFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.mini = false,
  });

  @override
  State<GameHapticFAB> createState() => _GameHapticFABState();
}

class _GameHapticFABState extends State<GameHapticFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      HapticFeedbackUtil.buttonTap();
      _controller.forward().then((_) => _controller.reverse());
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      mini: widget.mini,
      backgroundColor: widget.backgroundColor ?? GameColors.quizMaster,
      foregroundColor: widget.foregroundColor ?? Colors.white,
      onPressed: _handleTap,
      child: Icon(widget.icon),
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.tooltip != null
              ? Tooltip(message: widget.tooltip!, child: fab)
              : fab,
        );
      },
    );
  }
}
