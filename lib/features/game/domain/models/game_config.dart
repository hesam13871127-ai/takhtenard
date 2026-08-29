/// Available game modes.
enum GameMode { vsAi, localMultiplayer }

/// AI difficulty tiers.
enum AiDifficulty { easy, medium, hard }

/// Persian labels for the AI difficulties (UI helper kept in the domain so
/// the AI package can label its own decisions in logs during tests).
extension AiDifficultyLabel on AiDifficulty {
  String get persianName => switch (this) {
        AiDifficulty.easy => 'آسان',
        AiDifficulty.medium => 'متوسط',
        AiDifficulty.hard => 'سخت',
      };
}

/// Immutable configuration of a single game session.
class GameConfig {
  const GameConfig({
    required this.mode,
    required this.difficulty,
    this.whiteName = 'بازیکن ۱',
    this.blackName = 'بازیکن ۲',
    this.humanPlays = PlayerSide.white,
  });

  final GameMode mode;

  /// Only meaningful when [mode] == [GameMode.vsAi].
  final AiDifficulty difficulty;

  /// Display name of the white player.
  final String whiteName;

  /// Display name of the black player.
  final String blackName;

  /// Which side the human plays in single-player mode.
  final PlayerSide humanPlays;

  /// Whether [player] is controlled by the computer.
  bool isAi(PlayerSide player) {
    if (mode != GameMode.vsAi) return false;
    return player != humanPlays;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'mode': mode.name,
        'difficulty': difficulty.name,
        'whiteName': whiteName,
        'blackName': blackName,
        'humanPlays': humanPlays.name,
      };

  factory GameConfig.fromJson(Map<String, Object?> json) => GameConfig(
        mode: GameMode.values.firstWhere((m) => m.name == json['mode']),
        difficulty: AiDifficulty.values
            .firstWhere((d) => d.name == json['difficulty']),
        whiteName: json['whiteName']! as String,
        blackName: json['blackName']! as String,
        humanPlays:
            PlayerSide.values.firstWhere((s) => s.name == json['humanPlays']),
      );
}

/// Mirror of [Player] for configuration purposes, kept independent from the
/// engine enum so that configuration code does not depend on domain types.
enum PlayerSide { white, black }
