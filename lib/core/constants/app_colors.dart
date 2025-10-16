import 'package:flutter/material.dart';

/// IPlay Clean Card-Based Design Colors
/// No gradients, solid colors only
class AppColors {
  // PRIMARY BRAND COLORS
  static const primary = Color(0xFF7B68EE);      // Purple
  static const primaryDark = Color(0xFF5E4CC5);  // Darker purple
  static const primaryLight = Color(0xFF9B8FF5); // Light purple
  
  static const secondary = Color(0xFFFF6B35);    // Orange
  static const secondaryLight = Color(0xFFFF8F5C);
  
  static const accent = Color(0xFFFFC107);       // Yellow/Gold
  static const accentBlue = Color(0xFF2196F3);   // Blue
  
  // BACKGROUND COLORS
  static const background = Color(0xFFFFFFFF);   // Pure white
  static const backgroundGrey = Color(0xFFF5F7FA); // Very light grey
  
  // CARD COLORS (Solid, no gradients)
  static const cardPurple = Color(0xFF7B68EE);
  static const cardOrange = Color(0xFFFF6B35);
  static const cardYellow = Color(0xFFFFC107);
  static const cardBlue = Color(0xFF2196F3);
  static const cardGreen = Color(0xFF4CAF50);
  static const cardPink = Color(0xFFE91E63);
  static const cardTeal = Color(0xFF009688);
  static const cardIndigo = Color(0xFF3F51B5);
  static const cardBackground = Color(0xFFFFFFFF); // White background for cards
  
  // TEXT COLORS
  static const textPrimary = Color(0xFF2D3748);    // Dark grey
  static const textSecondary = Color(0xFF718096);  // Medium grey
  static const textTertiary = Color(0xFFA0AEC0);   // Light grey
  static const textWhite = Color(0xFFFFFFFF);      // White
  static const textLight = Color(0xFFFFFFFF);      // White (alias for compatibility)
  
  // SEMANTIC COLORS
  static const success = Color(0xFF4CAF50);        // Green
  static const warning = Color(0xFFFFC107);        // Yellow
  static const error = Color(0xFFFF5252);          // Red
  static const info = Color(0xFF2196F3);           // Blue
  
  // REALM COLORS (Solid colors for each realm)
  static const realmCopyright = Color(0xFFFF6B35);      // Orange
  static const realmTrademark = Color(0xFF2196F3);      // Blue
  static const realmPatent = Color(0xFF4CAF50);         // Green
  static const realmDesign = Color(0xFFE91E63);         // Pink
  static const realmGI = Color(0xFFFFC107);              // Yellow
  static const realmTradeSecret = Color(0xFF9C27B0);    // Purple
  
  // BORDERS & DIVIDERS
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);
  
  // SHADOWS (for cards)
  static const cardShadow = BoxShadow(
    color: Color(0x1A000000),  // 10% black
    blurRadius: 20,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );
  
  static const cardShadowHover = BoxShadow(
    color: Color(0x26000000),  // 15% black
    blurRadius: 30,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );
  
  // GRADIENTS (for backward compatibility with older screens)
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFE55A2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const backgroundGradient = LinearGradient(
    colors: [background, backgroundGrey],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Helper: Get realm color by type
  static Color getRealmColor(String realmType) {
    switch (realmType.toLowerCase()) {
      case 'copyright':
        return realmCopyright;
      case 'trademark':
        return realmTrademark;
      case 'patent':
        return realmPatent;
      case 'design':
        return realmDesign;
      case 'gi':
      case 'geographical indication':
        return realmGI;
      case 'trade secret':
      case 'tradesecret':
        return realmTradeSecret;
      default:
        return cardPurple;
    }
  }
}
