import 'package:flutter/material.dart';

/// Visual theme of the game board. Three premium looks are available;
/// pure geometry stays identical — only colors change.
class BoardThemeData {
  const BoardThemeData({
    required this.id,
    required this.name,
    required this.frameLight,
    required this.frameDark,
    required this.playfieldTint,
    required this.pointA,
    required this.pointB,
    required this.pointEdge,
    required this.barColor,
    required this.barInlay,
    required this.trayColor,
    required this.traySlot,
    required this.middleBand,
    required this.whiteCheckerTop,
    required this.whiteCheckerBottom,
    required this.whiteCheckerRing,
    required this.blackCheckerTop,
    required this.blackCheckerBottom,
    required this.blackCheckerRing,
    required this.hintColor,
  });

  /// Stable identifier persisted in settings.
  final String id;

  /// Persian display name.
  final String name;

  // Frame / wood -----------------------------------------------------------
  final Color frameLight;
  final Color frameDark;
  final Color playfieldTint;

  // Points -----------------------------------------------------------------
  final Color pointA;
  final Color pointB;
  final Color pointEdge;

  // Bar / trays / middle ---------------------------------------------------
  final Color barColor;
  final Color barInlay;
  final Color trayColor;
  final Color traySlot;
  final Color middleBand;

  // Checkers ---------------------------------------------------------------
  final Color whiteCheckerTop;
  final Color whiteCheckerBottom;
  final Color whiteCheckerRing;
  final Color blackCheckerTop;
  final Color blackCheckerBottom;
  final Color blackCheckerRing;

  /// Color of the glowing hint dots and selection highlights.
  final Color hintColor;

  /// Classic walnut & gold — the signature look.
  static const BoardThemeData classic = BoardThemeData(
    id: 'classic',
    name: 'گردویی کلاسیک',
    frameLight: Color(0xFF5D4034),
    frameDark: Color(0xFF2E1C16),
    playfieldTint: Color(0x66120A07),
    pointA: Color(0xFF4E342E),
    pointB: Color(0xFFC9A961),
    pointEdge: Color(0x59301E14),
    barColor: Color(0xFF3A251D),
    barInlay: Color(0xFFD4AF37),
    trayColor: Color(0xFF332019),
    traySlot: Color(0xFF241611),
    middleBand: Color(0xFF2B1B14),
    whiteCheckerTop: Color(0xFFF7EEDC),
    whiteCheckerBottom: Color(0xFFCDBD9F),
    whiteCheckerRing: Color(0xFFB49A57),
    blackCheckerTop: Color(0xFF44322B),
    blackCheckerBottom: Color(0xFF171009),
    blackCheckerRing: Color(0xFFD4AF37),
    hintColor: Color(0xFFFFD54F),
  );

  /// Emerald night — deep green felt tones with ivory points.
  static const BoardThemeData emeraldNight = BoardThemeData(
    id: 'emerald',
    name: 'زمرد شب',
    frameLight: Color(0xFF2F4A42),
    frameDark: Color(0xFF152521),
    playfieldTint: Color(0x5504100C),
    pointA: Color(0xFF1B4A3F),
    pointB: Color(0xFFD8CBA8),
    pointEdge: Color(0x4D0B2620),
    barColor: Color(0xFF204238),
    barInlay: Color(0xFFE0C568),
    trayColor: Color(0xFF1C352E),
    traySlot: Color(0xFF122420),
    middleBand: Color(0xFF183029),
    whiteCheckerTop: Color(0xFFF8F3E4),
    whiteCheckerBottom: Color(0xFFCFCCB4),
    whiteCheckerRing: Color(0xFF7FA88F),
    blackCheckerTop: Color(0xFF3B3F3C),
    blackCheckerBottom: Color(0xFF101412),
    blackCheckerRing: Color(0xFFE0C568),
    hintColor: Color(0xFF80CBC4),
  );

  /// Royal ruby — warm burgundy with rose-gold accents.
  static const BoardThemeData royalRuby = BoardThemeData(
    id: 'ruby',
    name: 'یاقوت سلطنتی',
    frameLight: Color(0xFF5A2E33),
    frameDark: Color(0xFF2D1518),
    playfieldTint: Color(0x66190A0D),
    pointA: Color(0xFF5D2A33),
    pointB: Color(0xFFE3C58E),
    pointEdge: Color(0x592E1216),
    barColor: Color(0xFF47222A),
    barInlay: Color(0xFFEBCE9A),
    trayColor: Color(0xFF3D1E24),
    traySlot: Color(0xFF28141A),
    middleBand: Color(0xFF351A20),
    whiteCheckerTop: Color(0xFFF9EDE0),
    whiteCheckerBottom: Color(0xFFD5BCA8),
    whiteCheckerRing: Color(0xFFC99A5B),
    blackCheckerTop: Color(0xFF452F31),
    blackCheckerBottom: Color(0xFF180F10),
    blackCheckerRing: Color(0xFFEBC49C),
    hintColor: Color(0xFFFFAB91),
  );

  static const List<BoardThemeData> all = [classic, emeraldNight, royalRuby];

  static BoardThemeData byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => classic);
}
