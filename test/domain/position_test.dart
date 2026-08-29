import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/models/single_move.dart';

void main() {
  group('Position.initial', () {
    final pos = Position.initial();

    test('has the traditional starting layout', () {
      expect(pos.countFor(Player.white, 24), 2);
      expect(pos.countFor(Player.white, 13), 5);
      expect(pos.countFor(Player.white, 8), 3);
      expect(pos.countFor(Player.white, 6), 5);

      expect(pos.countFor(Player.black, 1), 2);
      expect(pos.countFor(Player.black, 12), 5);
      expect(pos.countFor(Player.black, 17), 3);
      expect(pos.countFor(Player.black, 19), 5);
    });

    test('holds 15 checkers per side', () {
      var white = pos.whiteBar + pos.whiteOff;
      var black = pos.blackBar + pos.blackOff;
      for (var p = 1; p <= 24; p++) {
        white += pos.countFor(Player.white, p);
        black += pos.countFor(Player.black, p);
      }
      expect(white, 15);
      expect(black, 15);
    });

    test('starts with 167 pips per side', () {
      expect(pos.pipCount(Player.white), 167);
      expect(pos.pipCount(Player.black), 167);
    });

    test('nobody is on the bar or borne off', () {
      expect(pos.whiteBar, 0);
      expect(pos.blackBar, 0);
      expect(pos.whiteOff, 0);
      expect(pos.blackOff, 0);
    });
  });

  group('Position helpers', () {
    test('isClosedFor detects opponent-made points', () {
      final pos = Position.custom(white: {6: 5}, black: {1: 2, 5: 1});
      // Point 1 has two black checkers: closed for white, open for black.
      expect(pos.isClosedFor(Player.white, 1), isTrue);
      expect(pos.isClosedFor(Player.black, 1), isFalse);
      // Point 5 has a single black checker: a blot, open for white (hit!).
      expect(pos.isClosedFor(Player.white, 5), isFalse);
      expect(pos.isOpenFor(Player.white, 5), isTrue);
      // Own points are always open.
      expect(pos.isClosedFor(Player.white, 6), isFalse);
    });

    test('allInHome requires every checker in the home board', () {
      expect(
        Position.custom(white: {6: 5, 3: 10}).allInHome(Player.white),
        isTrue,
      );
      expect(
        Position.custom(white: {6: 5, 8: 10}).allInHome(Player.white),
        isFalse,
      );
      expect(
        Position.custom(white: {6: 5, 3: 10}, whiteBar: 1).allInHome(
          Player.white,
        ),
        isFalse,
      );
      expect(
        Position.custom(black: {19: 5, 24: 10}).allInHome(Player.black),
        isTrue,
      );
      expect(
        Position.custom(black: {19: 5, 17: 10}).allInHome(Player.black),
        isFalse,
      );
    });

    test('highestHomePoint finds the farthest occupied home point', () {
      expect(
        Position.custom(white: {6: 2, 4: 3, 1: 5}).highestHomePoint(
          Player.white,
        ),
        6,
      );
      expect(
        Position.custom(white: {4: 3, 1: 5}).highestHomePoint(Player.white),
        4,
      );
      // Black's own numbering: absolute 19 == own point 6.
      expect(
        Position.custom(black: {19: 2, 22: 3}).highestHomePoint(Player.black),
        6,
      );
      expect(Position.custom(black: {22: 3}).highestHomePoint(Player.black), 3);
    });

    test('pipCount counts bar checkers as 25', () {
      final pos = Position.custom(white: const {}, black: const {}, whiteBar: 2);
      expect(pos.pipCount(Player.white), 50);
    });

    test('applyMove moves, hits and bears off correctly', () {
      final pos = Position.custom(white: {8: 2}, black: {5: 1});
      final hit = pos.applyMove(
        const SingleMove(
          player: Player.white,
          from: 8,
          to: 5,
          die: 3,
          hits: true,
        ),
      );
      expect(hit.countFor(Player.white, 5), 1);
      expect(hit.countFor(Player.white, 8), 1);
      expect(hit.blackBar, 1);

      final bearOff = Position.custom(white: {3: 15}).applyMove(
        const SingleMove(
          player: Player.white,
          from: 3,
          to: kBearOffTo,
          die: 3,
          hits: false,
        ),
      );
      expect(bearOff.whiteOff, 1);
      expect(bearOff.countFor(Player.white, 3), 14);
    });

    test('serialization round-trips', () {
      final pos = Position.custom(
        white: {24: 2, 6: 5},
        black: {1: 2},
        whiteBar: 1,
        blackBar: 2,
        whiteOff: 3,
        blackOff: 4,
      );
      final restored = Position.fromJson(pos.toJson());
      expect(restored, pos);
    });
  });

  group('Player conventions', () {
    test('home boards and directions are consistent', () {
      expect(Player.white.homeLow, 1);
      expect(Player.white.homeHigh, 6);
      expect(Player.black.homeLow, 19);
      expect(Player.black.homeHigh, 24);
      expect(Player.white.travelDelta, -1);
      expect(Player.black.travelDelta, 1);
      expect(Player.white.isOwnHome(3), isTrue);
      expect(Player.white.isOwnHome(19), isFalse);
      expect(Player.black.isOwnHome(19), isTrue);
    });

    test('bar entry lands in the opponent home board', () {
      // White enters at 25 - die, i.e. points 19..24 (black's home).
      expect(Player.white.entryPoint(1), 24);
      expect(Player.white.entryPoint(6), 19);
      // Black enters at points 1..6 (white's home).
      expect(Player.black.entryPoint(1), 1);
      expect(Player.black.entryPoint(6), 6);
    });
  });
}
