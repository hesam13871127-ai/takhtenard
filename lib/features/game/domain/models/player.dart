/// The two sides of a Takhteh Nard game.
///
/// Conventions used across the whole engine:
/// * Points are numbered `1..24` in absolute coordinates.
/// * [Player.white] moves from point 24 towards point 1 (counter-clockwise)
///   and bears off from points `1..6` (its home board).
/// * [Player.black] moves from point 1 towards point 24 (clockwise) and bears
///   off from points `19..24` (its home board).
///
/// The initial position therefore matches the traditional layout:
/// white: 2 on 24, 5 on 13, 3 on 8, 5 on 6 — black mirrored on 1, 12, 17, 19.
enum Player {
  white,
  black;

  /// The opposing player.
  Player get opponent => this == Player.white ? Player.black : Player.white;

  /// Lowest point index of this player's home board.
  int get homeLow => this == Player.white ? 1 : 19;

  /// Highest point index of this player's home board.
  int get homeHigh => this == Player.white ? 6 : 24;

  /// Whether [point] lies inside this player's home board.
  bool isOwnHome(int point) => point >= homeLow && point <= homeHigh;

  /// Direction of travel expressed as a point delta per pip.
  ///
  /// White decreases the point index, black increases it.
  int get travelDelta => this == Player.white ? -1 : 1;

  /// Absolute point where this player re-enters from the bar with [die].
  ///
  /// Entry always lands inside the *opponent's* home board, which in absolute
  /// coordinates is `25 - die` seen from the entering player's own numbering.
  int entryPoint(int die) => this == Player.white ? 25 - die : die;

  /// Persian display name of the checker color.
  String get persianName => this == Player.white ? 'سفید' : 'مشکی';
}
