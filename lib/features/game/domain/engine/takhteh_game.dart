import '../models/dice_roll.dart';
import '../models/game_config.dart';
import '../models/game_result.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../models/single_move.dart';
import 'move_search.dart';

/// Coarse phases of a game. Animation-only states (dice spinning, pieces
/// gliding, banners) live in the presentation layer; the domain only tracks
/// what is legally allowed to happen next.
enum GamePhase {
  /// Waiting for the opening roll that decides who starts.
  openingRoll,

  /// The current player must roll both dice.
  awaitingRoll,

  /// Dice have been rolled; the current player is (still) moving.
  awaitingMove,

  /// The game is over and [TakhtehGame.result] is set.
  gameOver,
}

/// Outcome of the opening roll.
enum OpeningOutcome {
  /// Both players rolled the same value; they must roll again.
  tie,

  /// A starter was determined; they now roll both dice for their first turn
  /// (traditional Iranian style).
  decided,
}

/// Outcome of rolling the dice for a turn.
class RollOutcome {
  const RollOutcome({required this.roll, required this.noMoves});

  final DiceRoll roll;

  /// Whether not a single die can be played; the turn must be passed.
  final bool noMoves;
}

/// Outcome of applying a single move.
class MoveOutcome {
  const MoveOutcome({
    required this.move,
    required this.hit,
    required this.diceRemaining,
    required this.turnExhausted,
    required this.won,
  });

  final SingleMove move;
  final bool hit;

  /// How many dice values remain after this move.
  final int diceRemaining;

  /// Whether no further dice can be played (turn must be passed).
  final bool turnExhausted;

  /// Whether this move won the game.
  final bool won;
}

/// Internal snapshot used for undo (last move of the current turn only).
class _TurnSnapshot {
  const _TurnSnapshot({
    required this.position,
    required this.remaining,
    required this.frozen,
  });

  final Position position;
  final List<int> remaining;
  final Set<int> frozen;
}

/// The complete, pure-Dart state machine of a Takhteh Nard game.
///
/// It enforces every rule of the traditional Iranian variant:
///  * Iranian opening: one die each, higher starts and then rolls both dice;
///  * doubles give four moves;
///  * mandatory maximum dice usage (and the higher-die rule);
///  * hits, bar re-entry, bearing off;
///  * the "no hit-and-run inside your own home board" restriction, lifted
///    only when dice would otherwise be wasted;
///  * win detection with traditional scoring (normal = 1, mars = 2).
///
/// The class is deliberately independent of Flutter so it can be unit tested
/// headlessly and executed inside a background isolate for the AI.
class TakhtehGame {
  /// Starts a new game from the traditional initial position.
  ///
  /// The optional parameters exist for tests and for restoring a saved
  /// game; production code uses [TakhtehGame.new] without them.
  TakhtehGame({
    required this.config,
    Position? initialPosition,
    Player startingPlayer = Player.white,
    this.phase = GamePhase.openingRoll,
  })  : position = initialPosition ?? Position.initial(),
        current = startingPlayer;

  /// Configuration of this session (mode, difficulty, names).
  final GameConfig config;

  /// Current checker arrangement.
  Position position;

  /// Player whose turn it is (set once the opening roll is decided).
  Player current;

  /// Phase of the game.
  GamePhase phase;

  /// Dice rolled for the current turn (null before rolling).
  DiceRoll? dice;

  /// Die values still available this turn.
  List<int> remaining = <int>[];

  /// Points where a hit inside the player's own home board pinned the
  /// hitting checker for the rest of this turn.
  Set<int> frozen = <int>{};

  /// Values of the last opening roll (for the UI).
  int openingWhiteDie = 0;
  int openingBlackDie = 0;

  /// Moves already played in the current turn.
  final List<SingleMove> movesPlayedThisTurn = <SingleMove>[];

  /// Result once the game is over.
  GameResult? result;

  /// Snapshots for undoing the last move of the current turn.
  final List<_TurnSnapshot> _undoStack = <_TurnSnapshot>[];

  /// Lazily computed and cached move search for the current state; bumped
  /// whenever the state changes.
  MoveSearchResult? _cachedSearch;
  int _revision = 0;

  /// Monotonic counter; lets the UI detect any state change cheaply.
  int get revision => _revision;

  /// Legal moves for the current state (cached until the state changes).
  MoveSearchResult get legalMoves {
    if (phase != GamePhase.awaitingMove) {
      return const MoveSearchResult(
        maxUsableDice: 0,
        firstMoves: [],
        sequences: [],
        freezesLifted: false,
      );
    }
    return _cachedSearch ??= MoveSearch.search(
      position: position,
      player: current,
      remainingDice: remaining,
      frozenPoints: frozen,
    );
  }

  /// Whether the current player cannot play any die right now.
  bool get turnExhausted =>
      phase == GamePhase.awaitingMove && !legalMoves.hasMoves;

  /// Whether undo is currently possible (last move of this turn).
  bool get canUndo =>
      phase == GamePhase.awaitingMove && _undoStack.isNotEmpty;

  /// Performs the opening roll with explicit die values.
  OpeningOutcome rollOpening(int whiteDie, int blackDie) {
    if (phase != GamePhase.openingRoll) {
      throw StateError('rollOpening called outside the opening phase');
    }
    openingWhiteDie = whiteDie;
    openingBlackDie = blackDie;
    _revision++;
    if (whiteDie == blackDie) return OpeningOutcome.tie;
    current = whiteDie > blackDie ? Player.white : Player.black;
    phase = GamePhase.awaitingRoll;
    return OpeningOutcome.decided;
  }

  /// Rolls both dice (explicit values) for the current player's turn.
  RollOutcome roll(int first, int second) {
    if (phase != GamePhase.awaitingRoll) {
      throw StateError('roll called outside the awaitingRoll phase');
    }
    final roll = DiceRoll(first, second);
    dice = roll;
    remaining = List<int>.from(roll.moves);
    frozen = <int>{};
    movesPlayedThisTurn.clear();
    _undoStack.clear();
    phase = GamePhase.awaitingMove;
    _cachedSearch = null;
    _revision++;
    return RollOutcome(roll: roll, noMoves: !legalMoves.hasMoves);
  }

  /// Applies a legal move (must be part of [legalMoves.firstMoves]).
  MoveOutcome applyMove(SingleMove move) {
    if (phase != GamePhase.awaitingMove) {
      throw StateError('applyMove called outside the awaitingMove phase');
    }
    if (!legalMoves.firstMoves.contains(move)) {
      throw StateError('Illegal move attempted: $move');
    }

    _undoStack.add(
      _TurnSnapshot(
        position: position,
        remaining: List<int>.from(remaining),
        frozen: Set<int>.from(frozen),
      ),
    );

    position = position.applyMove(move);
    remaining = _removeDie(remaining, move.die);
    movesPlayedThisTurn.add(move);

    // Traditional Iranian restriction: a hit inside the player's own home
    // board pins the hitting checker until the end of the turn.
    if (move.hits && current.isOwnHome(move.to)) {
      frozen.add(move.to);
    }

    _cachedSearch = null;
    _revision++;

    if (position.offCount(current) == 15) {
      final loser = current.opponent;
      final loserOff = position.offCount(loser);
      final winType = loserOff == 0 ? WinType.gammon : WinType.normal;
      result = GameResult(
        winner: current,
        winType: winType,
        points: winType.points,
        loserOffCount: loserOff,
      );
      phase = GamePhase.gameOver;
      return MoveOutcome(
        move: move,
        hit: move.hits,
        diceRemaining: 0,
        turnExhausted: false,
        won: true,
      );
    }

    final exhausted = !legalMoves.hasMoves;
    return MoveOutcome(
      move: move,
      hit: move.hits,
      diceRemaining: remaining.length,
      turnExhausted: exhausted,
      won: false,
    );
  }

  /// Applies a move by origin and destination, resolving the concrete die.
  /// Returns `null` when the pair is not playable right now.
  MoveOutcome? applyFromTo(int from, int to) {
    final move = legalMoves.resolve(from, to);
    if (move == null) return null;
    return applyMove(move);
  }

  /// Undoes the last move of the current turn. Returns the undone move or
  /// `null` when nothing can be undone.
  SingleMove? undoLastMove() {
    if (!canUndo) return null;
    final snapshot = _undoStack.removeLast();
    position = snapshot.position;
    remaining = List<int>.from(snapshot.remaining);
    frozen = Set<int>.from(snapshot.frozen);
    _cachedSearch = null;
    _revision++;
    return movesPlayedThisTurn.removeLast();
  }

  /// Ends the current turn and passes to the opponent.
  void endTurn() {
    if (phase != GamePhase.awaitingMove) {
      throw StateError('endTurn called outside the awaitingMove phase');
    }
    current = current.opponent;
    phase = GamePhase.awaitingRoll;
    dice = null;
    remaining = <int>[];
    frozen = <int>{};
    movesPlayedThisTurn.clear();
    _undoStack.clear();
    _cachedSearch = null;
    _revision++;
  }

  /// Pip count of both players (for the UI scoreboard).
  ({int white, int black}) get pipCounts => (
        white: position.pipCount(Player.white),
        black: position.pipCount(Player.black),
      );

  List<int> _removeDie(List<int> dice, int die) {
    final rest = List<int>.from(dice);
    rest.remove(die);
    return rest;
  }

  // ------------------------------------------------------------------
  // Serialization (used for the offline "continue game" feature).
  // ------------------------------------------------------------------

  Map<String, Object?> toJson() => <String, Object?>{
        'phase': phase.name,
        'position': position.toJson(),
        'current': current.name,
        'dice': dice == null ? null : [dice!.first, dice!.second],
        'remaining': List<int>.from(remaining),
        'frozen': frozen.toList(),
        'openingWhiteDie': openingWhiteDie,
        'openingBlackDie': openingBlackDie,
        'movesPlayed': movesPlayedThisTurn
            .map((m) => {
                  'player': m.player.name,
                  'from': m.from,
                  'to': m.to,
                  'die': m.die,
                  'hits': m.hits,
                })
            .toList(),
        'result': result == null
            ? null
            : {
                'winner': result!.winner.name,
                'winType': result!.winType.name,
                'points': result!.points,
                'loserOffCount': result!.loserOffCount,
              },
      };

  factory TakhtehGame.fromJson(Map<String, Object?> json, GameConfig config) {
    final game = TakhtehGame(config: config)
      ..position = Position.fromJson(
        (json['position']! as Map<String, Object?>).cast<String, Object?>(),
      )
      ..phase = GamePhase.values.firstWhere((p) => p.name == json['phase'])
      ..current = Player.values.firstWhere((p) => p.name == json['current'])
      ..openingWhiteDie = json['openingWhiteDie']! as int
      ..openingBlackDie = json['openingBlackDie']! as int;

    final diceJson = json['dice'];
    if (diceJson != null) {
      final pair = (diceJson as List).cast<int>();
      game.dice = DiceRoll(pair[0], pair[1]);
    }
    game.remaining = (json['remaining']! as List).cast<int>().toList();
    game.frozen = (json['frozen']! as List).cast<int>().toSet();
    for (final m in (json['movesPlayed']! as List)) {
      final map = (m as Map).cast<String, Object?>();
      game.movesPlayedThisTurn.add(SingleMove(
        player: Player.values.firstWhere((p) => p.name == map['player']),
        from: map['from']! as int,
        to: map['to']! as int,
        die: map['die']! as int,
        hits: map['hits']! as bool,
      ));
    }
    final resultJson = json['result'];
    if (resultJson != null) {
      final map = (resultJson as Map).cast<String, Object?>();
      game.result = GameResult(
        winner: Player.values.firstWhere((p) => p.name == map['winner']),
        winType: WinType.values.firstWhere((t) => t.name == map['winType']),
        points: map['points']! as int,
        loserOffCount: map['loserOffCount']! as int,
      );
    }
    return game;
  }
}
