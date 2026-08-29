import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/domain/models/position.dart';
import 'package:takhtenard/features/game/domain/ai/shot_risk.dart';

void main() {
  group('ShotRisk.hitProbability (exact)', () {
    test('a blot one pip away is hit by 11 of 36 rolls', () {
      // Black checker on 9 travels towards 24; the white blot on 10 is one
      // pip ahead, so every roll containing a 1 hits it. No indirect shot
      // can sum to 1, and no double can hit either.
      final pos = Position.custom(white: {10: 1}, black: {9: 1});
      final risk = ShotRisk.hitProbability(pos, Player.black, 10);
      expect(risk, closeTo(11 / 36, 1e-9));
    });

    test('a blot four pips away counts indirect shots too', () {
      // Black on 20, white blot on 24 (distance 4):
      //  * 11 rolls contain a 4 (direct hit);
      //  * {1,3} twice and {2,2} once reach 24 with two dice;
      //  * {1,1} reaches it with all four ones.
      // Total: 15 of 36.
      final pos = Position.custom(white: {24: 1}, black: {20: 1});
      final risk = ShotRisk.hitProbability(pos, Player.black, 24);
      expect(risk, closeTo(15 / 36, 1e-9));
    });

    test('indirect shots respect blocked intermediate points', () {
      // Black on 3 must travel 7 pips to reach the white blot on 10. The
      // hitting combinations are {1,6}, {2,5} and {3,4} (each twice).
      // White made points on 6 and 7, which blocks both orders of the
      // {3,4} combination: 3+3=6 and 3+4=7 are closed. The remaining
      // hitting rolls are the 4 rolls of {1,6} and {2,5}.
      final pos = Position.custom(
        white: {10: 1, 6: 2, 7: 2},
        black: {3: 1},
      );
      final risk = ShotRisk.hitProbability(pos, Player.black, 10);
      expect(risk, closeTo(4 / 36, 1e-9));
    });

    test('unblocked indirect shots all count', () {
      // Same geometry, but points 6 and 7 are open: {3,4} hits too, so
      // 6 of 36 rolls hit.
      final pos = Position.custom(white: {10: 1}, black: {3: 1});
      final risk = ShotRisk.hitProbability(pos, Player.black, 10);
      expect(risk, closeTo(6 / 36, 1e-9));
    });

    test('an attacker on the bar must enter first', () {
      // Black is on the bar; white's blot sits on 10. Black enters on
      // points 1..6 and hits with the remaining die when entry + die = 10:
      // {4,6} (2 rolls) and {5,5} (1 roll) — 3 of 36.
      final pos = Position.custom(white: {10: 1}, black: {}, blackBar: 1);
      final risk = ShotRisk.hitProbability(pos, Player.black, 10);
      expect(risk, closeTo(3 / 36, 1e-9));
    });

    test('an untouchable blot has zero risk', () {
      // Every black checker has already passed the white blot on 10.
      final pos = Position.custom(white: {10: 1}, black: {22: 2, 23: 2});
      final risk = ShotRisk.hitProbability(pos, Player.black, 10);
      expect(risk, 0.0);
    });

    test('a closed-out opponent cannot hit anything', () {
      // White made every point 1..6 (black's entry board); black on the
      // bar cannot enter at all, so whatever blot white leaves is safe.
      final pos = Position.custom(
        white: {10: 1, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2},
        black: {},
        blackBar: 1,
      );
      expect(ShotRisk.hitProbability(pos, Player.black, 10), 0.0);
    });
  });

  group('ShotRisk.approximateHitProbability', () {
    test('direct shots use the union formula', () {
      final pos = Position.custom(white: {10: 1}, black: {9: 1});
      expect(
        ShotRisk.approximateHitProbability(pos, Player.black, 10),
        closeTo(11 / 36, 1e-9),
      );

      // Two direct shots with different distances: dies {1, 2} ->
      // 36 - (6-2)^2 = 20 rolls.
      final pos2 = Position.custom(white: {10: 1}, black: {8: 1, 9: 1});
      expect(
        ShotRisk.approximateHitProbability(pos2, Player.black, 10),
        closeTo(20 / 36, 1e-9),
      );
    });

    test('no threat yields zero', () {
      final pos = Position.custom(white: {10: 1}, black: {22: 2});
      expect(
        ShotRisk.approximateHitProbability(pos, Player.black, 10),
        0.0,
      );
    });
  });
}
