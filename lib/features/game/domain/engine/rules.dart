import '../models/player.dart';
import '../models/position.dart';
import '../models/single_move.dart';

/// Pure rule functions of traditional Iranian Takhteh Nard.
///
/// Every function is static and side-effect free so the whole rule set is
/// trivially unit-testable and independent from any UI framework.
abstract final class Rules {
  /// All legal moves [player] can make with a single [die] from [position].
  ///
  /// [frozenPoints] contains points on which this player has already hit an
  /// opponent blot inside their own home board during the current turn. Per
  /// the traditional Iranian rule the checker that performed such a hit may
  /// not be moved again during the same turn ("no hit-and-run"). When
  /// [honorFreezes] is false these restrictions are ignored; the move search
  /// uses that to detect whether dice would otherwise be wasted
  /// ("khal-soozi"), which lifts the restriction.
  static List<SingleMove> legalMovesForDie(
    Position position,
    Player player,
    int die, {
    Set<int> frozenPoints = const <int>{},
    bool honorFreezes = true,
  }) {
    final moves = <SingleMove>[];

    // A player with checkers on the bar must re-enter before doing anything
    // else. Re-entry lands inside the opponent's home board.
    if (position.barCount(player) > 0) {
      final entry = player.entryPoint(die);
      if (entry >= 1 && entry <= 24 && position.isOpenFor(player, entry)) {
        moves.add(
          SingleMove(
            player: player,
            from: kBarFrom,
            to: entry,
            die: die,
            hits: _isBlot(position, player, entry),
          ),
        );
      }
      return moves;
    }

    for (var p = 1; p <= 24; p++) {
      final count = position.countFor(player, p);
      if (count == 0) continue;

      // Traditional Iranian restriction: the checker that hit an opponent
      // blot inside the player's own home board is pinned for the rest of
      // the turn. If further checkers have stacked on the same point at
      // least one checker stays pinned, but the others may still move.
      if (honorFreezes && frozenPoints.contains(p) && count <= 1) {
        continue;
      }

      final dest = player == Player.white ? p - die : p + die;

      if (dest >= 1 && dest <= 24) {
        if (position.isOpenFor(player, dest)) {
          moves.add(
            SingleMove(
              player: player,
              from: p,
              to: dest,
              die: die,
              hits: _isBlot(position, player, dest),
            ),
          );
        }
      } else {
        // The checker would move past the edge of the board: a potential
        // bear-off. Legal only when every checker is inside the home board.
        if (_canBearOff(position, player, p, die)) {
          moves.add(
            SingleMove(
              player: player,
              from: p,
              to: kBearOffTo,
              die: die,
              hits: false,
            ),
          );
        }
      }
    }

    return moves;
  }

  /// Whether landing [player]'s checker on [point] would hit an opponent
  /// blot (exactly one opposing checker).
  static bool _isBlot(Position position, Player player, int point) {
    final owner = position.ownerAt(point);
    return owner != null && owner != player && position.countAt(point) == 1;
  }

  /// Bearing off rules:
  ///  * all checkers must be inside the player's home board (none on bar);
  ///  * a die bears off the exactly matching point;
  ///  * a higher die may bear off from the highest occupied point that is
  ///    lower than the die value.
  static bool _canBearOff(Position position, Player player, int from, int die) {
    if (!position.allInHome(player)) return false;

    final ownNumbering = player == Player.white ? from : 25 - from;
    if (ownNumbering > die) return false; // Die too small: normal move only.

    // Exact match always allowed.
    if (ownNumbering == die) return true;

    // Higher die: only from the highest occupied point.
    return position.highestHomePoint(player) == ownNumbering;
  }

  /// Whether the game has turned into a pure race (no more contact): no
  /// checker of either side can ever land on the other side again. This is
  /// symmetric in [player] and only kept as a parameter for readability.
  ///
  /// White travels towards 1 and black towards 24, so the two armies can
  /// still collide iff the highest white checker is above the lowest black
  /// checker. The race is over once they have completely passed each other
  /// (and nobody sits on the bar).
  static bool isRaceOver(Position position, Player player) {
    if (position.barCount(Player.white) > 0 ||
        position.barCount(Player.black) > 0) {
      return false;
    }

    var maxWhite = -1;
    var minBlack = 25;
    for (var p = 1; p <= 24; p++) {
      if (position.countFor(Player.white, p) > 0 && p > maxWhite) {
        maxWhite = p;
      }
      if (position.countFor(Player.black, p) > 0 && p < minBlack) {
        minBlack = p;
      }
    }
    // A side with every checker borne off cannot have contact either.
    if (maxWhite == -1 || minBlack == 25) return true;

    return maxWhite < minBlack;
  }
}

