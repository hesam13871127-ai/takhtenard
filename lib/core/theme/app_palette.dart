import 'package:flutter/material.dart';

/// Luxurious Persian color palette used across the whole app.
///
/// Primary: deep walnut brown + rich gold.
/// Secondary: emerald green + ivory cream.
/// Accent: warm amber / soft ruby.
abstract final class AppPalette {
  // Brand colors -----------------------------------------------------------
  static const Color deepBrown = Color(0xFF3E2723);
  static const Color darkerBrown = Color(0xFF241612);
  static const Color nearBlack = Color(0xFF15100D);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE9CE7A);
  static const Color goldDark = Color(0xFF8C7020);

  static const Color emerald = Color(0xFF00695C);
  static const Color emeraldDark = Color(0xFF004D40);

  static const Color ivory = Color(0xFFF5EAD6);
  static const Color ivorySoft = Color(0xFFE8DDC4);

  static const Color amberAccent = Color(0xFFFFB74D);
  static const Color rubyAccent = Color(0xFFB2495E);

  // Semantic ---------------------------------------------------------------
  static const Color whiteChecker = Color(0xFFF3E9D4);
  static const Color blackChecker = Color(0xFF241A16);

  static const Color textPrimary = Color(0xFFF2E9DC);
  static const Color textSecondary = Color(0xFFC9BBA3);
  static const Color textFaint = Color(0xFF8F8371);

  static const Color successGreen = Color(0xFF66BB6A);
  static const Color dangerRed = Color(0xFFE57373);

  // Gradients --------------------------------------------------------------
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1B15), Color(0xFF171008), Color(0xFF0D0906)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF33221B), Color(0xFF221610)],
  );

  /// Gold-ish border for luxury panels.
  static const Color panelBorder = Color(0x66D4AF37);
}
