import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_palette.dart';

/// A pair of dice with a physics-flavoured rolling animation.
///
/// While [rolling] is true the faces flicker rapidly with a wobble; when it
/// turns false the final [values] settle with a bounce. If the two values
/// are equal (doubles) the pair keeps a subtle golden aura.
class DicePairView extends StatefulWidget {
  const DicePairView({
    super.key,
    required this.size,
    required this.values,
    required this.remaining,
    required this.rolling,
    this.ivoryAccent = false,
  });

  final double size;
  final List<int> values;
  final List<int> remaining;
  final bool rolling;

  /// Tints the dice slightly ivory (used for the white player's opening die).
  final bool ivoryAccent;

  @override
  State<DicePairView> createState() => _DicePairViewState();
}

class _DicePairViewState extends State<DicePairView> {
  Timer? _flickerTimer;
  final math.Random _random = math.Random();
  List<int> _display = const [1, 1];
  int _lastSettleKey = 0;

  @override
  void initState() {
    super.initState();
    _display = List<int>.from(widget.values);
    _syncRolling();
  }

  @override
  void didUpdateWidget(DicePairView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.rolling) {
      _display = List<int>.from(widget.values);
      if (oldWidget.rolling) {
        // A fresh settle: restart the bounce.
        _lastSettleKey++;
      }
    }
    _syncRolling();
  }

  void _syncRolling() {
    if (widget.rolling) {
      _flickerTimer ??= Timer.periodic(const Duration(milliseconds: 60), (_) {
        if (!mounted) return;
        setState(() {
          _display = [
            _random.nextInt(6) + 1,
            _random.nextInt(6) + 1,
          ];
        });
      });
    } else {
      _flickerTimer?.cancel();
      _flickerTimer = null;
    }
  }

  List<bool> _usedDice() {
    if (widget.rolling) return List<bool>.filled(_display.length, false);
    final remainingCounts = <int, int>{};
    for (final value in widget.remaining) {
      remainingCounts.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    return List<bool>.generate(_display.length, (index) {
      final value = _display[index];
      final count = remainingCounts[value] ?? 0;
      if (count == 0) return true;
      remainingCounts[value] = count - 1;
      return false;
    });
  }

  @override
  void dispose() {
    _flickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDouble = !widget.rolling && _display.length == 4;
    final dieSize = widget.size * (isDouble ? 0.8 : 1);
    final dieGap = widget.size * (isDouble ? 0.12 : 0.42);
    final usedDice = _usedDice();
    final dice = <Widget>[];
    for (var i = 0; i < _display.length; i++) {
      if (i > 0) dice.add(SizedBox(width: dieGap));
      dice.add(
        AnimatedOpacity(
          opacity: usedDice[i] ? 0.28 : 1,
          duration: const Duration(milliseconds: 250),
          child: _Die(
            value: _display[i],
            size: dieSize,
            tilt: i.isEven ? -0.10 : 0.08,
            ivoryAccent: widget.ivoryAccent,
          ),
        ),
      );
    }

    Widget pair = Row(
      mainAxisSize: MainAxisSize.min,
      children: dice,
    );

    if (widget.rolling) {
      pair = pair
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .rotate(
            // Values are in turns; ~5 degrees of playful wobble.
            begin: -0.014,
            end: 0.014,
            duration: 140.ms,
            curve: Curves.easeInOut,
          )
          .moveY(
            begin: -widget.size * 0.10,
            end: widget.size * 0.10,
            duration: 160.ms,
            curve: Curves.easeInOut,
          );
    } else {
      pair = pair
          .animate(key: ValueKey(_lastSettleKey))
          .scale(
            begin: const Offset(1.35, 1.35),
            end: const Offset(1, 1),
            duration: 380.ms,
            curve: Curves.easeOutBack,
          );
      if (isDouble) {
        pair = pair
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .boxShadow(
              end: BoxShadow(
                color: AppPalette.gold.withAlpha(150),
                blurRadius: 20,
                spreadRadius: 4,
                offset: Offset.zero,
              ),
              duration: 1000.ms,
              curve: Curves.easeInOut,
            );
      }
    }
    return pair;
  }
}

/// One die: rounded ivory cube face with crisp pips and a soft shadow.
class _Die extends StatelessWidget {
  const _Die({
    required this.value,
    required this.size,
    required this.tilt,
    this.ivoryAccent = false,
  });

  final int value;
  final double size;
  final double tilt;
  final bool ivoryAccent;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: [
            BoxShadow(
              color: const Color(0x99000000),
              blurRadius: size * 0.14,
              offset: Offset(0, size * 0.10),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DiePainter(value: value, ivoryAccent: ivoryAccent),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Paints a die face.
class _DiePainter extends CustomPainter {
  _DiePainter({required this.value, required this.ivoryAccent});

  final int value;
  final bool ivoryAccent;

  static const Map<int, List<Offset>> _pipLayouts = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.26, 0.26), Offset(0.74, 0.74)],
    3: [
      Offset(0.25, 0.25),
      Offset(0.5, 0.5),
      Offset(0.75, 0.75),
    ],
    4: [
      Offset(0.27, 0.27),
      Offset(0.73, 0.27),
      Offset(0.27, 0.73),
      Offset(0.73, 0.73),
    ],
    5: [
      Offset(0.26, 0.26),
      Offset(0.74, 0.26),
      Offset(0.5, 0.5),
      Offset(0.26, 0.74),
      Offset(0.74, 0.74),
    ],
    6: [
      Offset(0.27, 0.22),
      Offset(0.73, 0.22),
      Offset(0.27, 0.5),
      Offset(0.73, 0.5),
      Offset(0.27, 0.78),
      Offset(0.73, 0.78),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width * 0.22),
    );

    // Cube body.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ivoryAccent
              ? const [
                  Color(0xFFFDF6E7),
                  Color(0xFFEBDDBB),
                  Color(0xFFCDBD95),
                ]
              : const [
                  Color(0xFFF7EFDE),
                  Color(0xFFE6D9BC),
                  Color(0xFFC9B98F),
                ],
        ).createShader(rect),
    );

    // Edge shading for a subtle 3D feel.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..color = const Color(0x2E5D4037),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF8C7020).withAlpha(70),
    );

    // Pips.
    final pipRadius = size.width * 0.085;
    final layout = _pipLayouts[value] ?? const <Offset>[];
    for (final relative in layout) {
      final center = Offset(
        relative.dx * size.width,
        relative.dy * size.height,
      );
      canvas.drawCircle(
        center,
        pipRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: const [Color(0xFF4E342E), Color(0xFF231508)],
          ).createShader(
            Rect.fromCircle(center: center, radius: pipRadius),
          ),
      );
      // Tiny pip highlight.
      canvas.drawCircle(
        center.translate(-pipRadius * 0.28, -pipRadius * 0.30),
        pipRadius * 0.22,
        Paint()..color = const Color(0x2EFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(_DiePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.ivoryAccent != ivoryAccent;
}
