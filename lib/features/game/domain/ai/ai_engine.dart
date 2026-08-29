import 'dart:math' as math;

import '../models/game_config.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../models/single_move.dart';
import '../engine/move_search.dart';
import 'evaluation.dart';

/// A complete AI turn: the sequence of moves chosen for the current dice.
class AiPlay {
  const AiPlay({required this.moves});

  /// The chosen moves in order; empty when nothing can be played.
  final List<SingleMove> moves;

  bool get isEmpty => moves.isEmpty;
}

/// The Takhteh Nard AI.
///
/// Difficulty profiles:
///  * [AiDifficulty.easy]   — picks uniformly at random among maximal legal
///    sequences, with a 30% chance of deliberately choosing a weak sequence.
///  * [AiDifficulty.medium] — heuristic evaluation (hits, primes, blot
///    safety with approximate shot risk) with a temperature so it stays
///    human and beatable.
///  * [AiDifficulty.hard]   — full evaluation with exact 36-roll shot risk,
///    race awareness and bear-off efficiency; plays near-perfect tactics.
///
/// Every returned sequence is legal and uses the maximum number of dice —
/// the AI can never break the rules or waste dice.
abstract final class AiEngine {
  /// Chooses the full move sequence for the current turn.
  static List<SingleMove> choosePlay({
    required Position position,
    required Player player,
    required List<int> remainingDice,
    required Set<int> frozenPoints,
    required AiDifficulty difficulty,
    required math.Random rng,
  }) {
    final search = MoveSearch.search(
      position: position,
      player: player,
      remainingDice: remainingDice,
      frozenPoints: frozenPoints,
    );
    if (!search.hasMoves) return const <SingleMove>[];
    final sequences = search.sequences;
    if (sequences.isEmpty) return const <SingleMove>[];

    // Deduplicate by resulting position: different move orders often reach
    // the same outcome, and evaluating each outcome once keeps the AI fast.
    final outcomes = <_Outcome>[];
    final seen = <String>{};
    for (final sequence in sequences) {
      var pos = position;
      for (final move in sequence) {
        pos = pos.applyMove(move);
      }
      final key = '${pos.key()}#${pos.whiteOff}/${pos.blackOff}';
      if (!seen.add(key)) continue;
      outcomes.add(_Outcome(sequence, pos));
    }

    switch (difficulty) {
      case AiDifficulty.easy:
        return _chooseEasy(outcomes, position, player, rng);
      case AiDifficulty.medium:
        return _chooseMedium(outcomes, position, player, rng);
      case AiDifficulty.hard:
        return _chooseHard(outcomes, position, player, rng);
    }
  }

  // ---------------------------------------------------------------------
  // Easy: random play with occasional deliberate weakness.
  // ---------------------------------------------------------------------
  static List<SingleMove> _chooseEasy(
    List<_Outcome> outcomes,
    Position position,
    Player player,
    math.Random rng,
  ) {
    // ~30% of turns: deliberately pick among the weakest outcomes.
    if (rng.nextDouble() < 0.30 && outcomes.length > 1) {
      final scored = outcomes
          .map((o) => (o, Evaluation.evaluate(o.position, player)))
          .toList()
        ..sort((a, b) => a.$2.compareTo(b.$2));
      final weakRange = math.max(1, scored.length * 3 ~/ 10);
      final pick = scored[rng.nextInt(weakRange)].$1;
      return pick.sequence;
    }
    return outcomes[rng.nextInt(outcomes.length)].sequence;
  }

  // ---------------------------------------------------------------------
  // Medium: heuristic evaluation with a temperature over the top choices.
  // ---------------------------------------------------------------------
  static List<SingleMove> _chooseMedium(
    List<_Outcome> outcomes,
    Position position,
    Player player,
    math.Random rng,
  ) {
    final scored = outcomes
        .map((o) => (o, Evaluation.evaluate(o.position, player)))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return _pickWithTemperature(
      scored,
      <double>[0.66, 0.22, 0.12],
      rng,
    );
  }

  // ---------------------------------------------------------------------
  // Hard: exact evaluation, almost always the best move.
  // ---------------------------------------------------------------------
  static List<SingleMove> _chooseHard(
    List<_Outcome> outcomes,
    Position position,
    Player player,
    math.Random rng,
  ) {
    final scored = outcomes
        .map(
          (o) => (
            o,
            Evaluation.evaluate(o.position, player, exactRisk: true) +
                rng.nextDouble() * 0.6, // tiny human-like imprecision
          ),
        )
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    // If the second best is nearly as good, occasionally vary the choice so
    // games do not feel mechanical.
    if (scored.length > 1) {
      final best = scored.first;
      final second = scored[1];
      if (second.$2 >= best.$2 - 0.35 && rng.nextDouble() < 0.22) {
        return second.$1.sequence;
      }
    }
    return scored.first.$1.sequence;
  }

  /// Picks one of the first [weights].length entries according to
  /// [weights]; the remainder of the probability mass goes to the best.
  static List<SingleMove> _pickWithTemperature(
    List<(_Outcome, double)> scored,
    List<double> weights,
    math.Random rng,
  ) {
    final n = math.min(weights.length, scored.length);
    if (n == 0) return const <SingleMove>[];
    var totalWeight = 0.0;
    for (var i = 0; i < n; i++) {
      totalWeight += weights[i];
    }
    var roll = rng.nextDouble() * totalWeight;
    for (var i = 0; i < n; i++) {
      roll -= weights[i];
      if (roll <= 0) return scored[i].$1.sequence;
    }
    return scored.first.$1.sequence;
  }
}

/// A candidate move sequence together with the position it leads to.
class _Outcome {
  const _Outcome(this.sequence, this.position);

  final List<SingleMove> sequence;
  final Position position;
}
