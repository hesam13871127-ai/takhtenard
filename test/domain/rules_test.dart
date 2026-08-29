import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/engine/rules.dart';
import 'package:takhtenard/features/game/domain/models/single_move.dart';

void main() {
  group('Rules.legalMovesForDie — basic movement', () {
    test('white moves towards lower point numbers', () {
      final moves = Rules.legalMovesForDie(
        Position.initial(),
        Player.white,
        5,
      );
      // From the initial position with a 5: 13 -> 8 and 8 -> 3 are open,
      // 24 -> 19 is blocked by five black checkers, 6 -> 1 is blocked too.
      expect(moves.length, 2);
      expect(moves.map((m) => m.from), containsAll(<int>[13, 8]));
      for (final m in moves) {
        expect(m.to, m.from - 5);
        expect(m.hits, isFalse);
      }
    });

    test('black moves towards higher point numbers', () {
      final moves = Rules.legalMovesForDie(
        Position.initial(),
        Player.black,
        5,
      );
      // Black mirror: 12 -> 17 and 17 -> 22 are open.
      expect(moves.length, 2);
      expect(moves.map((m) => m.from), containsAll(<int>[12, 17]));
      for (final m in moves) {
        expect(m.to, m.from + 5);
      }
    });

    test('landing on own checkers is allowed', () {
      final pos = Position.custom(white: {8: 2, 3: 2});
      final moves = Rules.legalMovesForDie(pos, Player.white, 5);
      expect(moves.any((m) => m.from == 8 && m.to == 3), isTrue);
    });

    test('landing on an opponent blot hits', () {
      final pos = Position.custom(white: {10: 1}, black: {5: 1});
      final moves = Rules.legalMovesForDie(pos, Player.white, 5);
      expect(moves.length, 1);
      expect(moves.first.hits, isTrue);
      expect(moves.first.from, 10);
      expect(moves.first.to, 5);
    });
  });

  group('Rules.legalMovesForDie — bar and re-entry', () {
    test('checkers on the bar must enter first', () {
      final pos = Position.custom(
        white: {6: 5, 13: 5},
        black: {1: 2},
        whiteBar: 1,
      );
      // A 3 must enter on point 22; nothing else may move.
      final moves = Rules.legalMovesForDie(pos, Player.white, 3);
      expect(moves.length, 1);
      expect(moves.single.from, kBarFrom);
      expect(moves.single.to, 22);
      expect(moves.single.entersFromBar, isTrue);
    });

    test('entry onto a closed point is illegal', () {
      final pos = Position.custom(
        white: {},
        black: {22: 2},
        whiteBar: 1,
      );
      final moves = Rules.legalMovesForDie(pos, Player.white, 3);
      expect(moves, isEmpty);
    });

    test('entry onto an opponent blot hits it', () {
      final pos = Position.custom(white: {}, black: {22: 1}, whiteBar: 1);
      final moves = Rules.legalMovesForDie(pos, Player.white, 3);
      expect(moves.single.hits, isTrue);
      expect(moves.single.to, 22);
    });

    test('black enters on points 1..6', () {
      final pos = Position.custom(white: {5: 2}, black: {}, blackBar: 1);
      final moves = Rules.legalMovesForDie(pos, Player.black, 5);
      // Black enters a 5 on point 5, which is made by white: blocked.
      expect(moves, isEmpty);

      final openPos = Position.custom(white: {}, black: {}, blackBar: 1);
      final openMoves = Rules.legalMovesForDie(openPos, Player.black, 5);
      expect(openMoves.single.to, 5);
    });
  });

  group('Rules.legalMovesForDie — bearing off', () {
    test('exact die bears off the matching point', () {
      final pos = Position.custom(white: {6: 5, 5: 5, 4: 5});
      final moves = Rules.legalMovesForDie(pos, Player.white, 6);
      final bearOffs = moves.where((m) => m.bearsOff).toList();
      expect(bearOffs.length, 1);
      expect(bearOffs.single.from, 6);
      expect(bearOffs.single.die, 6);
    });

    test('higher die bears off from the highest occupied point only', () {
      final pos = Position.custom(white: {4: 1, 3: 5, 1: 9});
      // Die 6: exact point 6 is empty; the highest occupied point is 4,
      // so only the checker on 4 may come off.
      final moves = Rules.legalMovesForDie(pos, Player.white, 6);
      final bearOffs = moves.where((m) => m.bearsOff).toList();
      expect(bearOffs.length, 1);
      expect(bearOffs.single.from, 4);

      // When the highest occupied point (5) is greater than the die (3),
      // no checker may bear off: the die is too small everywhere.
      final pos2 = Position.custom(white: {5: 5, 1: 10});
      final moves2 = Rules.legalMovesForDie(pos2, Player.white, 3);
      expect(moves2.where((m) => m.bearsOff), isEmpty);
      // A small die still moves normally: 5 -> 2.
      expect(moves2.any((m) => m.from == 5 && m.to == 2), isTrue);

      // The lower point (1) may never overshoot while point 5 is occupied.
      final pos3 = Position.custom(white: {5: 5, 1: 10});
      final moves3 = Rules.legalMovesForDie(pos3, Player.white, 6);
      final offs3 = moves3.where((m) => m.bearsOff).toList();
      expect(offs3.length, 1);
      expect(offs3.single.from, 5);
    });

    test('bearing off requires all checkers in the home board', () {
      final pos = Position.custom(white: {6: 5, 5: 5, 8: 5});
      final moves = Rules.legalMovesForDie(pos, Player.white, 6);
      expect(moves.where((m) => m.bearsOff), isEmpty);
      // 6 -> ... with a 6 would leave the board: not allowed, so point 6
      // offers no move at all here.
      expect(moves.where((m) => m.from == 6), isEmpty);
    });

    test('checkers on the bar prevent bearing off', () {
      final pos = Position.custom(
        white: {6: 5, 5: 5, 4: 4},
        whiteBar: 1,
      );
      final moves = Rules.legalMovesForDie(pos, Player.white, 6);
      // Only the bar entry is offered.
      expect(moves.length, 1);
      expect(moves.single.entersFromBar, isTrue);
    });

    test('black bears off from its own numbering', () {
      // Black home is 19..24; black own point 6 is absolute 19.
      final pos = Position.custom(black: {19: 5, 20: 5, 21: 5});
      final moves = Rules.legalMovesForDie(pos, Player.black, 6);
      final bearOffs = moves.where((m) => m.bearsOff).toList();
      expect(bearOffs.length, 1);
      expect(bearOffs.single.from, 19);

      // Overshoot: die 5 from own point 4 (absolute 21) when it is the
      // highest occupied black point.
      final pos2 = Position.custom(black: {21: 1, 23: 2, 24: 12});
      final moves2 = Rules.legalMovesForDie(pos2, Player.black, 5);
      final offs = moves2.where((m) => m.bearsOff).toList();
      expect(offs.length, 1);
      expect(offs.single.from, 21);
    });
  });

  group('Rules.legalMovesForDie — Iranian hit-and-run restriction', () {
    test('a frozen checker in the home board may not move again', () {
      // White just hit on point 5 (inside its home board) with the checker
      // from 8; the die 2 remains and the hitting checker is pinned.
      final pos = Position.custom(white: {5: 1, 10: 1}, black: {});
      final frozen = <int>{5};
      final moves = Rules.legalMovesForDie(
        pos,
        Player.white,
        2,
        frozenPoints: frozen,
      );
      // Point 5 is pinned; the checker on 10 may still move 10 -> 8.
      expect(moves.any((m) => m.from == 5 && m.to == 3), isFalse);
      expect(moves.any((m) => m.from == 10 && m.to == 8), isTrue);
    });

    test('a stacked frozen point may spare the extra checker', () {
      // Two white checkers on frozen point 5: one is pinned, one may move.
      final pos = Position.custom(white: {5: 2}, black: {});
      final moves = Rules.legalMovesForDie(
        pos,
        Player.white,
        2,
        frozenPoints: const {5},
      );
      expect(moves.any((m) => m.from == 5 && m.to == 3), isTrue);
    });

    test('hits outside the home board do not freeze', () {
      // The freeze only applies to hits that land in the own home board.
      final pos = Position.custom(white: {10: 1}, black: {});
      final moves = Rules.legalMovesForDie(
        pos,
        Player.white,
        3,
        frozenPoints: const {7},
      );
      // Point 7 is outside white's home; frozen points passed in from hits
      // there never exist, so this merely documents the behaviour.
      expect(moves.any((m) => m.from == 10 && m.to == 7), isTrue);
    });

    test('honorFreezes=false ignores the restriction', () {
      final pos = Position.custom(white: {5: 1, 10: 1}, black: {});
      final moves = Rules.legalMovesForDie(
        pos,
        Player.white,
        2,
        frozenPoints: const {5},
        honorFreezes: false,
      );
      expect(moves.any((m) => m.from == 5 && m.to == 3), isTrue);
    });
  });

  group('Rules.isRaceOver', () {
    test('detects when contact is broken', () {
      // All white checkers completely below all black checkers: pure race.
      final race = Position.custom(white: {1: 5, 2: 5, 3: 5}, black: {
        22: 5,
        23: 5,
        24: 5,
      });
      expect(Rules.isRaceOver(race, Player.white), isTrue);
      expect(Rules.isRaceOver(race, Player.black), isTrue);

      // Contact: the highest white checker (23) is above the lowest black
      // checker (22), so white can still land on black.
      final contact = Position.custom(white: {1: 5, 2: 5, 23: 5}, black: {
        22: 5,
        23: 0,
        24: 5,
      });
      expect(Rules.isRaceOver(contact, Player.white), isFalse);
      expect(Rules.isRaceOver(contact, Player.black), isFalse);
    });

    test('checkers on the bar mean contact', () {
      final pos = Position.custom(
        white: {1: 15},
        black: {24: 14},
        blackBar: 1,
      );
      expect(Rules.isRaceOver(pos, Player.white), isFalse);
    });
  });
}
