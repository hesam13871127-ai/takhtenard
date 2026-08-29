import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/sound_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_controller.dart';
import 'features/splash/presentation/splash_screen.dart';

/// Root widget: Persian (RTL) locale, dark luxury theme and the sound
/// setting wired to the audio controller.
class TakhtehNardApp extends ConsumerWidget {
  const TakhtehNardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the audio master switch in sync with the persisted setting.
    ref.listen(settingsProvider.select((s) => s.soundOn), (previous, next) {
      ref.read(soundControllerProvider).enabled = next;
    });

    return MaterialApp(
      title: 'تخته نرد',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
