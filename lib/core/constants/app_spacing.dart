import 'package:flutter/material.dart';

/// Consistent spacing system for clean card-based design
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Card specific
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double cardSpacing = 12.0;
  
  // Screen padding
  static const double screenHorizontal = 16.0;
  static const double screenVertical = 16.0;
  
  // Component sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 80.0;
  static const double avatarXLarge = 120.0;
  
  // Navigation
  static const double bottomNavHeight = 70.0;
  static const double bottomNavIconSize = 28.0;
  static const double appBarHeight = 56.0;
}

/// Border radius values
class AppRadius {
  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const xlarge = BorderRadius.all(Radius.circular(24));
  static const round = BorderRadius.all(Radius.circular(9999));
}
