import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/board_themes.dart';
import '../game/domain/models/game_config.dart';

/// Provider for the shared preferences instance, overridden in main().
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

/// Immutable snapshot of the user's preferences.
class SettingsState {
  const SettingsState({
    required this.soundOn,
    required this.defaultDifficulty,
    required this.boardThemeId,
  });

  final bool soundOn;
  final AiDifficulty defaultDifficulty;
  final String boardThemeId;

  BoardThemeData get boardTheme => BoardThemeData.byId(boardThemeId);

  SettingsState copyWith({
    bool? soundOn,
    AiDifficulty? defaultDifficulty,
    String? boardThemeId,
  }) =>
      SettingsState(
        soundOn: soundOn ?? this.soundOn,
        defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
        boardThemeId: boardThemeId ?? this.boardThemeId,
      );
}

/// Persists and exposes the app settings.
class SettingsController extends Notifier<SettingsState> {
  static const _kSoundOn = 'settings.soundOn';
  static const _kDifficulty = 'settings.difficulty';
  static const _kBoardTheme = 'settings.boardTheme';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      soundOn: prefs.getBool(_kSoundOn) ?? true,
      defaultDifficulty: AiDifficulty.values.firstWhere(
        (d) => d.name == prefs.getString(_kDifficulty),
        orElse: () => AiDifficulty.medium,
      ),
      boardThemeId: prefs.getString(_kBoardTheme) ?? BoardThemeData.classic.id,
    );
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> setSoundOn(bool value) async {
    state = state.copyWith(soundOn: value);
    await _prefs.setBool(_kSoundOn, value);
  }

  Future<void> setDefaultDifficulty(AiDifficulty value) async {
    state = state.copyWith(defaultDifficulty: value);
    await _prefs.setString(_kDifficulty, value.name);
  }

  Future<void> setBoardTheme(String id) async {
    state = state.copyWith(boardThemeId: id);
    await _prefs.setString(_kBoardTheme, id);
  }

}

final NotifierProvider<SettingsController, SettingsState>
    settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
