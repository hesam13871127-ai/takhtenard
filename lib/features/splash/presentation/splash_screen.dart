import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/presentation/home_screen.dart';

/// Animated splash: logo, Persian title and a pair of dice that settle,
/// then a smooth fade into the home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(AppConstants.splashDuration, _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppPalette.backgroundGradient),
          ),
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/images/bg_pattern.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emblem.
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 210,
                    height: 210,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // Persian title.
                const Text(
                  AppConstants.appTitleFa,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.ivory,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.35, end: 0, duration: 600.ms),

                const SizedBox(height: 10),

                const Text(
                  AppStrings.appSubtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppPalette.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 600.ms),

                const SizedBox(height: 34),

                // A pair of dice settling beneath the title.
                const _SplashDice()
                    .animate(delay: 650.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two decorative dice for the splash animation.
class _SplashDice extends StatelessWidget {
  const _SplashDice();

  @override
  Widget build(BuildContext context) {
    Widget die(int value, double tilt) => Transform.rotate(
          angle: tilt,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE3C4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppPalette.goldDark),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 8),
              ],
            ),
            child: Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF33221A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        die(1, -0.12),
        const SizedBox(width: 14),
        die(1, 0.1),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: 900.ms, curve: Curves.easeInOut);
  }
}
