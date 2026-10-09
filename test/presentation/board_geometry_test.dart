import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takhtenard/features/game/domain/models/player.dart';
import 'package:takhtenard/features/game/presentation/board_geometry.dart';

void main() {
  const size = Size(400, 336);

  test('the center boundary resolves to the nearest point row', () {
    final geometry = BoardGeometry(size: size);
    final x = geometry.pointRect(13).center.dx;

    expect(geometry.hitTest(Offset(x, size.height / 2 - 1)).point, 13);
    expect(geometry.hitTest(Offset(x, size.height / 2)).point, 12);
    expect(geometry.hitTest(Offset(x, size.height / 2 + 1)).point, 12);
  });

  test('bear-off slots remain in their assigned trays', () {
    final geometry = BoardGeometry(size: size);

    expect(
      geometry.leftTrayRect.contains(
        geometry.borneOffRect(Player.black, 0).center,
      ),
      isTrue,
    );
    expect(
      geometry.rightTrayRect.contains(
        geometry.borneOffRect(Player.white, 0).center,
      ),
      isTrue,
    );
  });

  test('flipped point hit-testing agrees with the displayed point', () {
    final geometry = BoardGeometry(size: size, flipped: true);
    final point = geometry.pointRect(13).center;

    expect(geometry.hitTest(point).point, 13);
  });
}
