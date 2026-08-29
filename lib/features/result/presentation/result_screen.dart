import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/luxury_button.dart';
import '../../game/application/game_controller.dart';
import '../../game/domain/models/game_config.dart';
import '../../game/domain/models/game_result.dart';
import '../../game/domain/models/player.dart';

/// Winner announcement with an elegant golden particle celebration.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.score,
    required this.config,
  });

  final GameResult result;
  final MatchScore score;
  final GameConfig config;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _winnerName =>
      widget.result.winner == Player.white
          ? widget.config.whiteName
          : widget.config.blackName;

  bool get _humanWon {
    final winnerSide = widget.result.winner == Player.white
        ? PlayerSide.white
        : PlayerSide.black;
    return !widget.config.isAi(winnerSide);
  }

  @override
  Widget build(BuildContext context) {
    final isGammon = widget.result.winType == WinType.gammon;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Golden celebration particles.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => CustomPaint(
                    painter: _CelebrationPainter(
                      progress: _confetti.value,
                      intense: _humanWon,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy emblem.
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x66D4AF37), Color(0x00D4AF37)],
                          ),
                        ),
                        child: Icon(
                          _humanWon
                              ? Icons.emoji_events
                              : Icons.military_tech,
                          size: 84,
                          color: AppPalette.gold,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 22),

                      Text(
                        _humanWon
                            ? AppStrings.youWin
                            : AppStrings.winnerIs(_winnerName),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.ivory,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(
                            begin: 0.25,
                            end: 0,
                            duration: 550.ms,
                          ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppPalette.gold),
                          color: isGammon
                              ? const Color(0x33B2495E)
                              : const Color(0x26D4AF37),
                        ),
                        child: Text(
                          '${isGammon ? AppStrings.gammonWin : AppStrings.normalWin}'
                          ' — ${AppStrings.pointsWon(widget.result.points)}',
                          style: const TextStyle(
                            color: AppPalette.ivory,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ).animate(delay: 250.ms).fadeIn().scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 30),

                      _buildScoreBoard(),

                      const SizedBox(height: 34),

                      LuxuryButton(
                        label: AppStrings.rematch,
                        icon: Icons.replay,
                        onPressed: _rematch,
                      ),
                      const SizedBox(height: 14),
                      LuxuryButton(
                        label: AppStrings.backToHome,
                        icon: Icons.home,
                        secondary: true,
                        onPressed: () => Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xCC241812),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.panelBorder),
      ),
      child: Column(
        children: [
          const Text(
            AppStrings.matchScore,
            style: TextStyle(
              color: AppPalette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _scoreEntry(widget.config.whiteName, widget.score.white,
                  Player.white, widget.result.winner == Player.white),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  PersianDigits.convert(
                    '${widget.score.white} - ${widget.score.black}',
                  ),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.gold,
                  ),
                ),
              ),
              _scoreEntry(widget.config.blackName, widget.score.black,
                  Player.black, widget.result.winner == Player.black),
            ],
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 500.ms);
  }

  Widget _scoreEntry(String name, int points, Player player, bool isWinner) {
    final isWhite = player == Player.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.35),
              colors: isWhite
                  ? const [Color(0xFFF7EEDC), Color(0xFFCDBD9F)]
                  : const [Color(0xFF44322B), Color(0xFF171009)],
            ),
            border: Border.all(
              color: isWhite ? Color(0xFFB49A57) : AppPalette.gold,
            ),
          ),
          child: isWinner
              ? const Icon(Icons.star, size: 16, color: AppPalette.gold)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          PersianDigits.format(points),
          style: const TextStyle(
            color: AppPalette.textFaint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _rematch() {
    ref.read(gameControllerProvider.notifier).rematch();
    Navigator.of(context).pop(); // Back to the fresh game.
  }
}

/// Falling golden confetti / light particles for the winner celebration.
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({required this.progress, required this.intense});

  final double progress;
  final bool intense;

  static final List<_Particle> _particles = List.generate(
    42,
    (i) => _Particle.random(i),
    growable: false,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final phase = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1.08 - phase * 1.16);
      final x =
          size.width * p.x + math.sin(phase * math.pi * 3 + p.phase) * 26;
      final opacity = (1 - phase) * 0.9;

      final paint = Paint()
        ..color = p.color.withAlpha((opacity * 255).round());
      canvas.drawCircle(Offset(x, y), p.radius, paint);
      if (intense && p.sparkle) {
        canvas.drawCircle(
          Offset(x, y),
          p.radius * 2.4,
          Paint()..color = p.color.withAlpha((opacity * 70).round()),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) => true;
}

class _Particle {
  _Particle.random(int seed)
      : x = ((seed * 41) % 100) / 100,
        radius = 1.4 + ((seed * 17) % 5) * 0.7,
        speed = 0.6 + ((seed * 7) % 10) / 16,
        phase = ((seed * 31) % 10) / 10,
        sparkle = seed % 3 == 0,
        color = seed % 5 == 0
            ? const Color(0xFFE9CE7A)
            : seed % 5 == 1
                ? const Color(0xFFD4AF37)
                : seed % 5 == 2
                    ? const Color(0xFFFFB74D)
                    : seed % 5 == 3
                        ? const Color(0xFFF5EAD6)
                        : const Color(0xFFB2495E);

  final double x;
  final double radius;
  final double speed;
  final double phase;
  final bool sparkle;
  final Color color;
}
