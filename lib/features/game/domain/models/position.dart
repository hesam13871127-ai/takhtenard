import 'player.dart';
import 'single_move.dart';

/// Immutable snapshot of all checkers on the board.
///
/// The 24 points are stored as signed counts: a positive value means [n]
/// white checkers, a negative value means [n] black checkers. Index `0` is
/// unused so that indices line up with point numbers `1..24`.
class Position {
  const Position._({
    required List<int> points,
    required this.whiteBar,
    required this.blackBar,
    required this.whiteOff,
    required this.blackOff,
  }) : _points = points;

  /// Length-25 list; index 0 unused. Positive = white, negative = black.
  final List<int> _points;

  /// Number of white checkers waiting on the bar.
  final int whiteBar;

  /// Number of black checkers waiting on the bar.
  final int blackBar;

  /// Number of white checkers already borne off.
  final int whiteOff;

  /// Number of black checkers already borne off.
  final int blackOff;

  /// The traditional starting position of Takhteh Nard.
  factory Position.initial() {
    final points = List<int>.filled(25, 0);
    // White (moves 24 -> 1, home 1..6).
    points[24] = 2; // back checkers
    points[13] = 5; // outer
    points[8] = 3; // outer
    points[6] = 5; // home
    // Black mirrors on the opposite side (moves 1 -> 24, home 19..24).
    points[1] = -2;
    points[12] = -5;
    points[17] = -3;
    points[19] = -5;
    return Position._(
      points: points,
      whiteBar: 0,
      blackBar: 0,
      whiteOff: 0,
      blackOff: 0,
    );
  }

  /// Builds a position from explicit counts. Mostly used by tests.
  factory Position.custom({
    required Map<int, int> white,
    required Map<int, int> black,
    int whiteBar = 0,
    int blackBar = 0,
    int whiteOff = 0,
    int blackOff = 0,
  }) {
    final points = List<int>.filled(25, 0);
    white.forEach((p, n) => points[p] += n);
    black.forEach((p, n) => points[p] -= n);
    return Position._(
      points: points,
      whiteBar: whiteBar,
      blackBar: blackBar,
      whiteOff: whiteOff,
      blackOff: blackOff,
    );
  }

  /// Signed count at [point] (positive = white, negative = black).
  int rawAt(int point) => _points[point];

  /// Absolute number of checkers standing on [point].
  int countAt(int point) => _points[point].abs();

  /// Owner of the checkers on [point], or `null` when empty.
  Player? ownerAt(int point) {
    final v = _points[point];
    if (v == 0) return null;
    return v > 0 ? Player.white : Player.black;
  }

  /// Number of checkers of [player] on [point].
  int countFor(Player player, int point) {
    final v = _points[point];
    if (v == 0) return 0;
    return (v > 0 ? Player.white : Player.black) == player ? v.abs() : 0;
  }

  /// Whether [point] holds two or more checkers of the opponent of [player],
  /// i.e. it is closed and [player] may not land there.
  bool isClosedFor(Player player, int point) {
    final v = _points[point];
    if (v == 0) return false;
    final owner = v > 0 ? Player.white : Player.black;
    return owner != player && v.abs() >= 2;
  }

  /// Whether [player] may land on [point] (empty, own, or a single blot).
  bool isOpenFor(Player player, int point) => !isClosedFor(player, point);

  /// Number of [player]'s checkers on the bar.
  int barCount(Player player) =>
      player == Player.white ? whiteBar : blackBar;

  /// Number of [player]'s checkers borne off.
  int offCount(Player player) =>
      player == Player.white ? whiteOff : blackOff;

  /// Whether every checker of [player] is inside their home board (and none
  /// is on the bar) — the precondition for bearing off.
  bool allInHome(Player player) {
    if (barCount(player) > 0) return false;
    for (var p = 1; p <= 24; p++) {
      if (_points[p] == 0) continue;
      final owner = _points[p] > 0 ? Player.white : Player.black;
      if (owner == player && !player.isOwnHome(p)) return false;
    }
    return true;
  }

  /// The highest occupied point of [player] inside their home board relative
  /// to their own numbering (1 = closest to bearing off), or 0 if none.
  int highestHomePoint(Player player) {
    // White's "highest" home point is the largest index 1..6 (farthest from
    // off), black's is the smallest index 19..24 in absolute terms, which in
    // black's own numbering is 25 - point.
    if (player == Player.white) {
      for (var p = 6; p >= 1; p--) {
        if (countFor(player, p) > 0) return p;
      }
    } else {
      for (var p = 19; p <= 24; p++) {
        if (countFor(player, p) > 0) return 25 - p;
      }
    }
    return 0;
  }

  /// Highest point (own numbering) inside home occupied by [player], used
  /// for the "wastage aware" bearing off rule.
  int countInHome(Player player) {
    var n = 0;
    for (var p = player.homeLow; p <= player.homeHigh; p++) {
      n += countFor(player, p);
    }
    return n;
  }

  /// Total pip count of [player] (distance remaining to bear everything off).
  int pipCount(Player player) {
    var pips = 25 * barCount(player);
    for (var p = 1; p <= 24; p++) {
      final n = countFor(player, p);
      if (n == 0) continue;
      final ownNumbering = player == Player.white ? p : 25 - p;
      pips += n * ownNumbering;
    }
    return pips;
  }

  /// Whether [player] still has any checker in the opponent's home board or
  /// on the bar (i.e. contact with the opponent's home board exists).
  bool hasBackCheckers(Player player) {
    if (barCount(player) > 0) return true;
    final oppHomeLow = player.opponent.homeLow;
    final oppHomeHigh = player.opponent.homeHigh;
    for (var p = oppHomeLow; p <= oppHomeHigh; p++) {
      if (countFor(player, p) > 0) return true;
    }
    return false;
  }

  /// Applies [move] and returns the resulting position together with the
  /// resulting position. The caller guarantees [move] is legal; this method
  /// performs no validation beyond applying the hit.
  Position applyMove(SingleMove move) {
    final points = List<int>.from(_points);
    var wBar = whiteBar;
    var bBar = blackBar;
    var wOff = whiteOff;
    var bOff = blackOff;
    final player = move.player;

    // Remove the checker from its origin.
    if (move.entersFromBar) {
      if (player == Player.white) {
        wBar--;
      } else {
        bBar--;
      }
    } else {
      points[move.from] += player == Player.white ? -1 : 1;
    }

    // Place the checker at its destination.
    if (move.bearsOff) {
      if (player == Player.white) {
        wOff++;
      } else {
        bOff++;
      }
    } else {
      if (move.hits) {
        // Send the opponent's blot to the bar.
        points[move.to] = 0;
        if (player == Player.white) {
          bBar++;
        } else {
          wBar++;
        }
      }
      points[move.to] += player == Player.white ? 1 : -1;
    }

    return Position._(
      points: points,
      whiteBar: wBar,
      blackBar: bBar,
      whiteOff: wOff,
      blackOff: bOff,
    );
  }

  /// Compact, stable key used for memoization and serialization.
  String key() {
    final sb = StringBuffer();
    for (var p = 1; p <= 24; p++) {
      sb.write(_points[p]);
      sb.write(',');
    }
    sb..write('w$whiteBar,')..write('b$blackBar,');
    return sb.toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'points': List<int>.from(_points),
        'whiteBar': whiteBar,
        'blackBar': blackBar,
        'whiteOff': whiteOff,
        'blackOff': blackOff,
      };

  factory Position.fromJson(Map<String, Object?> json) {
    final raw = (json['points']! as List).cast<int>();
    final points = List<int>.filled(25, 0);
    for (var i = 0; i < raw.length && i < 25; i++) {
      points[i] = raw[i];
    }
    return Position._(
      points: points,
      whiteBar: json['whiteBar']! as int,
      blackBar: json['blackBar']! as int,
      whiteOff: json['whiteOff']! as int,
      blackOff: json['blackOff']! as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Position &&
      other.whiteBar == whiteBar &&
      other.blackBar == blackBar &&
      other.whiteOff == whiteOff &&
      other.blackOff == blackOff &&
      _listEquals(other._points);

  bool _listEquals(List<int> o) {
    for (var i = 0; i < _points.length; i++) {
      if (_points[i] != o[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(key(), whiteBar, blackBar, whiteOff, blackOff);
}
