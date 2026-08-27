import 'package:flutter/material.dart';

/// App Theme with Iranian Golden Theme Colors
class AppTheme {
  // Iranian golden color scheme
  static const Color primaryGold = Color(0xFFC9A963);   // Main golden accent
  static const Color secondaryGold = Color(0xFFD4B650); // Light gold
  static const Color deepGold = Color(0xFFB58732);      // Dark gold
  
  // Primary colors
  static const Color cream = Color(0xFFFFF3E0);          // Main background
  static const Color warmWhite = Color(0xFFFFF8E1);      // Warm white
  static const Color lightBrown = Color(0xFFFFF0E1);    // Light board
  
  // Text colors
  static const Color darkText = Color(0xFF2C1810);      // Primary text
  static const Color mediumText = Color(0xFF4A3226);    // Secondary text
  static const Color mutedText = Color(0xFF6D4A28);     // Muted text
  
  // UI colors
  static const Color accent = Color(0xFFC9A963);        // Accent/gold
  static const Color divider = Color(0xFFE8E4DC);       // Dividers
  
  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);  // Light shadow
  static const Color shadowMedium = Color(0x3A000000); // Medium shadow
  
  // Game specific colors
  static const Color whitePieces = Color(0xFFFFF3E0);   // White pieces
  static const Color blackPieces = Color(0xFF2C1810);   // Black pieces
  static const Color barWhite = Color(0xFFFFF3E0);      // Bar - white
  static const Color barBlack = Color(0xFF2C1810);      // Bar - black
  
  /// Get text theme
  static TextTheme get textTheme => TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'IranSans',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
    titleLarge: TextStyle(
      fontFamily: 'IranSans',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'IranSans',
      fontSize: 16,
      color: mediumText,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'IranSans',
      fontSize: 14,
      color: mediumText,
    ),
    labelLarge: TextStyle(
      fontFamily: 'IranSans',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: darkText,
    ),
  );
  
  /// Get elevated button style
  static ElevatedButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryGold,
    foregroundColor: darkText,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );
  
  /// Get outlined button style
  static OutlinedButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryGold,
    side: BorderSide(color: primaryGold, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  /// Get input decoration
  InputDecoration get inputDecoration => InputDecoration(
    hintText: '',
    hintStyle: TextStyle(color: mediumText.withOpacity(0.5)),
    filled: true,
    fillColor: warmWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryGold, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryGold, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryGold, width: 2),
    ),
  );
  
  /// Get card theme
  CardTheme get cardTheme => const CardTheme(
    color: warmWhite,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  /// Get scaffold background
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGold,
      brightness: Brightness.light,
      primary: primaryGold,
      secondary: secondaryGold,
      surface: warmWhite,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: cream,
    textTheme: textTheme,
    elevatedButtonTheme: ElevatedButton.styleFrom(
      backgroundColor: primaryGold,
      foregroundColor: darkText,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    outlinedButtonTheme: OutlinedButton.styleFrom(
      foregroundColor: primaryGold,
      side: BorderSide(color: primaryGold, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}