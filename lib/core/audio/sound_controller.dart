import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All sound effects bundled with the app.
enum SoundEffect {
  click('click.wav', 0.9),
  diceRoll('dice_roll.wav', 0.95),
  pieceMove('piece_move.wav', 0.95),
  pieceHit('piece_hit.wav', 1.0),
  reenter('reenter.wav', 0.95),
  bearOff('bear_off.wav', 0.95),
  turnChange('turn_change.wav', 0.8),
  win('win.wav', 0.95),
  lose('lose.wav', 0.9);

  const SoundEffect(this.file, this.volume);

  /// File name inside assets/sounds/.
  final String file;

  /// Relative playback volume.
  final double volume;
}

/// Plays the bundled sound effects.
///
/// One [AudioPlayer] per effect is created once and reused so effects start
/// instantly. Every call is failure-safe: audio must never crash the game.
class SoundController {
  final Map<SoundEffect, Future<AudioPlayer?>> _futures = {};

  /// Master switch; mirrors the user's sound setting.
  bool enabled = true;

  bool _disposed = false;

  /// Preloads all effects (safe to call repeatedly).
  Future<void> preload() async {
    for (final effect in SoundEffect.values) {
      await _playerFor(effect);
    }
  }

  Future<AudioPlayer?> _playerFor(SoundEffect effect) {
    return _futures.putIfAbsent(effect, () async {
      final player = AudioPlayer(playerId: 'takhtenard_${effect.name}');
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        if (effect == SoundEffect.diceRoll ||
            effect == SoundEffect.pieceMove ||
            effect == SoundEffect.click ||
            effect == SoundEffect.pieceHit) {
          await player.setPlayerMode(PlayerMode.mediaPlayer);
        } else {
          // Low latency mode improves short sound effects on Android.
          await player.setPlayerMode(PlayerMode.lowLatency);
        }
        await player.setSource(AssetSource('sounds/${effect.file}'));
        await player.setVolume(effect.volume);
        if (_disposed) {
          await player.dispose();
          return null;
        }
        return player;
      } catch (_) {
        // Audio problems must never break the game.
        try {
          await player.dispose();
        } catch (_) {}
        return null;
      }
    });
  }

  /// Plays [effect] if sound is enabled. Never throws.
  Future<void> play(SoundEffect effect) async {
    if (!enabled || _disposed) return;
    try {
      final player = await _playerFor(effect);
      if (player == null) return;
      if (effect == SoundEffect.diceRoll ||
          effect == SoundEffect.pieceMove ||
          effect == SoundEffect.click ||
          effect == SoundEffect.pieceHit) {
        await player.play(
          AssetSource('sounds/${effect.file}'),
          volume: effect.volume,
        );
      } else {
        await player.stop();
        await player.seek(Duration.zero);
        await player.resume();
      }
    } catch (_) {
      // Swallow audio errors on purpose.
    }
  }

  /// Releases all audio resources.
  Future<void> dispose() async {
    _disposed = true;
    final futures = List<Future<AudioPlayer?>>.from(_futures.values);
    _futures.clear();
    for (final future in futures) {
      try {
        final player = await future;
        await player?.dispose();
      } catch (_) {}
    }
  }
}

/// Riverpod provider for the app-wide sound controller.
final Provider<SoundController> soundControllerProvider =
    Provider<SoundController>((ref) {
  final controller = SoundController();
  ref.onDispose(() => controller.dispose());
  // Warm up in the background so the first effect plays without delay.
  controller.preload();
  return controller;
});
