import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/game_config.dart';
import 'package:takhtenard/features/game/domain/models/game_result.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/models/single_move.dart';
import 'package:takhtenard/features/game/domain/engine/takhteh_game.dart';

GameConfig get config => GameConfig(
      mode: GameMode.localMultiplayer,
      difficulty: AiDifficulty.medium,
    );

void main() {
  group('TakhtehGame — opening roll', () {
    test('a tie is re-rolled and keeps the opening phase', () {
      final game = TakhtehGame(config: config);
      final outcome = game.rollOpening(4, 4);
      expect(outcome, OpeningOutcome.tie);
      expect(game.phase, GamePhase.openingRoll);
      expect(game.openingWhiteDie, 4);
      expect(game.openingBlackDie, 4);
    });

    test('the higher die decides the starter', () {
      final game = TakhtehGame(config: config);
      expect(game.rollOpening(5, 2), OpeningOutcome.decided);
      expect(game.current, Player.white);
      expect(game.phase, GamePhase.awaitingRoll);

      final game2 = TakhtehGame(config: config);
      expect(game2.rollOpening(1, 3), OpeningOutcome.decided);
      expect(game2.current, Player.black);
      expect(game2.phase, GamePhase.awaitingRoll);
    });

    test('the starter rolls both dice again (Iranian style)', () {
      final game = TakhtehGame(config: config);
      game.rollOpening(6, 3);
      expect(game.dice, isNull);
      final outcome = game.roll(4, 2);
      expect(game.phase, GamePhase.awaitingMove);
      expect(outcome.noMoves, isFalse);
      expect(game.remaining, [4, 2]);
      expect(game.dice!.first, 4);
      expect(game.dice!.second, 2);
    });

    test('invalid phase transitions throw', () {
      final game = TakhtehGame(config: config);
      expect(() => game.roll(1, 2), throwsStateError);
      game.rollOpening(2, 5);
      expect(() => game.rollOpening(1, 1), throwsStateError);
    });
  });

  group('TakhtehGame — moving and undo', () {
    TakhtehGame startedGame(int d1, int d2) {
      final game = TakhtehGame(config: config);
      game.rollOpening(5, 1); // white starts
      game.roll(d1, d2);
      return game;
    }

    test('legal moves apply and consume their die', () {
      final game = startedGame(5, 3);
      final outcome = game.applyFromTo(13, 8)!;
      expect(outcome.move.from, 13);
      expect(outcome.move.to, 8);
      expect(outcome.move.die, 5);
      expect(outcome.hit, isFalse);
      expect(outcome.diceRemaining, 1);
      expect(game.position.countFor(Player.white, 8), 4);
      expect(game.remaining, [3]);
    });

    test('illegal moves are rejected without side effects', () {
      final game = startedGame(5, 3);
      // 24 -> 19 is blocked by five black checkers.
      expect(game.applyFromTo(24, 19), isNull);
      expect(() {
        game.applyMove(const SingleMove(
          player: Player.white,
          from: 24,
          to: 19,
          die: 5,
          hits: false,
        ));
      }, throwsStateError);
      expect(game.remaining, [5, 3]);
    });

    test('undo restores the state before the last move', () {
      final game = startedGame(5, 3);
      final before = game.position;
      expect(game.canUndo, isFalse);
      game.applyFromTo(13, 8);
      expect(game.canUndo, isTrue);
      final undone = game.undoLastMove()!;
      expect(undone.from, 13);
      expect(game.position, before);
      expect(game.remaining, [5, 3]);
      expect(game.canUndo, isFalse);
      expect(game.undoLastMove(), isNull);
    });

    test('a hit sends the opponent to the bar and pins the hitter', () {
      final game = TakhtehGame(
        config: config,
        initialPosition: Position.custom(
          white: {8: 2, 6: 5, 13: 5, 24: 3},
          black: {5: 1, 19: 5, 17: 3, 12: 5, 1: 1},
        ),
        startingPlayer: Player.white,
        phase: GamePhase.awaitingRoll,
      );
      game.roll(3, 2);
      final outcome = game.applyFromTo(8, 5)!;
      expect(outcome.hit, isTrue);
      expect(game.position.blackBar, 1);
      expect(game.position.countFor(Player.black, 5), 0);
      expect(game.frozen, {5}); // Hit inside white's home board pins it.
    });

    test('turnExhausted fires when no further die can be played', () {
      final game = startedGame(6, 6); // doubles: four moves of six
      expect(game.legalMoves.maxUsableDice, 4);
      expect(game.applyFromTo(24, 18)!.turnExhausted, isFalse);
      expect(game.applyFromTo(13, 7)!.turnExhausted, isFalse);
      expect(game.applyFromTo(8, 2)!.turnExhausted, isFalse);
      final last = game.applyFromTo(13, 7)!;
      expect(last.turnExhausted, isTrue);
      expect(game.remaining, isEmpty);
      expect(game.legalMoves.hasMoves, isFalse);
    });

    test('endTurn passes to the opponent and clears the turn state', () {
      final game = startedGame(6, 3);
      game.applyFromTo(13, 7); // six
      game.applyFromTo(13, 10); // three
      expect(game.turnExhausted, isTrue);
      game.endTurn();
      expect(game.current, Player.black);
      expect(game.phase, GamePhase.awaitingRoll);
      expect(game.dice, isNull);
      expect(game.remaining, isEmpty);
      expect(game.frozen, isEmpty);
      expect(game.canUndo, isFalse);
    });

    test('a roll with no playable dice reports noMoves', () {
      final game = TakhtehGame(
        config: config,
        initialPosition: Position.custom(
          white: {24: 14},
          black: {19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 24: 2},
          whiteBar: 1,
        ),
        startingPlayer: Player.white,
        phase: GamePhase.awaitingRoll,
      );
      final outcome = game.roll(2, 5);
      expect(outcome.noMoves, isTrue);
      expect(game.legalMoves.hasMoves, isFalse);
      game.endTurn();
      expect(game.current, Player.black);
    });
  });

  group('TakhtehGame — winning and scoring', () {
    TakhtehGame endgameGame({int blackOff = 0, int blackBar = 0}) {
      return TakhtehGame(
        config: config,
        initialPosition: Position.custom(
          white: {1: 1, 2: 4, 3: 5, 4: 5},
          black: {19: 5, 20: 5, 21: 5 - blackBar},
          blackBar: blackBar,
          blackOff: blackOff,
        ),
        startingPlayer: Player.white,
        phase: GamePhase.awaitingRoll,
      );
    }

    test('bearing off the last checker wins (normal = 1 point)', () {
      final game = endgameGame(blackOff: 2);
      game.roll(1, 3);
      final outcome = game.applyFromTo(1, 0)!;
      expect(outcome.won, isTrue);
      expect(game.phase, GamePhase.gameOver);
      expect(game.result!.winner, Player.white);
      expect(game.result!.winType, WinType.normal);
      expect(game.result!.points, 1);
    });

    test('a win where the loser bore off nothing is a mars (2 points)', () {
      final game = endgameGame();
      game.roll(1, 3);
      game.applyFromTo(1, 0);
      expect(game.result!.winType, WinType.gammon);
      expect(game.result!.points, 2);
    });

    test('a loser with checkers on the bar still only counts as mars', () {
      // Traditional Iranian rules know no separate "backgammon" score:
      // every such win is counted as a mars.
      final game = endgameGame(blackBar: 1);
      game.roll(1, 3);
      game.applyFromTo(1, 0);
      expect(game.result!.winType, WinType.gammon);
      expect(game.result!.points, 2);
    });
  });

  group('TakhtehGame — serialization', () {
    test('round-trips a game in progress', () {
      final game = TakhtehGame(config: config);
      game.rollOpening(6, 2);
      game.roll(6, 3);
      game.applyFromTo(24, 18);
      game.applyFromTo(18, 15);

      final restored = TakhtehGame.fromJson(game.toJson(), config);

      expect(restored.phase, game.phase);
      expect(restored.current, game.current);
      expect(restored.position, game.position);
      expect(restored.remaining, game.remaining);
      expect(restored.dice, game.dice);
      expect(
        restored.movesPlayedThisTurn.length,
        game.movesPlayedThisTurn.length,
      );
      expect(restored.openingWhiteDie, 6);
      expect(restored.openingBlackDie, 2);
    });

    test('round-trips a finished game with its result', () {
      final game = TakhtehGame(
        config: config,
        initialPosition: Position.custom(
          white: {1: 1, 2: 4, 3: 5, 4: 5},
          black: {19: 5, 20: 5, 21: 5},
        ),
        startingPlayer: Player.white,
        phase: GamePhase.awaitingRoll,
      );
      game.roll(1, 3);
      game.applyFromTo(1, 0);

      final restored = TakhtehGame.fromJson(game.toJson(), config);
      expect(restored.phase, GamePhase.gameOver);
      expect(restored.result!.winType, WinType.gammon);
      expect(restored.result!.points, 2);
    });
  });
}
