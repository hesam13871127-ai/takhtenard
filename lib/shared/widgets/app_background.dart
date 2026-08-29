import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The luxurious dark app background: gradient + subtle Persian pattern
/// overlay + slowly floating golden dust particles.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, this.showParticles = true, this.child});

  final bool showParticles;
  final Widget? child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppPalette.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Persian arabesque pattern at a whisper of opacity.
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/images/bg_pattern.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          if (widget.showParticles)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _DustPainter(progress: _controller.value),
              ),
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

/// Floating golden dust — cheap to render (transform-only animation).
class _DustPainter extends CustomPainter {
  _DustPainter({required this.progress});

  final double progress;

  static final List<_Dust> _dust = List.generate(
    26,
    (i) => _Dust.random(i),
    growable: false,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x2ED4AF37);
    final brightPaint = Paint()..color = const Color(0x55E9CE7A);
    for (final d in _dust) {
      final phase = (progress * d.speed + d.phase) % 1.0;
      final y = size.height * (1.05 - phase * 1.1);
      final x = size.width * d.x + math.sin(phase * math.pi * 2 + d.phase) * 18;
      canvas.drawCircle(Offset(x, y), d.radius, d.bright ? brightPaint : paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) => true;
}

class _Dust {
  _Dust.random(int seed)
      : x = ((seed * 37) % 100) / 100,
        radius = 0.8 + ((seed * 13) % 5) * 0.45,
        speed = 0.5 + ((seed * 7) % 10) / 18,
        phase = ((seed * 29) % 10) / 10,
        bright = seed % 4 == 0;

  final double x;
  final double radius;
  final double speed;
  final double phase;
  final bool bright;
}
