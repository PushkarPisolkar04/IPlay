import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/app_design_system.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

/// Clean card-based theme (no gradients)
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDesignSystem.primaryIndigo,
        primary: AppDesignSystem.primaryIndigo,
        secondary: AppDesignSystem.primaryPink,
        surface: AppDesignSystem.backgroundLight,
        error: AppDesignSystem.error,
      ),
      
      scaffoldBackgroundColor: AppDesignSystem.backgroundLight,
      fontFamily: AppTextStyles.fontFamily,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppDesignSystem.textPrimary,
        iconTheme: IconThemeData(color: AppDesignSystem.textPrimary),
        titleTextStyle: AppTextStyles.h3,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: const BorderSide(color: AppDesignSystem.backgroundGrey, width: 1),
        ),
        color: AppDesignSystem.backgroundLight,
        shadowColor: AppDesignSystem.shadowMD.first.color,
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
          ),
          backgroundColor: AppDesignSystem.primaryIndigo,
          foregroundColor: AppDesignSystem.backgroundWhite,
          textStyle: AppTextStyles.buttonLarge,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
          ),
          side: const BorderSide(color: AppDesignSystem.primaryIndigo, width: 2),
          foregroundColor: AppDesignSystem.primaryIndigo,
          textStyle: AppTextStyles.buttonLarge,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDesignSystem.primaryIndigo,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: const BorderSide(color: Colors.black38, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: const BorderSide(color: Colors.black38, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: const BorderSide(color: AppDesignSystem.primaryIndigo, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: const BorderSide(color: AppDesignSystem.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.large,
          borderSide: const BorderSide(color: AppDesignSystem.error, width: 2.5),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppDesignSystem.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppDesignSystem.textTertiary,
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h2,
        headlineMedium: AppTextStyles.h3,
        headlineSmall: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonLarge,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppDesignSystem.backgroundGrey,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppDesignSystem.textPrimary,
        size: 24,
      ),
    );
  }
}
