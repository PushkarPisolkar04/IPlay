import 'package:flutter/material.dart';
import '../design/app_design_system.dart';

/// Clean, modern typography using Inter font
/// Fallback to system default if Inter not available
class AppTextStyles {
  static const String fontFamily = 'Inter';
  
  // HEADINGS
  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppDesignSystem.textPrimary,
    height: 1.3,
    letterSpacing: -0.5,
  );
  
  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.3,
  );
  
  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.4,
  );
  
  static const h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.4,
  );
  
  static const h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.4,
  );
  
  // BODY TEXT
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppDesignSystem.textPrimary,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppDesignSystem.textSecondary,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppDesignSystem.textTertiary,
    height: 1.4,
  );
  
  // BUTTON TEXT
  static const buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.backgroundWhite,
    height: 1.2,
  );
  
  static const buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.backgroundWhite,
    height: 1.2,
  );

  // Alias for compatibility
  static const button = buttonLarge;
  
  // LABELS
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppDesignSystem.textSecondary,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppDesignSystem.textTertiary,
    height: 1.2,
  );
  
  // SPECIAL PURPOSE
  static const sectionHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.3,
  );
  
  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppDesignSystem.textPrimary,
    height: 1.3,
  );
  
  static const cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppDesignSystem.textSecondary,
    height: 1.4,
  );
  
  // Helper methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }
  
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
