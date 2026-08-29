import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/audio/sound_controller.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted preferences synchronously before the first frame so the
  // whole UI (theme, sound, difficulty) is ready immediately — this keeps
  // the cold start fast and free of theme flicker.
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Apply the persisted sound switch to the audio controller right away.
  container.read(soundControllerProvider).enabled =
      container.read(settingsProvider).soundOn;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TakhtehNardApp(),
    ),
  );
}
