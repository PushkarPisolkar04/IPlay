import 'package:flutter/material.dart';

/// Game-specific color palette for the games overhaul
/// Provides vibrant colors for each game type and feedback colors
class GameColors {
  // ============================================================================
  // GAME-SPECIFIC COLORS
  // ============================================================================
  
  /// Quiz Master - Indigo
  static const Color quizMaster = Color(0xFF6366F1);
  static const Color quizMasterLight = Color(0xFF818CF8);
  static const Color quizMasterDark = Color(0xFF4F46E5);
  
  /// Trademark Match - Blue
  static const Color trademarkMatch = Color(0xFF2196F3);
  static const Color trademarkMatchLight = Color(0xFF42A5F5);
  static const Color trademarkMatchDark = Color(0xFF1976D2);
  
  /// IP Defender - Pink
  static const Color ipDefender = Color(0xFFE91E63);
  static const Color ipDefenderLight = Color(0xFFEC407A);
  static const Color ipDefenderDark = Color(0xFFC2185B);
  
  /// Spot the Original - Orange
  static const Color spotOriginal = Color(0xFFFF6B35);
  static const Color spotOriginalLight = Color(0xFFFF8A65);
  static const Color spotOriginalDark = Color(0xFFE64A19);
  
  /// GI Mapper - Amber
  static const Color giMapper = Color(0xFFFFC107);
  static const Color giMapperLight = Color(0xFFFFCA28);
  static const Color giMapperDark = Color(0xFFFFA000);
  
  /// Patent Detective - Cyan
  static const Color patentDetective = Color(0xFF00BCD4);
  static const Color patentDetectiveLight = Color(0xFF26C6DA);
  static const Color patentDetectiveDark = Color(0xFF0097A7);
  
  /// Innovation Lab - Green
  static const Color innovationLab = Color(0xFF4CAF50);
  static const Color innovationLabLight = Color(0xFF66BB6A);
  static const Color innovationLabDark = Color(0xFF388E3C);
  
  // ============================================================================
  // FEEDBACK COLORS
  // ============================================================================
  
  /// Correct answer - Green
  static const Color correct = Color(0xFF4CAF50);
  static const Color correctLight = Color(0xFF66BB6A);
  static const Color correctDark = Color(0xFF388E3C);
  
  /// Incorrect answer - Red
  static const Color incorrect = Color(0xFFF44336);
  static const Color incorrectLight = Color(0xFFEF5350);
  static const Color incorrectDark = Color(0xFFD32F2F);
  
  /// Hint - Orange
  static const Color hint = Color(0xFFFF9800);
  static const Color hintLight = Color(0xFFFFB74D);
  static const Color hintDark = Color(0xFFF57C00);
  
  /// Warning - Amber
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFCA28);
  static const Color warningDark = Color(0xFFFFA000);
  
  /// Info - Blue
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF42A5F5);
  static const Color infoDark = Color(0xFF1976D2);
  
  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================
  
  /// Quiz Master gradient (purple to blue)
  static const LinearGradient quizMasterGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Trademark Match gradient (blue shades)
  static const LinearGradient trademarkMatchGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF03A9F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// IP Defender gradient (pink to purple)
  static const LinearGradient ipDefenderGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Spot the Original gradient (orange shades)
  static const LinearGradient spotOriginalGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// GI Mapper gradient (amber to yellow)
  static const LinearGradient giMapperGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFFFEB3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Patent Detective gradient (cyan to teal)
  static const LinearGradient patentDetectiveGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF009688)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Innovation Lab gradient (green shades)
  static const LinearGradient innovationLabGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Correct answer gradient
  static const LinearGradient correctGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Incorrect answer gradient
  static const LinearGradient incorrectGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Hint gradient
  static const LinearGradient hintGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================================================
  // HIGH CONTRAST COLOR SCHEMES
  // ============================================================================
  
  /// High contrast correct color (darker green for better visibility)
  static const Color correctHighContrast = Color(0xFF2E7D32);
  
  /// High contrast incorrect color (darker red for better visibility)
  static const Color incorrectHighContrast = Color(0xFFC62828);
  
  /// High contrast hint color (darker orange for better visibility)
  static const Color hintHighContrast = Color(0xFFE65100);
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get game color by game type
  static Color getGameColor(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'quiz_master':
      case 'quizmaster':
        return quizMaster;
      case 'trademark_match':
      case 'trademarkmatch':
        return trademarkMatch;
      case 'ip_defender':
      case 'ipdefender':
        return ipDefender;
      case 'spot_the_original':
      case 'spottheoriginal':
        return spotOriginal;
      case 'gi_mapper':
      case 'gimapper':
        return giMapper;
      case 'patent_detective':
      case 'patentdetective':
        return patentDetective;
      case 'innovation_lab':
      case 'innovationlab':
        return innovationLab;
      default:
        return quizMaster;
    }
  }
  
  /// Get game gradient by game type
  static LinearGradient getGameGradient(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'quiz_master':
      case 'quizmaster':
        return quizMasterGradient;
      case 'trademark_match':
      case 'trademarkmatch':
        return trademarkMatchGradient;
      case 'ip_defender':
      case 'ipdefender':
        return ipDefenderGradient;
      case 'spot_the_original':
      case 'spottheoriginal':
        return spotOriginalGradient;
      case 'gi_mapper':
      case 'gimapper':
        return giMapperGradient;
      case 'patent_detective':
      case 'patentdetective':
        return patentDetectiveGradient;
      case 'innovation_lab':
      case 'innovationlab':
        return innovationLabGradient;
      default:
        return quizMasterGradient;
    }
  }
  
  /// Get feedback color by type
  static Color getFeedbackColor(String feedbackType, {bool highContrast = false}) {
    switch (feedbackType.toLowerCase()) {
      case 'correct':
      case 'success':
        return highContrast ? correctHighContrast : correct;
      case 'incorrect':
      case 'error':
      case 'wrong':
        return highContrast ? incorrectHighContrast : incorrect;
      case 'hint':
      case 'help':
        return highContrast ? hintHighContrast : hint;
      case 'warning':
        return warning;
      case 'info':
        return info;
      default:
        return info;
    }
  }
  
  /// Get feedback gradient by type
  static LinearGradient getFeedbackGradient(String feedbackType) {
    switch (feedbackType.toLowerCase()) {
      case 'correct':
      case 'success':
        return correctGradient;
      case 'incorrect':
      case 'error':
      case 'wrong':
        return incorrectGradient;
      case 'hint':
      case 'help':
        return hintGradient;
      default:
        return correctGradient;
    }
  }
  
  /// Create a color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Get text color for background (ensures readability)
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  }
}
