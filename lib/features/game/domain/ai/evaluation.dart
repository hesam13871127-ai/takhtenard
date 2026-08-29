import '../models/player.dart';
import '../models/position.dart';
import '../engine/rules.dart';
import 'shot_risk.dart';

/// Static position evaluation from a single player's perspective.
///
/// The evaluator deliberately blends race, structure (primes, made points,
/// anchors) and safety (blot risk) so that the different AI difficulty
/// levels can simply use different subsets and risk models:
///  * medium — approximate shot risk, reduced structural terms;
///  * hard   — exact shot risk (all 36 rolls), full structural terms.
abstract final class Evaluation {
  // ---------------------- tuning weights (hard AI) ----------------------
  static const double _wPipContact = 0.42;
  static const double _wPipRace = 1.0;
  static const double _wMyOff = 18;
  static const double _wOppOff = -14;
  static const double _wMyBar = -14;
  static const double _wOppBar = 16;
  static const double _wBlotRisk = 1.15; // multiplied by pip value at risk
  static const double _blotFlatPenalty = 1.6;
  static const double _wOppBlot = 5.0;
  static const double _wPrime = 3.4; // per (length)^2
  static const double _wHomePrimeBonus = 1.25; // multiplier for home primes
  static const double _wMadePoint = 1.1;
  static const double _wHomeMadePoint = 3.0;
  static const double _wAnchor = 9.0;
  static const double _wBackCheckerExcess = -4.0;
  static const double _wContainment = 2.6;
  static const double _wOppHomeMade = -2.6;
  static const double _wRaceOff = 8.0;
  static const double _wStackPenalty = 0.55;

  /// Evaluates [position] from [player]'s perspective; higher is better.
  ///
  /// [exactRisk] selects between the exact 36-roll shot calculation and the
  /// cheap direct-shot approximation. [riskBudget] bounds the number of
  /// exact risk calculations (performance guard on pathological boards).
  static double evaluate(
    Position position,
    Player player, {
    bool exactRisk = false,
    int riskBudget = 90,
  }) {
    final opponent = player.opponent;
    final myPips = position.pipCount(player);
    final oppPips = position.pipCount(opponent);
    final pipDiff = (oppPips - myPips).toDouble();

    if (Rules.isRaceOver(position, player)) {
      return _evaluateRace(position, player, pipDiff);
    }
    return _evaluateContact(
      position,
      player,
      pipDiff,
      exactRisk: exactRisk,
      riskBudget: riskBudget,
    );
  }

  /// Pure race: pips dominate, borne-off checkers and smooth distribution
  /// break ties.
  static double _evaluateRace(
    Position position,
    Player player,
    double pipDiff,
  ) {
    final opponent = player.opponent;
    var score = pipDiff * _wPipRace;
    score += (position.offCount(player) - position.offCount(opponent)) *
        _wRaceOff;

    // Smooth home distribution: tall towers waste pips and bear off slowly.
    for (var p = 1; p <= 24; p++) {
      final n = position.countFor(player, p);
      if (n > 2) {
        final own = player == Player.white ? p : 25 - p;
        score -= (n - 2) * (n - 2) * _wStackPenalty * (own <= 6 ? 1.0 : 0.4);
      }
    }
    return score;
  }

  /// Contact position: structure and safety dominate.
  static double _evaluateContact(
    Position position,
    Player player,
    double pipDiff, {
    required bool exactRisk,
    required int riskBudget,
  }) {
    final opponent = player.opponent;
    var score = pipDiff * _wPipContact;

    // ------------------------------------------------------------------
    // Progress: borne-off checkers and bar occupancy.
    // ------------------------------------------------------------------
    score += position.offCount(player) * _wMyOff;
    score += position.offCount(opponent) * _wOppOff;
    score += position.barCount(player) * _wMyBar;
    score += position.barCount(opponent) * _wOppBar;

    // ------------------------------------------------------------------
    // Blots: exact/approximate probability of being hit, weighted by how
    // many pips a hit would cost.
    // ------------------------------------------------------------------
    score -= _blotPenalty(position, player,
        exactRisk: exactRisk, riskBudget: riskBudget);

    // Opponent blots are targets for the next turn.
    var oppBlots = 0;
    for (var p = 1; p <= 24; p++) {
      if (position.countFor(opponent, p) == 1) oppBlots++;
    }
    score += oppBlots * _wOppBlot;

    // ------------------------------------------------------------------
    // Structure: primes, made points, anchors, home board.
    // ------------------------------------------------------------------
    score += _primeScore(position, player);
    score += _primeScore(position, opponent) * -0.85;
    score += position.barCount(opponent) > 0
        ? _madeHomePoints(position, player) * _wHomeMadePoint
        : 0.0;
    score -= _madeHomePoints(position, opponent) * _wOppHomeMade;

    // Anchors in the opponent's home board give safety and late-game
    // chances; more than two lingering back checkers is usually bad.
    var backCheckers = 0;
    var anchors = 0;
    for (var p = opponent.homeLow; p <= opponent.homeHigh; p++) {
      final n = position.countFor(player, p);
      if (n == 0) continue;
      backCheckers += n;
      if (n >= 2) anchors++;
    }
    score += anchors * _wAnchor;
    if (backCheckers > 2) {
      score += (backCheckers - 2) * _wBackCheckerExcess;
    }

    // Containment: opponent checkers trapped behind our home board.
    var trapped = 0;
    for (var p = player.homeLow; p <= player.homeHigh; p++) {
      trapped += position.countFor(opponent, p);
    }
    score += trapped * _wContainment;

    return score;
  }

  /// Penalty for [player]'s blots.
  static double _blotPenalty(
    Position position,
    Player player, {
    required bool exactRisk,
    required int riskBudget,
  }) {
    final attacker = player.opponent;
    var penalty = 0.0;
    var usedBudget = 0;

    for (var p = 1; p <= 24; p++) {
      if (position.countFor(player, p) != 1) continue;

      final ownNumbering = player == Player.white ? p : 25 - p;
      final pipValueAtRisk = 25 - ownNumbering; // Pips lost when hit.

      // Cheap pre-filter: if no opposing checker can ever reach this blot
      // (nothing in front of it and nobody on the bar), the risk is zero.
      if (!_threatExists(position, attacker, p)) continue;

      double risk;
      if (exactRisk && usedBudget < riskBudget) {
        risk = ShotRisk.hitProbability(position, attacker, p);
        usedBudget++;
      } else {
        risk = ShotRisk.approximateHitProbability(position, attacker, p);
      }

      penalty += _blotFlatPenalty + risk * pipValueAtRisk * _wBlotRisk;
    }
    return penalty;
  }

  /// Whether any checker of [attacker] lies in front of [blotPoint] (i.e.
  /// still has to pass it) or the attacker has checkers on the bar.
  static bool _threatExists(
    Position position,
    Player attacker,
    int blotPoint,
  ) {
    if (position.barCount(attacker) > 0) return true;
    final delta = attacker.travelDelta;
    for (var p = 1; p <= 24; p++) {
      if (position.countFor(attacker, p) == 0) continue;
      if ((blotPoint - p) * delta > 0) return true;
    }
    return false;
  }

  /// Value of [player]'s primes (consecutive made points), including a
  /// bonus for primes inside their own home board.
  static double _primeScore(Position position, Player player) {
    var best = 0;
    var bestInHome = false;
    var run = 0;
    var runInHome = true;
    var totalMade = 0;

    for (var p = 1; p <= 25; p++) {
      final made = p <= 24 && position.countFor(player, p) >= 2;
      if (made) {
        totalMade++;
        run++;
        if (!player.isOwnHome(p)) runInHome = false;
      } else {
        if (run > best || (run == best && runInHome && !bestInHome)) {
          best = run;
          bestInHome = runInHome;
        }
        run = 0;
        runInHome = true;
      }
    }

    var score = totalMade * _wMadePoint;
    if (best >= 2) {
      var prime = best * best * _wPrime;
      if (bestInHome) {
        // A prime inside the own home board blocks re-entry after a hit.
        prime *= _wHomePrimeBonus;
      }
      score += prime;
    }
    return score;
  }

  /// Number of made points (two or more checkers) in [player]'s home board.
  static int _madeHomePoints(Position position, Player player) {
    var count = 0;
    for (var p = player.homeLow; p <= player.homeHigh; p++) {
      if (position.countFor(player, p) >= 2) count++;
    }
    return count;
  }
}
