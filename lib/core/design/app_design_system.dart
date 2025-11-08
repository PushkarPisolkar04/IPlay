import 'package:flutter/material.dart';

/// AppDesignSystem - Unified design system for IPlay
/// Provides vibrant, gamified colors, typography, spacing, and shadows
class AppDesignSystem {
  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryAmber = Color(0xFFF59E0B);

  // ============================================================================
  // SECONDARY COLORS
  // ============================================================================
  static const Color secondaryPurple = Color(0xFF8B5CF6);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color secondaryRed = Color(0xFFEF4444);
  static const Color secondaryTeal = Color(0xFF14B8A6);

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF3F4F6);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ============================================================================
  // GRADIENTS
  // ============================================================================
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryIndigo, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [primaryGreen, secondaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarning = LinearGradient(
    colors: [primaryAmber, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientError = LinearGradient(
    colors: [secondaryRed, Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  // Font Families
  static const String fontFamilyHeading = 'Poppins';
  static const String fontFamilyBody = 'Inter';

  // Headings (Poppins)
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamilyHeading,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );

  // Body Text (Inter)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  // Special Text Styles
  static const TextStyle button = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  // ============================================================================
  // SPACING (8px Grid System)
  // ============================================================================
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  // BorderRadius objects for convenience
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // ============================================================================
  // SHADOWS
  // ============================================================================
  static const List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0,0,0,0.05)
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.1)
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.1)
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowXL = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,0.15)
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // ROLE-BASED COLORS
  // ============================================================================
  
  /// Get color for student role
  static Color getStudentColor() => primaryIndigo;
  
  /// Get color for teacher role
  static Color getTeacherColor() => primaryPink;
  
  /// Get color for principal role
  static Color getPrincipalColor() => primaryAmber;
  
  /// Get color based on role string
  static Color getRoleColor(String role, {bool isPrincipal = false}) {
    if (isPrincipal) return getPrincipalColor();
    
    switch (role.toLowerCase()) {
      case 'student':
        return getStudentColor();
      case 'teacher':
        return getTeacherColor();
      default:
        return primaryIndigo;
    }
  }

  /// Get gradient for role
  static LinearGradient getRoleGradient(String role, {bool isPrincipal = false}) {
    if (isPrincipal) {
      return const LinearGradient(
        colors: [primaryAmber, Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    switch (role.toLowerCase()) {
      case 'student':
        return gradientPrimary;
      case 'teacher':
        return const LinearGradient(
          colors: [primaryPink, secondaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return gradientPrimary;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Create a color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get text color based on background brightness
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : backgroundWhite;
  }

  /// Get accessible text color for button backgrounds (WCAG AA compliant)
  /// Returns dark text for light backgrounds (amber, light green)
  /// Returns white text for dark backgrounds (indigo, pink, purple, etc.)
  static Color getAccessibleButtonTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    
    // For very light backgrounds (amber, light green), use dark text
    if (luminance > 0.5) {
      return textPrimary;
    }
    
    // For dark backgrounds, use white text
    return backgroundWhite;
  }

  /// Check if a color combination meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    final ratio = (lighter + 0.05) / (darker + 0.05);
    return ratio >= 4.5;
  }

  /// Create a decoration with gradient and shadow
  static BoxDecoration gradientDecoration({
    required LinearGradient gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius ?? borderRadiusMD,
      boxShadow: boxShadow ?? shadowMD,
    );
  }

  /// Create a decoration with solid color and shadow
  static BoxDecoration solidDecoration({
    required Color color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? borderRadiusMD,
      boxShadow: boxShadow,
      border: border,
    );
  }

  /// Create a bordered decoration
  static BoxDecoration borderedDecoration({
    required Color borderColor,
    double borderWidth = 2.0,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundWhite,
      borderRadius: borderRadius ?? borderRadiusMD,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
    );
  }

  // ============================================================================
  // THEME DATA
  // ============================================================================
  
  /// Get ThemeData for the app
  static ThemeData getThemeData() {
    return ThemeData(
      primaryColor: primaryIndigo,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: fontFamilyBody,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: secondaryPurple,
        error: error,
        surface: backgroundWhite,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: h5,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: h1,
        displayMedium: h2,
        displaySmall: h3,
        headlineMedium: h4,
        headlineSmall: h5,
        titleLarge: h6,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: button,
        labelSmall: caption,
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: backgroundWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMD,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: backgroundWhite,
          textStyle: button,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMD,
          ),
          elevation: 0,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: const BorderSide(color: backgroundGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: const BorderSide(color: backgroundGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMD,
          borderSide: const BorderSide(color: error),
        ),
      ),
    );
  }
}
