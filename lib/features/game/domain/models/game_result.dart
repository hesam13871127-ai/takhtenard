import 'player.dart';

/// How a finished game was won, following traditional Iranian scoring:
/// a normal win scores 1 point and a "mars" (gammon — the loser has not
/// borne off a single checker) scores 2 points. There is no separate
/// backgammon (mars-e kabir) score in the traditional rules; every such
/// win is counted as a mars.
enum WinType { normal, gammon }

extension WinTypeLabel on WinType {
  String get persianName => this == WinType.normal ? 'برد ساده' : 'مارس';

  int get points => this == WinType.normal ? 1 : 2;
}

/// Outcome of a finished game.
class GameResult {
  const GameResult({
    required this.winner,
    required this.winType,
    required this.points,
    required this.loserOffCount,
  });

  final Player winner;
  final WinType winType;
  final int points;
  final int loserOffCount;
}
