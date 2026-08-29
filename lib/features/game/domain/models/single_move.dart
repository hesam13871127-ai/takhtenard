import 'player.dart';

/// Marker for the "from" location of a move that plays a checker off the bar.
const int kBarFrom = 25;

/// Marker for the "to" location of a move that bears a checker off.
const int kBearOffTo = 0;

/// A single checker move played with one die.
///
/// [from] is either a point index (`1..24`) or [kBarFrom] when the checker
/// comes off the bar. [to] is either a point index (`1..24`) or [kBearOffTo]
/// when the checker is borne off the board.
class SingleMove {
  const SingleMove({
    required this.player,
    required this.from,
    required this.to,
    required this.die,
    required this.hits,
  });

  final Player player;
  final int from;
  final int to;
  final int die;

  /// Whether this move lands on a single opponent checker (a blot) and
  /// therefore hits it, sending it to the bar.
  final bool hits;

  bool get entersFromBar => from == kBarFrom;
  bool get bearsOff => to == kBearOffTo;

  /// A short human-readable description, useful for logging and tests.
  @override
  String toString() =>
      '${player.name}: ${_loc(from)} -> ${_loc(to)} (die $die'
      '${hits ? ', hit' : ''})';

  static String _loc(int l) {
    if (l == kBarFrom) return 'bar';
    if (l == kBearOffTo) return 'off';
    return '$l';
  }

  @override
  bool operator ==(Object other) =>
      other is SingleMove &&
      other.player == player &&
      other.from == from &&
      other.to == to &&
      other.die == die &&
      other.hits == hits;

  @override
  int get hashCode => Object.hash(player, from, to, die, hits);
}
