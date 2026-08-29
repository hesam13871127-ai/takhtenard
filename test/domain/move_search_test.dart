import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/models/single_move.dart';
import 'package:takhtenard/features/game/domain/engine/move_search.dart';

void main() {
  group('MoveSearch — doubles and maximum usage', () {
    test('doubles grant four moves from the opening position', () {
      final result = MoveSearch.search(
        position: Position.initial(),
        player: Player.white,
        remainingDice: [3, 3, 3, 3],
      );
      expect(result.maxUsableDice, 4);
      expect(result.sequences, isNotEmpty);
      for (final sequence in result.sequences) {
        expect(sequence.length, 4);
      }
    });

    test('cannot waste dice when only one die is playable', () {
      // White has a single mobile checker on 8; black owns point 6.
      final pos = Position.custom(white: {8: 1, 1: 13}, black: {6: 2});
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [2, 6],
      );
      expect(result.maxUsableDice, 1);
      // Only 8 -> 2 with the six is legal.
      expect(result.firstMoves.length, 1);
      expect(result.firstMoves.single.from, 8);
      expect(result.firstMoves.single.to, 2);
      expect(result.firstMoves.single.die, 6);
      // The blocked destination can never be resolved.
      expect(result.resolve(8, 6), isNull);
    });

    test('higher die must be used when both dice play alone but not together',
        () {
      // White enters from the bar; black owns 17, 18 and 22. Entering with
      // either die is possible, but after entering no second die can be
      // played — so the higher die (6) must be used for the entry.
      final pos = Position.custom(
        white: {24: 14},
        black: {17: 2, 18: 2, 22: 2},
        whiteBar: 1,
      );
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [2, 6],
      );
      expect(result.maxUsableDice, 1);
      expect(result.firstMoves.length, 1);
      expect(result.firstMoves.single.die, 6);
      expect(result.firstMoves.single.from, kBarFrom);
      expect(result.firstMoves.single.to, 19);
    });

    test('returns no moves when everything is blocked', () {
      // White is on the bar and black's home board is completely closed.
      final pos = Position.custom(
        white: {24: 14},
        black: {19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 24: 2},
        whiteBar: 1,
      );
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [2, 5],
      );
      expect(result.maxUsableDice, 0);
      expect(result.firstMoves, isEmpty);
      expect(result.sequences, isEmpty);
    });

    test('a player on the bar must enter all checkers first', () {
      // Two white checkers on the bar; entry with 1 is blocked (24 made).
      final pos = Position.custom(
        white: {6: 13},
        black: {24: 2},
        whiteBar: 2,
      );
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [1, 5],
      );
      // Enter with the 5 on point 20; the second bar checker cannot enter
      // with the 1, and no other checker may move while white is on the bar.
      expect(result.maxUsableDice, 1);
      expect(result.firstMoves.single.to, 20);
      expect(result.firstMoves.single.die, 5);
    });
  });

  group('MoveSearch — Iranian no-hit-and-run restriction', () {
    test('the hitting checker is pinned inside the home board', () {
      // White 8 -> 5 hits a blot inside white's home board; the die 2 then
      // belongs to another checker (10 -> 8), not to the pinned one.
      final afterHit = Position.custom(white: {5: 1, 10: 1}, black: {});
      final result = MoveSearch.search(
        position: afterHit,
        player: Player.white,
        remainingDice: [2],
        frozenPoints: {5},
      );
      expect(result.maxUsableDice, 1);
      expect(result.firstMoves.any((m) => m.from == 10 && m.to == 8), isTrue);
      expect(result.firstMoves.any((m) => m.from == 5 && m.to == 3), isFalse);
      expect(result.freezesLifted, isFalse);
    });

    test('the restriction is lifted when dice would otherwise be wasted', () {
      // White's only checker starts at 9. With 4+2:
      //  * 9 -> 5 with the 4 hits a blot inside white's home board,
      //  * playing the 2 first (9 -> 7) is blocked by black's made point,
      //  * after the hit the pinned checker on 5 is the only one able to
      //    play the 2 (5 -> 3).
      // Honoring the pin would waste the 2 ("khal-soozi"), so the
      // restriction must be lifted and both dice played.
      final pos = Position.custom(white: {9: 1}, black: {5: 1, 7: 2});
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [4, 2],
      );
      expect(result.maxUsableDice, 2);
      expect(result.freezesLifted, isTrue);
      expect(result.firstMoves.single.from, 9);
      expect(result.firstMoves.single.to, 5);
      expect(result.firstMoves.single.hits, isTrue);

      // After applying the hit, the lifted move 5 -> 3 must be offered.
      final afterHit = pos.applyMove(result.firstMoves.single);
      final rest = MoveSearch.search(
        position: afterHit,
        player: Player.white,
        remainingDice: [2],
        frozenPoints: {5},
      );
      expect(rest.maxUsableDice, 1);
      expect(rest.freezesLifted, isTrue);
      expect(rest.firstMoves.single.from, 5);
      expect(rest.firstMoves.single.to, 3);
    });

    test('hits outside the home board do not pin the checker', () {
      // 10 -> 7 hits outside white's home board (7 > 6): no pin, the same
      // checker may continue with the second die.
      final pos = Position.custom(white: {10: 1}, black: {7: 1});
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [3, 2],
      );
      expect(result.maxUsableDice, 2);
      final hitAndRun = result.sequences.firstWhere(
        (s) => s.first.from == 10 && s.first.to == 7,
        orElse: () => const [],
      );
      expect(hitAndRun, isNotEmpty);
      expect(hitAndRun.any((m) => m.from == 7 && m.to == 5), isTrue);
    });

    test('a stacked pinned point may spare its extra checker', () {
      // After hitting on 5 with doubles (3,3,3,3), white stacks another
      // checker on 5; one checker stays pinned but the other may leave.
      final pos = Position.custom(white: {5: 2, 11: 1, 8: 1}, black: {});
      final result = MoveSearch.search(
        position: pos,
        player: Player.white,
        remainingDice: [3],
        frozenPoints: {5},
      );
      expect(result.firstMoves.any((m) => m.from == 5 && m.to == 2), isTrue);
    });
  });

  group('MoveSearch — firstMoves preserve maximum dice usage', () {
    test('every first move keeps the full sequence achievable', () {
      final rngMoves = MoveSearch.search(
        position: Position.initial(),
        player: Player.white,
        remainingDice: [6, 4],
      );
      expect(rngMoves.maxUsableDice, 2);
      for (final move in rngMoves.firstMoves) {
        final next = Position.initial().applyMove(move);
        final rest = MoveSearch.search(
          position: next,
          player: Player.white,
          remainingDice: [move.die == 6 ? 4 : 6],
        );
        expect(
          rest.maxUsableDice,
          1,
          reason: 'After $move the second die must still be playable.',
        );
      }
    });
  });
}
