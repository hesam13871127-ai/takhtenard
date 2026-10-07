import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Application-wide [ThemeData]: a dark, luxurious Persian aesthetic.
///
/// All colors are applied with full alpha (no deprecated opacity APIs), and
/// the Vazirmatn font family is applied globally through the theme.
abstract final class AppTheme {
  static const String fontFamily = 'Vazirmatn';

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.gold,
        onPrimary: AppPalette.darkerBrown,
        secondary: AppPalette.emerald,
        onSecondary: AppPalette.ivory,
        surface: Color(0xFF221711),
        onSurface: AppPalette.textPrimary,
        error: AppPalette.dangerRed,
        outline: AppPalette.goldDark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: fontFamily,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppPalette.textPrimary,
        displayColor: AppPalette.textPrimary,
        fontFamily: fontFamily,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.gold,
          textStyle: const TextStyle(fontFamily: fontFamily),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2A1C15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.panelBorder),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppPalette.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          height: 1.8,
          color: AppPalette.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppPalette.panelBorder),
    );
  }
}
