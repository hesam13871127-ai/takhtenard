import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine/takhteh_game.dart';
import '../domain/models/game_config.dart';

/// Everything needed to resume an interrupted game.
class SavedGame {
  const SavedGame({
    required this.config,
    required this.game,
    required this.whiteScore,
    required this.blackScore,
  });

  final GameConfig config;
  final TakhtehGame game;
  final int whiteScore;
  final int blackScore;
}

/// Persists the current game in [SharedPreferences] so the app can be
/// closed and resumed at any time (fully offline).
class GameSaver {
  static const _kSave = 'save.currentGame';

  Future<void> save({
    required TakhtehGame game,
    required GameConfig config,
    required int whiteScore,
    required int blackScore,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(<String, Object?>{
        'config': config.toJson(),
        'game': game.toJson(),
        'whiteScore': whiteScore,
        'blackScore': blackScore,
      });
      await prefs.setString(_kSave, payload);
    } catch (_) {
      // Saving is best-effort; never let it break gameplay.
    }
  }

  Future<SavedGame?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSave);
      if (raw == null) return null;
      final Map<String, Object?> payload =
          (jsonDecode(raw) as Map).cast<String, Object?>();
      final config = GameConfig.fromJson(
        (payload['config']! as Map).cast<String, Object?>(),
      );
      final game = TakhtehGame.fromJson(
        (payload['game']! as Map).cast<String, Object?>(),
        config,
      );
      if (game.phase == GamePhase.gameOver) return null;
      final whiteScore = payload['whiteScore']! as int;
      final blackScore = payload['blackScore']! as int;
      return SavedGame(
        config: config,
        game: game,
        whiteScore: whiteScore,
        blackScore: blackScore,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSave);
    } catch (_) {}
  }
}
