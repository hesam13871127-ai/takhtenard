import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/board_themes.dart';
import 'board_geometry.dart';

/// Paints the static luxury board: wooden frame, leather band, alternating
/// points, bar with gold inlay and the two bear-off trays.
///
/// The painter is completely static (never animates) so Flutter can cache
/// its raster; dynamic elements (checkers, dice, hints) are widgets above it.
class BoardPainter extends CustomPainter {
  BoardPainter({required this.theme, this.woodTexture, this.flipped = false});

  final BoardThemeData theme;

  /// When true the whole painting is rotated by 180 degrees — the static
  /// counterpart of [BoardGeometry.flipped].
  final bool flipped;

  /// Optional photographic wood texture; when null a procedural walnut
  /// gradient is painted instead.
  final ui.Image? woodTexture;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint everything in the canonical orientation and rotate the whole
    // static layer for a flipped view; this keeps each point's colors and
    // ornaments attached to the point itself.
    canvas.save();
    if (flipped) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    final geometry = BoardGeometry(size: size);

    _paintFrame(canvas, size, geometry);
    _paintPlayfield(canvas, size, geometry);
    _paintMiddleBand(canvas, size, geometry);
    _paintPoints(canvas, size, geometry);
    _paintBar(canvas, size, geometry);
    _paintTrays(canvas, size, geometry);
    canvas.restore();
  }

  // ------------------------------------------------------------------ frame
  void _paintFrame(Canvas canvas, Size size, BoardGeometry g) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(g.frame * 1.4));

    // Wood base.
    if (woodTexture != null) {
      final src = _coverSource(woodTexture!, rect.size);
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawImageRect(
        woodTexture!,
        src,
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.frameLight, theme.frameDark, theme.frameLight],
          ).createShader(rect),
      );
    }

    // Darken towards the edges for depth.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: const [
            Color(0x00000000),
            Color(0x33000000),
            Color(0x66000000),
          ],
          stops: const [0.55, 0.85, 1.0],
        ).createShader(rect),
    );

    // Golden outer trim + a subtle inner line.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.frame * 0.42
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.barInlay.withOpacityValue(0.85),
            theme.barInlay.withOpacityValue(0.35),
            theme.barInlay.withOpacityValue(0.85),
          ],
        ).createShader(rect),
    );

    // Bevel shadow around the playfield.
    final inner = g.innerRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner.shift(Offset(0, g.frame * 0.14)),
          Radius.circular(g.frame * 0.8)),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter =  MaskFilter.blur(BlurStyle.inner, g.frame * 0.5),
    );
  }

  // -------------------------------------------------------------- playfield
  void _paintPlayfield(Canvas canvas, Size size, BoardGeometry g) {
    final inner = g.innerRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(g.frame * 0.7)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.frameDark.withOpacityValue(0.28),
            const Color(0xFF171008).withOpacityValue(0.44),
            theme.frameDark.withOpacityValue(0.28),
          ],
        ).createShader(inner),
    );

    // Fine inner border around the playfield.
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(g.frame * 0.7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = theme.barInlay.withOpacityValue(0.4),
    );
  }

  // ------------------------------------------------------------ middle band
  void _paintMiddleBand(Canvas canvas, Size size, BoardGeometry g) {
    final left = g.leftTrayRect.right;
    final right = g.rightTrayRect.left;
    final top = g.frame + g.pointHeight;
    final bottom = g.height - g.frame - g.pointHeight;
    final rect = Rect.fromLTRB(left, top, right, bottom);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.middleBand,
            Color.lerp(theme.middleBand, Colors.black, 0.35)!,
            theme.middleBand,
          ],
        ).createShader(rect),
    );

    // Golden seams along the band.
    for (final y in [rect.top + 1.5, rect.bottom - 1.5]) {
      canvas.drawLine(
        Offset(rect.left + 6, y),
        Offset(rect.right - 6, y),
        Paint()
          ..color = theme.barInlay.withOpacityValue(0.55)
          ..strokeWidth = 1,
      );
    }
  }

  // ----------------------------------------------------------------- points
  void _paintPoints(Canvas canvas, Size size, BoardGeometry g) {
    for (var point = 1; point <= 24; point++) {
      final rect = g.pointRect(point);
      final isBottom = rect.top > size.height / 2;
      final column = _columnOf(point);
      final color = column.isEven ? theme.pointA : theme.pointB;
      final baseY = isBottom ? rect.bottom : rect.top;
      final tipY = isBottom ? rect.top : rect.bottom;
      final cx = rect.center.dx;

      final path = Path()
        ..moveTo(rect.left + 0.5, baseY)
        ..lineTo(rect.right - 0.5, baseY)
        ..lineTo(cx, tipY)
        ..close();

      // Body gradient: slightly darker towards the tip.
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            // Lighter at the base of the triangle, darker at the tip.
            begin: Alignment(0, isBottom ? 1 : -1),
            end: Alignment(0, isBottom ? -1 : 1),
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.38)!,
            ],
          ).createShader(rect),
      );

      // Crisp outline + a light edge on one side for a carved look.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = theme.pointEdge,
      );
      canvas.drawLine(
        Offset(rect.left + 1, baseY),
        Offset(cx, tipY),
        Paint()
          ..color = Colors.white.withOpacityValue(0.10)
          ..strokeWidth = 1,
      );

      // Small inlaid diamond near the base — a Persian ornament detail.
      _paintDiamond(
        canvas,
        Offset(cx, baseY + (isBottom ? -1 : 1) * rect.height * 0.085),
        rect.width * 0.11,
        theme.barInlay.withOpacityValue(0.5),
      );
    }
  }

  int _columnOf(int point) => point <= 12 ? 13 - point : point - 12;

  // -------------------------------------------------------------------- bar
  void _paintBar(Canvas canvas, Size size, BoardGeometry g) {
    final rect = g.barRect;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(g.barWidth * 0.2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(theme.barColor, Colors.black, 0.30)!,
            theme.barColor,
            Color.lerp(theme.barColor, Colors.black, 0.30)!,
          ],
        ).createShader(rect),
    );

    // Gold inlay lines down the bar.
    for (final dx in [rect.left + rect.width * 0.22, rect.right - rect.width * 0.22]) {
      canvas.drawLine(
        Offset(dx, rect.top + 6),
        Offset(dx, rect.bottom - 6),
        Paint()
          ..color = theme.barInlay.withOpacityValue(0.7)
          ..strokeWidth = 1.4,
      );
    }

    // Central diamond ornament.
    _paintDiamond(
      canvas,
      rect.center,
      rect.width * 0.16,
      theme.barInlay.withOpacityValue(0.9),
    );
    _paintDiamond(
      canvas,
      Offset(rect.center.dx, rect.center.dy - rect.height * 0.18),
      rect.width * 0.10,
      theme.barInlay.withOpacityValue(0.55),
    );
    _paintDiamond(
      canvas,
      Offset(rect.center.dx, rect.center.dy + rect.height * 0.18),
      rect.width * 0.10,
      theme.barInlay.withOpacityValue(0.55),
    );
  }

  // ------------------------------------------------------------------ trays
  void _paintTrays(Canvas canvas, Size size, BoardGeometry g) {
    for (final rect in [g.leftTrayRect, g.rightTrayRect]) {
      // Recessed tray.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.3)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(theme.traySlot, Colors.black, 0.4)!,
              theme.traySlot,
              Color.lerp(theme.traySlot, Colors.black, 0.25)!,
            ],
          ).createShader(rect),
      );

      // Soft inner shadow.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.3)),
        Paint()
          ..color = Colors.black.withOpacityValue(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 6),
      );

      // Golden trim.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = theme.barInlay.withOpacityValue(0.45),
      );
    }
  }

  // ---------------------------------------------------------------- helpers
  void _paintDiamond(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  Rect _coverSource(ui.Image image, Size target) {
    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();
    final targetRatio = target.width / target.height;
    final srcRatio = srcW / srcH;
    if (srcRatio > targetRatio) {
      final w = srcH * targetRatio;
      return Rect.fromLTWH((srcW - w) / 2, 0, w, srcH);
    }
    final h = srcW / targetRatio;
    return Rect.fromLTWH(0, (srcH - h) / 2, srcW, h);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.theme != theme ||
      oldDelegate.woodTexture != woodTexture ||
      oldDelegate.flipped != flipped;
}

/// Small extension that avoids the deprecated `withOpacity` API across
/// Flutter versions while keeping call sites readable.
extension _ColorOpacity on Color {
  Color withOpacityValue(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}
