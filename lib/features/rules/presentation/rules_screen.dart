import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_background.dart';

/// The complete traditional Iranian rules, in clear Persian, with small
/// painted diagrams.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _luxuryAppBar(context, AppStrings.rulesTitle),
      body: AppBackground(
        showParticles: false,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _RuleCard(
                icon: Icons.flag,
                title: AppStrings.rulesIntroTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.rulesIntro),
                    const SizedBox(height: 12),
                    const _BoardOverviewDiagram(),
                  ],
                ),
              ),
              _RuleCard(
                icon: Icons.grid_view,
                title: AppStrings.rulesSetupTitle,
                child: Text(AppStrings.rulesSetupBody),
              ),
              _RuleCard(
                icon: Icons.casino,
                title: AppStrings.rulesOpeningTitle,
                child: Text(AppStrings.rulesOpeningBody),
              ),
              _RuleCard(
                icon: Icons.swap_horiz,
                title: AppStrings.rulesMovementTitle,
                child: Text(AppStrings.rulesMovementBody),
              ),
              _RuleCard(
                icon: Icons.gps_fixed,
                title: AppStrings.rulesHitTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.rulesHitBody),
                    const SizedBox(height: 12),
                    const _HitDiagram(),
                  ],
                ),
              ),
              _RuleCard(
                icon: Icons.block,
                title: AppStrings.rulesHitAndRunTitle,
                highlight: true,
                child: Text(AppStrings.rulesHitAndRunBody),
              ),
              _RuleCard(
                icon: Icons.vertical_align_bottom,
                title: AppStrings.rulesBarTitle,
                child: Text(AppStrings.rulesBarBody),
              ),
              _RuleCard(
                icon: Icons.inventory_2,
                title: AppStrings.rulesBearOffTitle,
                child: Text(AppStrings.rulesBearOffBody),
              ),
              _RuleCard(
                icon: Icons.rule,
                title: AppStrings.rulesMandatoryTitle,
                child: Text(AppStrings.rulesMandatoryBody),
              ),
              _RuleCard(
                icon: Icons.score,
                title: AppStrings.rulesScoringTitle,
                child: Text(AppStrings.rulesScoringBody),
              ),
              _RuleCard(
                icon: Icons.emoji_events,
                title: AppStrings.rulesEtiquetteTitle,
                child: Text(AppStrings.rulesEtiquetteBody),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _luxuryAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: AppPalette.ivory,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppPalette.gold),
    );
  }
}

/// One numbered rule card.
class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.child,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC241812),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? AppPalette.gold : AppPalette.panelBorder,
          width: highlight ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: highlight
                      ? const Color(0x33D4AF37)
                      : const Color(0x1FD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppPalette.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.ivory,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 14,
              height: 1.9,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A tiny simplified board showing the two home boards and the direction of
/// travel for both players.
class _BoardOverviewDiagram extends StatelessWidget {
  const _BoardOverviewDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _BoardOverviewPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _BoardOverviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final frame = 5.0;
    final barW = w * 0.07;

    // Frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF3A2A20),
    );

    // Playfield.
    final inner = Rect.fromLTWH(frame, frame, w - 2 * frame, h - 2 * frame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(6)),
      Paint()..color = const Color(0xFF241611),
    );

    final pointW = (inner.width - barW) / 12;

    // Points.
    for (var i = 0; i < 12; i++) {
      final isRightHalf = i >= 6;
      final left =
          inner.left + i * pointW + (isRightHalf ? barW : 0);
      final color =
          i.isEven ? const Color(0xFF4E342E) : const Color(0xFFC9A961);
      for (final isBottom in [true, false]) {
        final path = Path()
          ..moveTo(left, isBottom ? inner.bottom : inner.top)
          ..lineTo(left + pointW, isBottom ? inner.bottom : inner.top)
          ..lineTo(left + pointW / 2,
              isBottom ? inner.top + 14 : inner.bottom - 14)
          ..close();
        canvas.drawPath(path, Paint()..color = color.withAlpha(217));
      }
    }

    // Bar.
    canvas.drawRect(
      Rect.fromLTWH(inner.left + 6 * pointW, inner.top, barW, inner.height),
      Paint()..color = const Color(0xFF3A251D),
    );

    // Highlight the two home boards (bottom-right and top-right).
    final homeBottom = Rect.fromLTWH(
      inner.left + 6 * pointW + barW,
      inner.top + inner.height / 2,
      6 * pointW,
      inner.height / 2,
    );
    final homeTop = Rect.fromLTWH(
      inner.left + 6 * pointW + barW,
      inner.top,
      6 * pointW,
      inner.height / 2,
    );
    canvas.drawRect(homeBottom, Paint()..color = const Color(0x3D4CAF50));
    canvas.drawRect(homeTop, Paint()..color = const Color(0x3D4FC3F7));
    _label(canvas, homeBottom.center, 'خانهٔ سفید', 9);
    _label(canvas, homeTop.center, 'خانهٔ مشکی', 9);

    // Direction arrows.
    _arrow(canvas, Offset(inner.left + 8, inner.top + inner.height / 2),
        Offset(w - 20, inner.top + inner.height / 2));
  }

  void _label(Canvas canvas, Offset center, String text, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  void _arrow(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = AppPalette.gold
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    final direction = (to - from) / (to - from).distance;
    final perpendicular = Offset(-direction.dy, direction.dx);
    for (final sign in [1.0, -1.0]) {
      canvas.drawLine(
        to,
        to - direction * 8 + perpendicular * sign * 4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A small diagram of hitting a blot: the blot flies to the bar.
class _HitDiagram extends StatelessWidget {
  const _HitDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: CustomPaint(
        painter: _HitDiagramPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _HitDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base strip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = const Color(0xFF241611),
    );

    final checkerR = h * 0.13;

    // A white checker mid-flight towards a black blot.
    _checker(canvas, Offset(w * 0.16, h * 0.5), checkerR, true);
    // The black blot.
    _checker(canvas, Offset(w * 0.62, h * 0.5), checkerR, false);
    // The bar in the middle-right area.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.86, h * 0.5),
          width: w * 0.05,
          height: h * 0.7,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF3A251D),
    );

    // Arrow: white checker hits the blot...
    _arrowDashed(canvas, Offset(w * 0.24, h * 0.5), Offset(w * 0.54, h * 0.5));
    // ...and the blot goes to the bar.
    _arrowDashed(
      canvas,
      Offset(w * 0.66, h * 0.35),
      Offset(w * 0.84, h * 0.2),
      color: const Color(0xFFE57373),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'مانع',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(
      canvas,
      Offset(w * 0.86 - tp.width / 2, h * 0.5 + h * 0.36),
    );
  }

  void _checker(Canvas canvas, Offset center, double r, bool white) {
    canvas.drawCircle(center, r, Paint()..color = const Color(0x55000000));
    canvas.drawCircle(
      center,
      r * 0.95,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: white
              ? const [Color(0xFFF7EEDC), Color(0xFFCDBD9F)]
              : const [Color(0xFF44322B), Color(0xFF171009)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center,
      r * 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = white ? const Color(0xFFB49A57) : const Color(0xFFD4AF37),
    );
  }

  void _arrowDashed(
    Canvas canvas,
    Offset from,
    Offset to, {
    Color color = AppPalette.gold,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 6.0;
    const gap = 5.0;
    var pos = 0.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    while (pos + dash < total) {
      canvas.drawLine(from + dir * pos, from + dir * (pos + dash), paint);
      pos += dash + gap;
    }
    final head = to - dir * 8;
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawLine(to, Offset(head.dx + perp.dx * 4, head.dy + perp.dy * 4), paint);
    canvas.drawLine(to, Offset(head.dx - perp.dx * 4, head.dy - perp.dy * 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
