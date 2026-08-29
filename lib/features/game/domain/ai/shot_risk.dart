import 'dart:math' as math;

import '../models/player.dart';
import '../models/position.dart';
import '../models/single_move.dart';
import '../engine/rules.dart';

/// Hit-risk calculations used by the AI to judge blots.
///
/// [hitProbability] is exact: it enumerates all 36 rolls and checks, for
/// each roll, whether the attacker has *some* legal sequence that lands on
/// the blot (respecting blocked points and bar entries).
///
/// [approximateHitProbability] is a cheap classical approximation that only
/// counts direct shots (distance 1..6) — good enough for the medium AI.
abstract final class ShotRisk {
  /// Exact probability that [attacker] (the player to move) can hit the
  /// blot standing on [blotPoint].
  static double hitProbability(
    Position position,
    Player attacker,
    int blotPoint,
  ) {
    var hittingRolls = 0;

    // 21 distinct rolls; doubles occur once out of 36, mixed rolls twice.
    for (var d1 = 1; d1 <= 6; d1++) {
      for (var d2 = d1; d2 <= 6; d2++) {
        final weight = d1 == d2 ? 1 : 2;
        final dice =
            d1 == d2 ? <int>[d1, d1, d1, d1] : <int>[d1, d2];
        if (_canHit(position, attacker, dice, blotPoint, <String, bool>{})) {
          hittingRolls += weight;
        }
      }
    }
    return hittingRolls / 36.0;
  }

  /// Whether [attacker] can, with the given [dice], land on [blotPoint]
  /// with some legal sequence of moves (memoized DFS with early exit).
  static bool _canHit(
    Position position,
    Player attacker,
    List<int> dice,
    int blotPoint,
    Map<String, bool> memo,
  ) {
    if (dice.isEmpty) return false;
    final key = '${position.key()}#${_sorted(dice)}';
    final cached = memo[key];
    if (cached != null) return cached;

    var result = false;
    final usedDies = <int>{};
    for (final die in dice) {
      if (!usedDies.add(die)) continue;
      final moves = Rules.legalMovesForDie(position, attacker, die);
      for (final move in moves) {
        if (move.to == blotPoint && move.hits) {
          result = true;
          break;
        }
        // Only follow moves that could be part of a minimal hitting
        // sequence: entering from the bar or strictly approaching the
        // blot. (Any hitting sequence can be reduced to such moves: a
        // checker that has already passed the blot can never hit it, and
        // moves away from it never enable one.)
        if (!_approaches(move, blotPoint, attacker)) continue;
        final rest = List<int>.from(dice)..remove(die);
        if (_canHit(
          position.applyMove(move),
          attacker,
          rest,
          blotPoint,
          memo,
        )) {
          result = true;
          break;
        }
      }
      if (result) break;
    }

    memo[key] = result;
    return result;
  }

  /// Whether [move] enters from the bar or brings a checker strictly closer
  /// to [target] along the attacker's direction of travel.
  static bool _approaches(SingleMove move, int target, Player attacker) {
    if (move.bearsOff) return false;
    if (move.entersFromBar) return true;
    final delta = attacker.travelDelta;
    final fromDist = (target - move.from) * delta;
    final toDist = (target - move.to) * delta;
    if (fromDist <= 0) return false; // Already passed the blot.
    return toDist < fromDist;
  }

  static String _sorted(List<int> dice) {
    final copy = List<int>.from(dice)..sort();
    return copy.join(',');
  }

  /// Cheap approximation: union of direct shots (one die, distance 1..6).
  /// Uses the classical formula `36 - (6 - |dies|)^2` for the number of
  /// rolls containing at least one of the threatening die values, plus a
  /// rough pair-based estimate when the attacker must come in from the bar.
  static double approximateHitProbability(
    Position position,
    Player attacker,
    int blotPoint,
  ) {
    final dies = <int>{};
    for (var p = 1; p <= 24; p++) {
      if (position.countFor(attacker, p) == 0) continue;
      final dist = (blotPoint - p) * attacker.travelDelta;
      if (dist >= 1 && dist <= 6) dies.add(dist);
    }

    var rolls = dies.isEmpty ? 0 : 36 - (6 - dies.length) * (6 - dies.length);

    // Attackers entering from the bar need an entry die plus a hit die.
    if (position.barCount(attacker) > 0) {
      var bestExtra = 0;
      for (var entry = 1; entry <= 6; entry++) {
        final entryPoint = attacker.entryPoint(entry);
        if (position.isClosedFor(attacker, entryPoint)) continue;
        final dist = (blotPoint - entryPoint) * attacker.travelDelta;
        if (dist < 1 || dist > 6) continue;
        // Rolls containing both `entry` and `dist`:
        bestExtra = entry == dist ? 1 : 2;
        break;
      }
      rolls += bestExtra;
    }

    return math.min(rolls, 36) / 36.0;
  }
}
