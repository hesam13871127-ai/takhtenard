import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/board_themes.dart';
import '../../domain/models/player.dart';

/// Visual state of a checker.
enum CheckerVisualState { normal, movable, selected }

/// A single checker rendered as a glossy, slightly 3D disc.
class CheckerFace extends StatelessWidget {
  const CheckerFace({
    super.key,
    required this.player,
    required this.theme,
    this.state = CheckerVisualState.normal,
  });

  final Player player;
  final BoardThemeData theme;
  final CheckerVisualState state;

  @override
  Widget build(BuildContext context) {
    final isWhite = player == Player.white;
    final top = isWhite ? theme.whiteCheckerTop : theme.blackCheckerTop;
    final bottom = isWhite ? theme.whiteCheckerBottom : theme.blackCheckerBottom;
    final ring = isWhite ? theme.whiteCheckerRing : theme.blackCheckerRing;

    return CustomPaint(
      painter: _CheckerPainter(
        top: top,
        bottom: bottom,
        ring: ring,
        isWhite: isWhite,
        state: state,
        hintColor: theme.hintColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Paints one checker: radial body, rim ring, engraved grooves and a
/// specular highlight.
class _CheckerPainter extends CustomPainter {
  _CheckerPainter({
    required this.top,
    required this.bottom,
    required this.ring,
    required this.isWhite,
    required this.state,
    required this.hintColor,
  });

  final Color top;
  final Color bottom;
  final Color ring;
  final bool isWhite;
  final CheckerVisualState state;
  final Color hintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final d = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = d / 2;

    // Drop shadow.
    canvas.drawCircle(
      center.translate(0, radius * 0.10),
      radius * 0.97,
      Paint()..color = const Color(0x66000000),
    );

    // Body with a lit upper-left area.
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.45,
        colors: [top, bottom],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius * 0.96, bodyPaint);

    // Rim ring.
    canvas.drawCircle(
      center,
      radius * 0.86,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * 0.10)
        ..color = isWhite
            ? Color.lerp(ring, bottom, 0.35)!
            : ring.withAlpha(242),
    );

    // Inner engraved groove.
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, radius * 0.05)
        ..color = isWhite
            ? const Color(0x338D6E3F)
            : const Color(0x59D4AF37),
    );

    // Specular highlight.
    final highlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.42, -0.48),
        radius: 0.55,
        colors: const [Color(0x66FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius * 0.92, highlight);

    // Selection ring.
    if (state != CheckerVisualState.normal) {
      canvas.drawCircle(
        center,
        radius * 0.99,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, radius * 0.12)
          ..color = hintColor,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.state != state ||
      oldDelegate.ring != ring;
}

/// A checker that glows gently while it can be moved.
class MovableChecker extends StatelessWidget {
  const MovableChecker({super.key, required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.055, 1.055),
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .boxShadow(
          end: BoxShadow(
            color: color.withAlpha(140),
            blurRadius: 16,
            spreadRadius: 3,
            offset: Offset.zero,
          ),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}
