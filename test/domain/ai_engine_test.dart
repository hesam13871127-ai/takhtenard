import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/game_config.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/engine/takhteh_game.dart';
import 'package:takhtenard/features/game/domain/ai/ai_engine.dart';

GameConfig testConfig(AiDifficulty difficulty) => GameConfig(
      mode: GameMode.vsAi,
      difficulty: difficulty,
    );

void main() {
  group('AiEngine — legality and maximum dice usage (self-play)', () {
    for (final difficulty in AiDifficulty.values) {
      test('plays complete games without ever breaking a rule ($difficulty)',
          () {
        for (var gameIndex = 0; gameIndex < 2; gameIndex++) {
          final rng = math.Random(4242 + difficulty.index * 100 + gameIndex);
          final game = TakhtehGame(config: testConfig(difficulty));

          // Opening roll: re-roll ties.
          var w = rng.nextInt(6) + 1;
          var b = rng.nextInt(6) + 1;
          while (w == b) {
            w = rng.nextInt(6) + 1;
            b = rng.nextInt(6) + 1;
          }
          game.rollOpening(w, b);

          var turns = 0;
          while (game.phase != GamePhase.gameOver) {
            turns++;
            // A hard cap protects the test from infinite loops; real games
            // finish in a few hundred turns at most.
            expect(turns, lessThan(2000),
                reason: 'Game did not terminate ($difficulty, #$gameIndex)');

            if (game.phase == GamePhase.awaitingRoll) {
              final outcome =
                  game.roll(rng.nextInt(6) + 1, rng.nextInt(6) + 1);
              if (outcome.noMoves) {
                game.endTurn();
              }
              continue;
            }

            expect(game.phase, GamePhase.awaitingMove);
            final play = AiEngine.choosePlay(
              position: game.position,
              player: game.current,
              remainingDice: game.remaining,
              frozenPoints: game.frozen,
              difficulty: difficulty,
              rng: rng,
            );
            expect(
              play.length,
              game.legalMoves.maxUsableDice,
              reason:
                  'AI must use the maximum number of dice ($difficulty).',
            );
            for (final move in play) {
              if (game.phase != GamePhase.awaitingMove) break;
              // Throws if the move were illegal.
              game.applyMove(move);
            }
            if (game.phase == GamePhase.awaitingMove &&
                game.turnExhausted) {
              game.endTurn();
            }
          }

          expect(game.result, isNotNull);
          expect(game.result!.points, anyOf(1, 2));
        }
      });
    }
  });

  group('AiEngine — difficulty behaviour', () {
    // White can either hit the black blot on 5 and cover it with the
    // second die, or make quiet moves. Hitting is clearly strongest.
    final hitPosition = Position.custom(
      white: {8: 2, 10: 2, 13: 11},
      black: {5: 1, 19: 7, 20: 7},
    );

    test('hard AI takes the strong hit', () {
      final rng = math.Random(7);
      final play = AiEngine.choosePlay(
        position: hitPosition,
        player: Player.white,
        remainingDice: [3, 5],
        frozenPoints: const {},
        difficulty: AiDifficulty.hard,
        rng: rng,
      );
      expect(play.length, 2);
      expect(play.any((m) => m.hits), isTrue);
    });

    test('medium AI also prefers the hit', () {
      final rng = math.Random(9);
      final play = AiEngine.choosePlay(
        position: hitPosition,
        player: Player.white,
        remainingDice: [3, 5],
        frozenPoints: const {},
        difficulty: AiDifficulty.medium,
        rng: rng,
      );
      expect(play.any((m) => m.hits), isTrue);
    });

    test('easy AI varies its moves (random profile)', () {
      final firstMoves = <int>{};
      var hitsTaken = 0;
      for (var i = 0; i < 24; i++) {
        final rng = math.Random(500 + i);
        final play = AiEngine.choosePlay(
          position: hitPosition,
          player: Player.white,
          remainingDice: [3, 5],
          frozenPoints: const {},
          difficulty: AiDifficulty.easy,
          rng: rng,
        );
        firstMoves.add(play.first.from * 100 + play.first.to);
        if (play.any((m) => m.hits)) hitsTaken++;
      }
      // Random play must produce variety and must not be a perfect hitter.
      expect(firstMoves.length, greaterThan(1));
      expect(hitsTaken, lessThan(24));
    });

    test('deterministic for a given seed', () {
      for (final difficulty in AiDifficulty.values) {
        final a = AiEngine.choosePlay(
          position: hitPosition,
          player: Player.white,
          remainingDice: [3, 5],
          frozenPoints: const {},
          difficulty: difficulty,
          rng: math.Random(99),
        );
        final b = AiEngine.choosePlay(
          position: hitPosition,
          player: Player.white,
          remainingDice: [3, 5],
          frozenPoints: const {},
          difficulty: difficulty,
          rng: math.Random(99),
        );
        expect(b.length, a.length);
        for (var i = 0; i < a.length; i++) {
          expect(b[i], a[i]);
        }
      }
    });
  });

  group('AiEngine — race awareness', () {
    test('hard AI bears off efficiently in a pure race', () {
      // Pure race: white is far ahead and everything is in the home board.
      // With 6 and 5 the efficient play takes two checkers off instead of
      // wasting pips inside the board.
      final racePosition = Position.custom(
        white: {6: 2, 5: 2, 4: 2, 3: 2, 2: 2, 1: 5},
        black: {20: 5, 21: 5, 22: 5},
      );
      final rng = math.Random(3);
      final play = AiEngine.choosePlay(
        position: racePosition,
        player: Player.white,
        remainingDice: [6, 5],
        frozenPoints: const {},
        difficulty: AiDifficulty.hard,
        rng: rng,
      );
      expect(play.length, 2);
      final bearOffs = play.where((m) => m.bearsOff).length;
      expect(bearOffs, 2); // 6 -> off and 5 -> off.
    });
  });
}
