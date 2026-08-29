import 'dart:math' as math;

/// The result of rolling the two dice.
class DiceRoll {
  const DiceRoll(this.first, this.second)
      : assert(first >= 1 && first <= 6),
        assert(second >= 1 && second <= 6);

  final int first;
  final int second;

  bool get isDouble => first == second;

  /// The list of individual moves granted by this roll:
  /// two values normally, four values when a double is thrown.
  List<int> get moves =>
      isDouble ? List<int>.filled(4, first) : <int>[first, second];

  /// Randomly rolls two dice using [random].
  static DiceRoll roll(math.Random random) =>
      DiceRoll(random.nextInt(6) + 1, random.nextInt(6) + 1);

  @override
  String toString() => 'DiceRoll($first, $second)';

  @override
  bool operator ==(Object other) =>
      other is DiceRoll && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);
}
