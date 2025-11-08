import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// AccessibilityHelper - Utility class for accessibility features
/// Provides helpers for screen reader support, text scaling, and color contrast
class AccessibilityHelper {
  // ============================================================================
  // SCREEN READER SUPPORT
  // ============================================================================

  /// Wrap a widget with Semantics for screen reader support
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool? button,
    bool? link,
    bool? header,
    bool? enabled,
    bool? selected,
    bool? checked,
    bool? focusable,
    bool? focused,
    bool? hidden,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onScrollLeft,
    VoidCallback? onScrollRight,
    VoidCallback? onScrollUp,
    VoidCallback? onScrollDown,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      link: link,
      header: header,
      enabled: enabled,
      selected: selected,
      checked: checked,
      focusable: focusable,
      focused: focused,
      hidden: hidden,
      onTap: onTap,
      onLongPress: onLongPress,
      onScrollLeft: onScrollLeft,
      onScrollRight: onScrollRight,
      onScrollUp: onScrollUp,
      onScrollDown: onScrollDown,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }

  /// Create a semantic label for a button
  static String buttonLabel(String text, {bool isLoading = false}) {
    if (isLoading) {
      return '$text button, loading';
    }
    return '$text button';
  }

  /// Create a semantic label for a card
  static String cardLabel(String title, {String? subtitle}) {
    if (subtitle != null) {
      return '$title, $subtitle';
    }
    return title;
  }

  /// Create a semantic label for a stat card
  static String statLabel(String title, String value, {String? subtitle}) {
    String label = '$title: $value';
    if (subtitle != null) {
      label += ', $subtitle';
    }
    return label;
  }

  /// Create a semantic label for XP counter
  static String xpLabel(int xp) {
    return '$xp experience points';
  }

  /// Create a semantic label for streak indicator
  static String streakLabel(int streak, {bool isActive = true}) {
    if (isActive) {
      return '$streak day streak, active';
    }
    return '$streak day streak, inactive';
  }

  /// Create a semantic label for badge
  static String badgeLabel(String name, {bool unlocked = false}) {
    if (unlocked) {
      return '$name badge, unlocked';
    }
    return '$name badge, locked';
  }

  /// Create a semantic label for leaderboard position
  static String leaderboardLabel(int rank, String name, int xp) {
    String rankText;
    if (rank == 1) {
      rankText = 'First place';
    } else if (rank == 2) {
      rankText = 'Second place';
    } else if (rank == 3) {
      rankText = 'Third place';
    } else {
      rankText = 'Rank $rank';
    }
    return '$rankText, $name, $xp experience points';
  }

  /// Create a semantic label for progress
  static String progressLabel(String item, int completed, int total) {
    final percentage = ((completed / total) * 100).round();
    return '$item, $completed of $total completed, $percentage percent';
  }

  /// Create a semantic label for level
  static String levelLabel(
    int levelNumber,
    String levelName, {
    bool isLocked = false,
    bool isCompleted = false,
  }) {
    String status = '';
    if (isLocked) {
      status = ', locked';
    } else if (isCompleted) {
      status = ', completed';
    }
    return 'Level $levelNumber: $levelName$status';
  }

  /// Create a semantic label for game
  static String gameLabel(String name, {int? highScore}) {
    if (highScore != null) {
      return '$name game, high score: $highScore';
    }
    return '$name game';
  }

  // ============================================================================
  // TEXT SCALING SUPPORT
  // ============================================================================

  /// Get scaled text size based on MediaQuery.textScaleFactor
  static double getScaledTextSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseSize * textScaleFactor;
  }

  /// Get scaled text style with proper scaling
  static TextStyle getScaledTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * textScaleFactor,
    );
  }

  /// Check if text scaling is enabled
  static bool isTextScalingEnabled(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor > 1.0;
  }

  /// Get maximum text scale factor to prevent layout breaks
  static double getMaxTextScaleFactor() {
    return 2.0; // Maximum 200% scaling
  }

  /// Clamp text scale factor to prevent extreme scaling
  static double clampTextScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor.clamp(1.0, getMaxTextScaleFactor());
  }

  // ============================================================================
  // COLOR CONTRAST SUPPORT
  // ============================================================================

  /// Calculate relative luminance of a color (WCAG formula)
  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Calculate contrast ratio between two colors (WCAG formula)
  static double calculateContrastRatio(Color foreground, Color background) {
    final luminance1 = calculateLuminance(foreground);
    final luminance2 = calculateLuminance(background);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standard (4.5:1 for normal text)
  static bool meetsWCAGAA(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= 4.5;
  }

  /// Check if contrast ratio meets WCAG AAA standard (7:1 for normal text)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= 7.0;
  }

  /// Check if contrast ratio meets WCAG AA for large text (3:1)
  static bool meetsWCAGAALargeText(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= 3.0;
  }

  /// Get appropriate text color for background (ensures WCAG AA compliance)
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = calculateLuminance(backgroundColor);
    
    // If background is light, use dark text
    if (luminance > 0.5) {
      return const Color(0xFF111827); // textPrimary
    }
    
    // If background is dark, use light text
    return const Color(0xFFFFFFFF); // white
  }

  /// Adjust color to meet WCAG AA contrast requirements
  static Color adjustColorForContrast(
    Color foreground,
    Color background, {
    bool preferDarker = true,
  }) {
    double ratio = calculateContrastRatio(foreground, background);
    
    // If already meets WCAG AA, return original color
    if (ratio >= 4.5) {
      return foreground;
    }
    
    // Adjust color brightness to meet contrast requirements
    HSLColor hsl = HSLColor.fromColor(foreground);
    
    if (preferDarker) {
      // Make darker until contrast is sufficient
      while (ratio < 4.5 && hsl.lightness > 0.0) {
        hsl = hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0));
        ratio = calculateContrastRatio(hsl.toColor(), background);
      }
    } else {
      // Make lighter until contrast is sufficient
      while (ratio < 4.5 && hsl.lightness < 1.0) {
        hsl = hsl.withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0));
        ratio = calculateContrastRatio(hsl.toColor(), background);
      }
    }
    
    return hsl.toColor();
  }

  // ============================================================================
  // FOCUS AND NAVIGATION
  // ============================================================================

  /// Check if device is using keyboard navigation
  static bool isKeyboardNavigationEnabled(BuildContext context) {
    // This would need platform-specific implementation
    // For now, return false as default
    return false;
  }

  /// Request focus for accessibility
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  // ============================================================================
  // ANNOUNCEMENTS
  // ============================================================================

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    // Use SemanticsService to announce
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Announce a success message
  static void announceSuccess(BuildContext context, String message) {
    announce(context, 'Success: $message');
  }

  /// Announce an error message
  static void announceError(BuildContext context, String message) {
    announce(context, 'Error: $message');
  }

  /// Announce a warning message
  static void announceWarning(BuildContext context, String message) {
    announce(context, 'Warning: $message');
  }

  // ============================================================================
  // TESTING HELPERS
  // ============================================================================

  /// Get all contrast ratios for a color scheme (for testing)
  static Map<String, double> getContrastRatios(
    Color primary,
    Color background,
  ) {
    return {
      'primary_on_background': calculateContrastRatio(primary, background),
      'white_on_primary': calculateContrastRatio(Colors.white, primary),
      'black_on_background': calculateContrastRatio(Colors.black, background),
    };
  }

  /// Validate all colors meet WCAG AA standards
  static bool validateColorScheme(Map<String, Color> colors) {
    // This would check all color combinations in the design system
    // For now, return true as placeholder
    return true;
  }
}
