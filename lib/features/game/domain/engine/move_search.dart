import '../models/player.dart';
import '../models/position.dart';
import '../models/single_move.dart';
import 'rules.dart';

/// Hard cap on how many maximal sequences are collected for the AI. Typical
/// turns produce far fewer; the cap only protects pathological positions.
const int kMaxSequences = 512;

/// Result of searching all move sequences for the remaining dice.
class MoveSearchResult {
  const MoveSearchResult({
    required this.maxUsableDice,
    required this.firstMoves,
    required this.sequences,
    required this.freezesLifted,
  });

  /// The maximum number of dice that can legally be played.
  final int maxUsableDice;

  /// Every legal single move that can start a maximal sequence. Playing any
  /// of these moves guarantees the remaining dice can still be used to the
  /// same maximum — this is what makes illegal (dice-wasting) moves
  /// impossible in the UI.
  final List<SingleMove> firstMoves;

  /// A capped sample of full maximal sequences (for the AI).
  final List<List<SingleMove>> sequences;

  /// Whether the traditional "no hit-and-run inside the home board"
  /// restriction had to be lifted for this roll because honoring it would
  /// waste dice ("khal-soozi").
  final bool freezesLifted;

  /// All distinct origin locations that have at least one legal move.
  List<int> get selectableFroms {
    final froms = <int>{};
    for (final m in firstMoves) {
      froms.add(m.from);
    }
    return froms.toList()..sort();
  }

  /// All legal destinations from [from] (deduplicated; may include
  /// [kBearOffTo]).
  List<int> destinationsFrom(int from) {
    final dests = <int>{};
    for (final m in firstMoves) {
      if (m.from == from) dests.add(m.to);
    }
    return dests.toList()..sort();
  }

  /// Resolves a concrete move for a tap/drag from [from] to [to], or `null`
  /// when that pair is not playable right now.
  SingleMove? resolve(int from, int to) {
    for (final m in firstMoves) {
      if (m.from == from && m.to == to) return m;
    }
    return null;
  }

  bool get hasMoves => maxUsableDice > 0 && firstMoves.isNotEmpty;
}

/// Exhaustive, memoized search over move sequences.
///
/// Enforces:
///  * maximum dice usage (a player must play as many dice as possible),
///  * the higher-die rule (when only one of two distinct dice can be played,
///    the higher one must be used),
///  * the traditional Iranian "no hit-and-run in the home board" restriction
///    (lifted only when honoring it would waste dice).
abstract final class MoveSearch {
  static MoveSearchResult search({
    required Position position,
    required Player player,
    required List<int> remainingDice,
    Set<int> frozenPoints = const <int>{},
  }) {
    if (remainingDice.isEmpty) {
      return const MoveSearchResult(
        maxUsableDice: 0,
        firstMoves: [],
        sequences: [],
        freezesLifted: false,
      );
    }

    final memo = <String, int>{};
    final honored = _maxDepth(
      position,
      player,
      remainingDice,
      frozenPoints,
      true,
      memo,
    );
    var freezesLifted = false;
    var maxUsable = honored;
    if (frozenPoints.isNotEmpty) {
      final relaxed = _maxDepth(
        position,
        player,
        remainingDice,
        frozenPoints,
        false,
        memo,
      );
      if (relaxed > honored) {
        // Honoring the freeze would waste dice: the restriction is lifted
        // ("khal-soozi" avoidance takes priority).
        maxUsable = relaxed;
        freezesLifted = true;
      }
    }

    if (maxUsable == 0) {
      return MoveSearchResult(
        maxUsableDice: 0,
        firstMoves: const [],
        sequences: const [],
        freezesLifted: freezesLifted,
      );
    }

    final honorFreezes = !freezesLifted;
    final effectiveFrozen =
        honorFreezes ? Set<int>.from(frozenPoints) : const <int>{};

    // Collect all maximal sequences (capped) plus the set of first moves
    // that can still reach the maximum.
    final sequences = <List<SingleMove>>[];
    final firstMoves = <SingleMove>{};
    _collect(
      position,
      player,
      remainingDice,
      effectiveFrozen,
      honorFreezes,
      maxUsable,
      <SingleMove>[],
      sequences,
      firstMoves,
      memo,
    );

    var resultMoves = firstMoves.toList();

    // Higher-die rule: with two distinct dice remaining where only a single
    // die can be played in total, the higher number must be used.
    if (maxUsable == 1 &&
        remainingDice.length == 2 &&
        remainingDice[0] != remainingDice[1]) {
      final lower = remainingDice[0] < remainingDice[1]
          ? remainingDice[0]
          : remainingDice[1];
      final hasLower = resultMoves.any((m) => m.die == lower);
      final hasHigher = resultMoves.any((m) => m.die != lower);
      if (hasLower && hasHigher) {
        resultMoves = resultMoves.where((m) => m.die != lower).toList();
        sequences.removeWhere((s) => s.first.die == lower);
      }
    }

    return MoveSearchResult(
      maxUsableDice: maxUsable,
      firstMoves: resultMoves,
      sequences: sequences,
      freezesLifted: freezesLifted,
    );
  }

  /// Maximum number of dice playable from this state (memoized DFS).
  static int _maxDepth(
    Position position,
    Player player,
    List<int> dice,
    Set<int> frozen,
    bool honorFreezes,
    Map<String, int> memo,
  ) {
    if (dice.isEmpty) return 0;

    final key = _memoKey(position, dice, frozen, honorFreezes);
    final cached = memo[key];
    if (cached != null) return cached;

    var best = 0;
    final usedDies = <int>{};
    for (final die in dice) {
      if (!usedDies.add(die)) continue;
      final moves = Rules.legalMovesForDie(
        position,
        player,
        die,
        frozenPoints: frozen,
        honorFreezes: honorFreezes,
      );
      for (final move in moves) {
        final rest = _withoutOne(dice, die);
        final next = position.applyMove(move);
        final nextFrozen = _freezeAfter(player, move, frozen, honorFreezes);
        final depth =
            1 + _maxDepth(next, player, rest, nextFrozen, honorFreezes, memo);
        if (depth > best) best = depth;
        if (best == dice.length) break; // Cannot do better.
      }
      if (best == dice.length) break;
    }

    memo[key] = best;
    return best;
  }

  /// DFS that collects maximal sequences and the first moves that lead to
  /// them. [memo] is shared with [_maxDepth]; since its entries store the
  /// exact maximum depth of a state, the reachability check below is exact.

  static void _collect(
    Position position,
    Player player,
    List<int> dice,
    Set<int> frozen,
    bool honorFreezes,
    int target,
    List<SingleMove> path,
    List<List<SingleMove>> sequences,
    Set<SingleMove> firstMoves,
    Map<String, int> memo,
  ) {
    if (path.length == target) {
      if (sequences.length < kMaxSequences) {
        sequences.add(List<SingleMove>.from(path));
      }
      if (path.isNotEmpty) firstMoves.add(path.first);
      return;
    }
    if (dice.isEmpty) return;

    final usedDies = <int>{};
    for (final die in dice) {
      if (!usedDies.add(die)) continue;
      final moves = Rules.legalMovesForDie(
        position,
        player,
        die,
        frozenPoints: frozen,
        honorFreezes: honorFreezes,
      );
      for (final move in moves) {
        final rest = _withoutOne(dice, die);
        final next = position.applyMove(move);
        final nextFrozen = _freezeAfter(player, move, frozen, honorFreezes);
        final reachable =
            1 + _maxDepth(next, player, rest, nextFrozen, honorFreezes, memo);
        if (reachable != target - path.length) continue;
        path.add(move);
        _collect(
          next,
          player,
          rest,
          nextFrozen,
          honorFreezes,
          target,
          path,
          sequences,
          firstMoves,
          memo,
        );
        path.removeLast();
      }
    }
  }

  /// Updates the frozen set after [move]: landing a hit inside the player's
  /// own home board pins the hitting checker for the rest of the turn.
  static Set<int> _freezeAfter(
    Player player,
    SingleMove move,
    Set<int> frozen,
    bool honorFreezes,
  ) {
    if (!honorFreezes) return frozen;
    if (move.hits && player.isOwnHome(move.to)) {
      if (frozen.contains(move.to)) return frozen;
      return {...frozen, move.to};
    }
    return frozen;
  }

  /// Removes a single occurrence of [die] from [dice].
  static List<int> _withoutOne(List<int> dice, int die) {
    final rest = List<int>.from(dice);
    rest.remove(die);
    return rest;
  }

  static String _memoKey(
    Position position,
    List<int> dice,
    Set<int> frozen,
    bool honorFreezes,
  ) {
    final sortedDice = List<int>.from(dice)..sort();
    final frozenKey = (frozen.toList()..sort()).join('|');
    return '${position.key()}#${sortedDice.join(',')}#$frozenKey#$honorFreezes';
  }
}
