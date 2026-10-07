import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/sound_controller.dart';
import '../../../core/localization/app_strings.dart';
import '../domain/ai/ai_engine.dart';
import '../domain/engine/move_search.dart';
import '../domain/engine/takhteh_game.dart';
import '../domain/models/dice_roll.dart';
import '../domain/models/game_config.dart';
import '../domain/models/game_result.dart';
import '../domain/models/player.dart';
import '../domain/models/position.dart';
import '../domain/models/single_move.dart';
import 'game_saver.dart';

/// Injectable timing profile so widget & controller tests run fast.
class GameTimings {
  const GameTimings({
    this.diceRollAnimation = const Duration(milliseconds: 780),
    this.openingRollAnimation = const Duration(milliseconds: 950),
    this.openingTiePause = const Duration(milliseconds: 2500),
    this.openingDecidedPause = const Duration(milliseconds: 3000),
    this.moveSpacing = const Duration(milliseconds: 430),
    this.afterMovePause = const Duration(milliseconds: 680),
    this.noMoveBanner = const Duration(milliseconds: 1250),
    this.turnBanner = const Duration(milliseconds: 850),
    this.bannerDuration = const Duration(milliseconds: 1600),
  });

  final Duration diceRollAnimation;
  final Duration openingRollAnimation;
  final Duration openingTiePause;
  final Duration openingDecidedPause;
  final Duration moveSpacing;
  final Duration afterMovePause;
  final Duration noMoveBanner;
  final Duration turnBanner;
  final Duration bannerDuration;

  /// Human-like AI thinking time per difficulty.
  Duration aiThinkTime(AiDifficulty difficulty, math.Random rng) {
    int minMs;
    int maxMs;
    switch (difficulty) {
      case AiDifficulty.easy:
        minMs = 800;
        maxMs = 1500;
      case AiDifficulty.medium:
        minMs = 600;
        maxMs = 1200;
      case AiDifficulty.hard:
        minMs = 400;
        maxMs = 900;
    }
    return Duration(milliseconds: minMs + rng.nextInt(maxMs - minMs + 1));
  }
}

/// Provider for timing knobs (overridden in tests).
final Provider<GameTimings> gameTimingsProvider =
    Provider<GameTimings>((ref) => const GameTimings());

/// Provider for the dice RNG (overridden in tests for determinism).
final Provider<math.Random> diceRandomProvider =
    Provider<math.Random>((ref) => math.Random());

/// Provider for the game persistence service.
final Provider<GameSaver> gameSaverProvider =
    Provider<GameSaver>((ref) => GameSaver());

/// A single user-visible action, consumed by the board widget to animate
/// checkers, dice and banners.
sealed class GameAction {
  const GameAction();
}

class GameStarted extends GameAction {
  const GameStarted();
}

class OpeningRolled extends GameAction {
  const OpeningRolled({
    required this.whiteDie,
    required this.blackDie,
    required this.outcome,
  });

  final int whiteDie;
  final int blackDie;
  final OpeningOutcome outcome;
}

class DiceRolled extends GameAction {
  const DiceRolled({required this.roll, required this.noMoves});

  final DiceRoll roll;
  final bool noMoves;
}

class MoveApplied extends GameAction {
  const MoveApplied({required this.move, required this.won});

  final SingleMove move;
  final bool won;
}

class MoveUndone extends GameAction {
  const MoveUndone({required this.move});

  final SingleMove move;
}

class TurnEndedAction extends GameAction {
  const TurnEndedAction({required this.nextPlayer});

  final Player nextPlayer;
}

class GameFinished extends GameAction {
  const GameFinished({required this.result});

  final GameResult result;
}

/// Running match score across consecutive games.
class MatchScore {
  const MatchScore({this.white = 0, this.black = 0});

  final int white;
  final int black;

  MatchScore add(Player player, int points) => player == Player.white
      ? MatchScore(white: white + points, black: black)
      : MatchScore(white: white, black: black + points);
}

/// View state consumed by the presentation layer.
class GameUiState {
  GameUiState({
    required this.config,
    required this.game,
    required this.score,
    required this.revision,
    this.lastAction,
    this.selectedFrom,
    this.diceRolling = false,
    this.aiThinking = false,
    this.openingRolling = false,
    this.openingResultPending = false,
    this.openingWhiteDie,
    this.openingBlackDie,
    this.banner,
    this.bannerRevision = 0,
    this.paused = false,
    this.manualFlip = false,
  });

  final GameConfig config;
  final TakhtehGame game;
  final MatchScore score;

  /// Bumped on every domain mutation so widgets can cheaply detect changes.
  final int revision;
  final GameAction? lastAction;

  /// Selected checker origin (point index or [kBarFrom]).
  final int? selectedFrom;

  /// Dice animation in progress.
  final bool diceRolling;

  /// AI turn in progress.
  final bool aiThinking;

  /// Opening roll animation in progress.
  final bool openingRolling;

  /// The latest opening result is being held on screen before the next roll.
  final bool openingResultPending;

  final int? openingWhiteDie;
  final int? openingBlackDie;

  /// Transient banner text (e.g. "no moves").
  final String? banner;
  final int bannerRevision;

  final bool paused;

  /// Session-local "flip the board for me" override.
  final bool manualFlip;

  GameUiState copyWith({
    GameConfig? config,
    TakhtehGame? game,
    MatchScore? score,
    int? revision,
    GameAction? lastAction,
    Object? selectedFrom = _sentinel,
    bool? diceRolling,
    bool? aiThinking,
    bool? openingRolling,
    bool? openingResultPending,
    Object? openingWhiteDie = _sentinel,
    Object? openingBlackDie = _sentinel,
    Object? banner = _sentinel,
    int? bannerRevision,
    bool? paused,
    bool? manualFlip,
  }) =>
      GameUiState(
        config: config ?? this.config,
        game: game ?? this.game,
        score: score ?? this.score,
        revision: revision ?? this.revision,
        lastAction: lastAction ?? this.lastAction,
        selectedFrom:
            selectedFrom == _sentinel ? this.selectedFrom : selectedFrom as int?,
        diceRolling: diceRolling ?? this.diceRolling,
        aiThinking: aiThinking ?? this.aiThinking,
        openingRolling: openingRolling ?? this.openingRolling,
        openingResultPending:
            openingResultPending ?? this.openingResultPending,
        openingWhiteDie: openingWhiteDie == _sentinel
            ? this.openingWhiteDie
            : openingWhiteDie as int?,
        openingBlackDie: openingBlackDie == _sentinel
            ? this.openingBlackDie
            : openingBlackDie as int?,
        banner: banner == _sentinel ? this.banner : banner as String?,
        bannerRevision: bannerRevision ?? this.bannerRevision,
        paused: paused ?? this.paused,
        manualFlip: manualFlip ?? this.manualFlip,
      );

  static const Object _sentinel = Object();

  // ---------------------------------------------------------------- helpers
  /// Whether the side on turn is controlled by the computer.
  bool get aiOnTurn =>
      config.isAi(currentSide) && game.phase != GamePhase.gameOver;

  PlayerSide get currentSide =>
      game.current == Player.white ? PlayerSide.white : PlayerSide.black;

  /// Legal moves of the current turn (empty outside the move phase).
  MoveSearchResult get legal => game.legalMoves;

  /// Destinations currently selectable for [selectedFrom].
  List<int> get destinations =>
      selectedFrom == null ? const <int>[] : legal.destinationsFrom(selectedFrom!);
}

/// Orchestrates the domain state machine: dice animations, human input,
/// AI turns, undo, banners, sounds and persistence.
///
/// All asynchronous continuations are guarded by an epoch counter so that
/// restarting or leaving a game immediately invalidates any in-flight AI
/// computation or scheduled transition — no races, no leaks.
class GameController extends Notifier<GameUiState> {
  int _epoch = 0;
  bool _aiBusy = false;
  late math.Random _rng;

  @override
  GameUiState build() {
    _rng = ref.watch(diceRandomProvider);
    ref.onDispose(_invalidateContinuations);
    // A neutral, not-started state; the game screen calls startGame first.
    final config = GameConfig(mode: GameMode.vsAi, difficulty: AiDifficulty.medium);
    return GameUiState(
      config: config,
      game: TakhtehGame(config: config),
      score: const MatchScore(),
      revision: 0,
    );
  }

  void _invalidateContinuations() => _epoch++;

  GameTimings get _timings => ref.read(gameTimingsProvider);
  SoundController get _sound => ref.read(soundControllerProvider);
  GameSaver get _saver => ref.read(gameSaverProvider);

  // ----------------------------------------------------------- lifecycle

  /// Starts a brand new game with [config]. [carryScore] keeps the match
  /// score across rematches.
  void startGame(GameConfig config, {MatchScore carryScore = const MatchScore()}) {
    _epoch++;
    _aiBusy = false;
    final game = TakhtehGame(config: config);
    state = GameUiState(
      config: config,
      game: game,
      score: carryScore,
      revision: 0,
      lastAction: const GameStarted(),
    );
    _persist();
  }

  /// Starts a rematch with the same configuration; scores carry over.
  void rematch() => startGame(state.config, carryScore: state.score);

  /// Restores a previously saved game (returns false when none exists).
  Future<bool> restoreSavedGame() async {
    final saved = await _saver.load();
    if (saved == null) return false;
    _epoch++;
    _aiBusy = false;
    state = GameUiState(
      config: saved.config,
      game: saved.game,
      score: MatchScore(white: saved.whiteScore, black: saved.blackScore),
      revision: 0,
      lastAction: const GameStarted(),
    );
    // Resume the flow (e.g. the AI was on turn).
    _fireAndForget(_maybeRunAi());
    return true;
  }

  /// Whether a saved game exists (for the "continue" button on home).
  Future<bool> hasSavedGame() async => await _saver.load() != null;

  // ------------------------------------------------------------- opening

  /// Rolls the opening dice (both players roll one die each). Ties are
  /// re-rolled automatically; the starter then rolls both dice again,
  /// exactly as in the traditional Iranian custom.
  Future<void> rollOpening() async {
    final game = state.game;
    if (game.phase != GamePhase.openingRoll ||
        state.openingRolling ||
        state.openingResultPending ||
        state.paused) {
      return;
    }
    final myEpoch = _epoch;
    state = state.copyWith(
      openingRolling: true,
      openingResultPending: false,
      openingWhiteDie: null,
      openingBlackDie: null,
    );

    await _sound.play(SoundEffect.diceRoll);
    await Future<void>.delayed(_timings.openingRollAnimation);
    if (_epoch != myEpoch) return;

    final whiteDie = _rng.nextInt(6) + 1;
    final blackDie = _rng.nextInt(6) + 1;
    final outcome = game.rollOpening(whiteDie, blackDie);
    state = state.copyWith(
      openingRolling: false,
      openingResultPending: true,
      openingWhiteDie: whiteDie,
      openingBlackDie: blackDie,
      revision: state.revision + 1,
      lastAction: OpeningRolled(
        whiteDie: whiteDie,
        blackDie: blackDie,
        outcome: outcome,
      ),
    );
    _persist();

    if (outcome == OpeningOutcome.tie) {
      _showBanner(AppStrings.openingTie);
      await Future<void>.delayed(_timings.openingTiePause);
      if (_epoch != myEpoch) return;
      state = state.copyWith(openingResultPending: false);
      await rollOpening();
      return;
    }

    // The starter now rolls both dice again (traditional Iranian style).
    await Future<void>.delayed(_timings.openingDecidedPause);
    if (_epoch != myEpoch) return;
    state = state.copyWith(openingResultPending: false);
    await rollDice(auto: true);
    if (_epoch != myEpoch) return;
    if (state.aiOnTurn && state.game.phase == GamePhase.awaitingMove) {
      _fireAndForget(_maybeRunAi());
    }
  }

  // ------------------------------------------------------------- rolling

  /// Rolls the dice for the current player. [auto] is used internally after
  /// the opening roll and by the AI; human players tap the dice themselves.
  Future<void> rollDice({bool auto = false}) async {
    final game = state.game;
    if (game.phase != GamePhase.awaitingRoll ||
        state.diceRolling ||
        state.paused ||
        (!auto && state.openingResultPending)) {
      return;
    }
    if (!auto && state.aiOnTurn) return; // The AI rolls its own dice.

    final myEpoch = _epoch;
    state = state.copyWith(
      diceRolling: true,
      openingResultPending: false,
      selectedFrom: null,
      banner: null,
    );

    await _sound.play(SoundEffect.diceRoll);
    await Future<void>.delayed(_timings.diceRollAnimation);
    if (_epoch != myEpoch || state.paused) {
      if (_epoch == myEpoch) {
        state = state.copyWith(diceRolling: false);
      }
      return;
    }

    final first = _rng.nextInt(6) + 1;
    final second = _rng.nextInt(6) + 1;
    final outcome = game.roll(first, second);
    state = state.copyWith(
      diceRolling: false,
      revision: state.revision + 1,
      lastAction: DiceRolled(roll: outcome.roll, noMoves: outcome.noMoves),
    );
    _persist();

    if (outcome.noMoves) {
      _showBanner(AppStrings.noMovesAvailable);
      await Future<void>.delayed(_timings.noMoveBanner);
      if (_epoch != myEpoch) return;
      if (game.phase == GamePhase.awaitingMove && game.turnExhausted) {
        _endTurn();
      }
    }
  }

  // --------------------------------------------------------------- input

  /// Selects (or deselects) a checker as the move origin.
  void selectChecker(int? from) {
    if (state.game.phase != GamePhase.awaitingMove || state.aiOnTurn) return;
    if (from != null && !state.legal.selectableFroms.contains(from)) return;
    state = state.copyWith(selectedFrom: from);
    if (from != null) _sound.play(SoundEffect.click);
  }

  /// Plays the legal one-or-more-die path the user tapped or dragged:
  /// [from] -> [to]. Illegal destinations simply do nothing.
  void playMove(int from, int to) {
    if (state.game.phase != GamePhase.awaitingMove || state.aiOnTurn) return;
    final path = state.legal.pathTo(from, to);
    if (path == null) return;
    for (final move in path) {
      if (state.game.phase != GamePhase.awaitingMove ||
          !state.legal.firstMoves.contains(move)) {
        return;
      }
      _applyMove(move);
    }
  }

  /// Undoes the last move of the current (human) turn.
  void undo() {
    final game = state.game;
    if (game.phase != GamePhase.awaitingMove ||
        state.aiOnTurn ||
        !game.canUndo) {
      return;
    }
    final undone = game.undoLastMove();
    if (undone == null) return;
    state = state.copyWith(
      revision: state.revision + 1,
      lastAction: MoveUndone(move: undone),
      selectedFrom: null,
    );
    _persist();
    _sound.play(SoundEffect.click);
  }

  // ---------------------------------------------------------- pause / view

  void setPaused(bool value) {
    if (state.paused == value) return;
    state = state.copyWith(paused: value);
    if (!value) {
      _fireAndForget(_maybeRunAi());
    }
  }

  void toggleManualFlip() {
    state = state.copyWith(manualFlip: !state.manualFlip);
    _sound.play(SoundEffect.click);
  }

  // ------------------------------------------------------------ internals

  void _applyMove(SingleMove move) {
    final game = state.game;
    if (game.phase != GamePhase.awaitingMove) return;
    final outcome = game.applyMove(move);
    state = state.copyWith(
      revision: state.revision + 1,
      lastAction: MoveApplied(move: move, won: outcome.won),
      selectedFrom: null,
    );

    if (outcome.won) {
      _finishGame();
      return;
    }

    // Distinct audible feedback for every kind of action.
    if (move.hits) {
      _sound.play(SoundEffect.pieceHit);
    } else if (move.bearsOff) {
      _sound.play(SoundEffect.bearOff);
    } else if (move.entersFromBar) {
      _sound.play(SoundEffect.reenter);
    } else {
      _sound.play(SoundEffect.pieceMove);
    }

    _persist();
    if (outcome.turnExhausted) {
      _scheduleTurnEnd();
    }
  }

  void _scheduleTurnEnd() {
    final myEpoch = _epoch;
    Future<void>(() async {
      await Future<void>.delayed(_timings.afterMovePause);
      if (_epoch != myEpoch || state.paused) return;
      final game = state.game;
      if (game.phase == GamePhase.awaitingMove && game.turnExhausted) {
        _endTurn();
      }
    });
  }

  void _endTurn() {
    final game = state.game;
    if (game.phase != GamePhase.awaitingMove) return;
    final next = game.current.opponent;
    game.endTurn();
    state = state.copyWith(
      revision: state.revision + 1,
      lastAction: TurnEndedAction(nextPlayer: next),
      selectedFrom: null,
      banner: null,
    );
    _sound.play(SoundEffect.turnChange);
    _persist();

    if (state.aiOnTurn) {
      _fireAndForget(_maybeRunAi(afterDelay: _timings.turnBanner));
    }
  }

  void _finishGame() {
    final game = state.game;
    final result = game.result;
    if (result == null) return;
    state = state.copyWith(
      score: state.score.add(result.winner, result.points),
      lastAction: GameFinished(result: result),
    );
    _saver.clear();

    final humanWon = !state.config.isAi(
      result.winner == Player.white ? PlayerSide.white : PlayerSide.black,
    );
    _sound.play(humanWon ? SoundEffect.win : SoundEffect.lose);
  }

  // -------------------------------------------------------------- AI flow

  /// Drives the computer's turn: rolls, thinks (off the UI isolate), and
  /// applies the chosen moves one by one with human-like pacing.
  Future<void> _maybeRunAi({Duration? afterDelay}) async {
    if (_aiBusy ||
        !state.aiOnTurn ||
        state.paused ||
        state.openingResultPending) {
      return;
    }
    final myEpoch = _epoch;
    bool active() => myEpoch == _epoch;
    _aiBusy = true;
    try {
      if (afterDelay != null) {
        await Future<void>.delayed(afterDelay);
        if (!active() || state.paused || !state.aiOnTurn) return;
      }

      var game = state.game;
      if (game.phase == GamePhase.awaitingRoll) {
        await Future<void>.delayed(
          _timings.aiThinkTime(state.config.difficulty, _rng) ~/ 2,
        );
        if (!active() || state.paused) return;
        await rollDice(auto: true);
        game = state.game;
        if (game.phase != GamePhase.awaitingMove || !state.aiOnTurn) return;
      } else if (game.phase != GamePhase.awaitingMove) {
        return;
      }

      state = state.copyWith(aiThinking: true);
      final think = _timings.aiThinkTime(state.config.difficulty, _rng);
      final stopwatch = Stopwatch()..start();

      // Heavy search runs in a background isolate so even hard difficulty
      // never freezes the interface.
      final request = _AiRequest(
        position: game.position,
        player: game.current,
        remainingDice: List<int>.from(game.remaining),
        frozenPoints: Set<int>.from(game.frozen),
        difficulty: state.config.difficulty,
        seed: _rng.nextInt(0x7FFFFFFF),
      );
      List<SingleMove> play;
      try {
        play = await Isolate.run(request.solve);
      } catch (_) {
        play = request.solve();
      }
      stopwatch.stop();

      // Keep the visible thinking time inside the human-like window.
      final remaining = think - stopwatch.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      if (!active() || state.paused) {
        state = state.copyWith(aiThinking: false);
        return;
      }
      state = state.copyWith(aiThinking: false);

      for (final move in play) {
        if (!active()) return;
        if (state.game.phase != GamePhase.awaitingMove) break;
        _applyMove(move);
        if (!active()) return;
        if (state.game.phase == GamePhase.awaitingMove &&
            !state.game.turnExhausted) {
          await Future<void>.delayed(_timings.moveSpacing);
        }
      }
      if (!active()) return;

      // Safety net: if the AI play could not be applied fully, end the turn.
      if (state.game.phase == GamePhase.awaitingMove &&
          state.game.turnExhausted) {
        await Future<void>.delayed(_timings.afterMovePause);
        if (!active() || state.paused) return;
        if (state.game.phase == GamePhase.awaitingMove &&
            state.game.turnExhausted) {
          _endTurn();
        }
      }
    } finally {
      _aiBusy = false;
    }
  }

  // ------------------------------------------------------------- banners

  void _showBanner(String text) {
    state = state.copyWith(
      banner: text,
      bannerRevision: state.bannerRevision + 1,
    );
    final myEpoch = _epoch;
    Future<void>(() async {
      await Future<void>.delayed(_timings.bannerDuration);
      if (_epoch != myEpoch) return;
      if (state.banner == text) {
        state = state.copyWith(banner: null);
      }
    });
  }

  // ---------------------------------------------------------- persistence

  Future<void> _persist() async {
    final game = state.game;
    if (game.phase == GamePhase.gameOver) {
      await _saver.clear();
      return;
    }
    await _saver.save(
      game: game,
      config: state.config,
      whiteScore: state.score.white,
      blackScore: state.score.black,
    );
  }
}

/// Plain data carrier sent to the background isolate.
class _AiRequest {
  _AiRequest({
    required this.position,
    required this.player,
    required this.remainingDice,
    required this.frozenPoints,
    required this.difficulty,
    required this.seed,
  });

  final Position position;
  final Player player;
  final List<int> remainingDice;
  final Set<int> frozenPoints;
  final AiDifficulty difficulty;
  final int seed;

  List<SingleMove> solve() => AiEngine.choosePlay(
        position: position,
        player: player,
        remainingDice: remainingDice,
        frozenPoints: frozenPoints,
        difficulty: difficulty,
        rng: math.Random(seed),
      );
}

final NotifierProvider<GameController, GameUiState> gameControllerProvider =
    NotifierProvider<GameController, GameUiState>(GameController.new);

/// Fire-and-forget helper (keeps call sites clean without dangling lint).
void _fireAndForget(Future<void> future) {
  future.catchError((Object _) {});
}
