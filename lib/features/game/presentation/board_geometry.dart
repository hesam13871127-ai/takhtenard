import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models/player.dart';

/// Pure layout math for the backgammon board.
///
/// All coordinates are relative to a board box of [size]. The board is
/// composed of:
///
/// * a wooden frame around everything,
/// * a narrow bear-off tray on the left and right,
/// * twelve point columns per row (bottom row = white's points 1..12 seen
///   right-to-left, top row = 13..24 left-to-right),
/// * the bar between columns 6 and 7,
/// * a horizontal middle band where the dice rest.
///
/// [flipped] rotates the whole layout by 180° — the view the black player
/// has in two-player mode. Every method applies the rotation consistently,
/// including hit-testing.
class BoardGeometry {
  BoardGeometry({required this.size, this.flipped = false});

  final Size size;
  final bool flipped;

  double get width => size.width;
  double get height => size.height;

  // ------------------------------------------------------- metrics
  double get frame => width * 0.028;
  double get trayWidth => width * 0.058;
  double get barWidth => width * 0.085;

  /// Total width of the twelve point columns plus the bar.
  double get playWidth => width - 2 * frame - 2 * trayWidth;
  double get pointWidth => (playWidth - barWidth) / 12;

  /// The horizontal band between the two point rows where the dice rest.
  double get middleBandHeight => (height * 0.155).clamp(38.0, 84.0);

  /// Height of each row of point triangles.
  double get pointHeight => ((height - 2 * frame) - middleBandHeight) / 2;

  /// Diameter of a checker.
  double get checkerDiameter =>
      math.min(pointWidth * 0.86, pointHeight / 5.2);

  /// Edge length of a die.
  double get diceSize =>
      math.min(pointWidth * 1.45, middleBandHeight * 0.72);

  // ------------------------------------------------------- zones
  Rect get boardRect => Offset.zero & size;

  Rect get innerRect => Rect.fromLTWH(
        frame,
        frame,
        width - 2 * frame,
        height - 2 * frame,
      );

  /// The bar (central column), full height of the inner rect.
  Rect get barRect {
    final left = frame + trayWidth + 6 * pointWidth;
    return Rect.fromLTWH(left, frame, barWidth, height - 2 * frame);
  }

  /// Tray column on the left side.
  Rect get leftTrayRect => Rect.fromLTWH(
        frame,
        frame,
        trayWidth,
        height - 2 * frame,
      );

  /// Tray column on the right side.
  Rect get rightTrayRect => Rect.fromLTWH(
        width - frame - trayWidth,
        frame,
        trayWidth,
        height - 2 * frame,
      );

  /// x origin of the point columns (left edge of column 1).
  double get _pointsLeft => frame + trayWidth;

  double _columnLeft(int column) =>
      _pointsLeft +
      (column - 1) * pointWidth +
      (column > 6 ? barWidth : 0);

  /// Rect of the triangle of [point] (1..24), ignoring flip.
  Rect _pointRectRaw(int point) {
    final (column, isBottom) = _pointColumn(point);
    final left = _columnLeft(column);
    final top = isBottom ? height - frame - pointHeight : frame;
    return Rect.fromLTWH(left, top, pointWidth, pointHeight);
  }

  (int, bool) _pointColumn(int point) {
    if (point <= 12) {
      return (13 - point, true); // bottom row, right to left
    }
    return (point - 12, false); // top row, left to right
  }

  /// Rect of a point triangle, with flip applied.
  Rect pointRect(int point) => _flipRect(_pointRectRaw(point));

  // ------------------------------------------------------- checkers

  /// Center position of the checker with stack [index] on [point]
  /// (1..24). Index 0 is the checker nearest the board edge.
  Offset checkerCenter(int point, int index) {
    final raw = _pointRectRaw(point);
    final (_, isBottom) = _pointColumn(point);
    final d = checkerDiameter;
    final spacing = math.min(d * 0.98, _stackSpacing(pointHeight));
    final cx = raw.center.dx;
    final cy = isBottom
        ? raw.bottom - d / 2 - index * spacing
        : raw.top + d / 2 + index * spacing;
    return _flipOffset(Offset(cx, cy));
  }

  double _stackSpacing(double h) => h / 5.35;

  /// Center of the [index]-th checker of [player] waiting on the bar.
  ///
  /// White bar checkers stack from the top of the bar (they re-enter in the
  /// opponent's home board up there), black checkers from the bottom.
  Offset barCheckerCenter(Player player, int index) {
    final d = checkerDiameter;
    final spacing = math.min(d * 0.98, (height / 2 - frame) / 5.4);
    final cx = barRect.center.dx;
    final whiteCy = frame + d / 2 + index * spacing;
    final blackCy = height - frame - d / 2 - index * spacing;
    return _flipOffset(Offset(cx, player == Player.white ? whiteCy : blackCy));
  }

  /// Rect of a borne-off checker slab ([index] counted from the tray
  /// bottom). White uses the right tray, black the left one.
  Rect borneOffRect(Player player, int index) {
    final rect = player == Player.white ? rightTrayRect : leftTrayRect;
    final pad = rect.width * 0.18;
    final slabHeight = math.min(
      rect.height / 15.5,
      checkerDiameter * 0.52,
    );
    final bottom = rect.bottom - pad - (index + 1) * slabHeight;
    final r = Rect.fromLTWH(
      rect.left + pad,
      bottom,
      rect.width - 2 * pad,
      slabHeight,
    );
    return flipped ? _flipRect(r) : r;
  }

  // ------------------------------------------------------- dice

  /// Center positions of the two dice. They sit in the middle band on the
  /// right half of the board (the acting player's rolling side).
  List<Offset> diceCenters() {
    final bandCenterY = height / 2;
    final rightHalfCenter =
        _pointsLeft + 6 * pointWidth + barWidth + 3 * pointWidth;
    final gap = diceSize * 0.78;
    final a = Offset(rightHalfCenter - gap, bandCenterY);
    final b = Offset(rightHalfCenter + gap, bandCenterY);
    return [_flipOffset(a), _flipOffset(b)];
  }

  /// Rect of one die centered at [center].
  Rect diceRect(Offset center) =>
      Rect.fromCenter(center: center, width: diceSize, height: diceSize);

  // ------------------------------------------------------- hit testing

  /// Interprets a tap/drop position (already in board coordinates).
  BoardHit hitTest(Offset position) {
    final p = flipped
        ? Offset(width - position.dx, height - position.dy)
        : position;
    return _hitRaw(p);
  }

  BoardHit _hitRaw(Offset p) {
    // Trays.
    if (leftTrayRect.contains(p)) return const BoardHit.leftTray();
    if (rightTrayRect.contains(p)) return const BoardHit.rightTray();
    if (barRect.contains(p)) return const BoardHit.bar();

    // Point rows.
    final inRows = p.dy >= frame && p.dy <= height - frame;
    if (!inRows) return const BoardHit.outside();
    final relative = p.dx - _pointsLeft;
    if (relative < 0) return const BoardHit.outside();
    var column = (relative / pointWidth).floor() + 1;
    if (column > 6) {
      // Skip the bar.
      final afterBar = relative - 6 * pointWidth - barWidth;
      if (afterBar < 0) return const BoardHit.bar();
      column = 6 + (afterBar / pointWidth).floor() + 1;
    }
    if (column > 12) return const BoardHit.outside();
    final isBottom = p.dy >= height / 2;
    final point = isBottom ? 13 - column : column + 12;
    return BoardHit.point(point);
  }

  // ------------------------------------------------------- flip helpers

  Offset _flipOffset(Offset o) => flipped
      ? Offset(width - o.dx, height - o.dy)
      : o;

  Rect _flipRect(Rect r) => flipped
      ? Rect.fromLTWH(
          width - r.right,
          height - r.bottom,
          r.width,
          r.height,
        )
      : r;
}

/// Result of hit-testing a board position.
class BoardHit {
  const BoardHit.point(this.point)
      : isBar = false,
        isTray = false,
        trayIsRight = false,
        isOutside = false;

  const BoardHit.bar()
      : point = null,
        isBar = true,
        isTray = false,
        trayIsRight = false,
        isOutside = false;

  const BoardHit.leftTray()
      : point = null,
        isBar = false,
        isTray = true,
        trayIsRight = false,
        isOutside = false;

  const BoardHit.rightTray()
      : point = null,
        isBar = false,
        isTray = true,
        trayIsRight = true,
        isOutside = false;

  const BoardHit.outside()
      : point = null,
        isBar = false,
        isTray = false,
        trayIsRight = false,
        isOutside = true;

  final int? point;
  final bool isBar;
  final bool isTray;
  final bool trayIsRight;
  final bool isOutside;

  bool get isPoint => point != null;
}
