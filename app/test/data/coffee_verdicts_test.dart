import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/data/coffee_verdicts.dart';

/// A Random test double whose nextInt() calls are scripted in advance.
/// Running past the end of the script throws (RangeError), which is used
/// deliberately below to prove rollCoffeeVerdict does NOT draw a second
/// value when it doesn't need to.
class _ScriptedRandom implements Random {
  _ScriptedRandom(List<int> ints) : _ints = List.of(ints);
  final List<int> _ints;
  int _i = 0;

  @override
  int nextInt(int max) => _ints[_i++];

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  test('pool has a large, non-trivial number of outcomes', () {
    expect(coffeeVerdicts.length, greaterThanOrEqualTo(30));
  });

  test('does not reroll when the first pick does not match avoid', () {
    final random = _ScriptedRandom([2]); // only one value scripted
    final result = rollCoffeeVerdict(random, avoid: coffeeVerdicts[0]);
    expect(identical(result, coffeeVerdicts[2]), isTrue);
  });

  test('rerolls once when the first pick is identical to avoid', () {
    final random = _ScriptedRandom([0, 1]);
    final result = rollCoffeeVerdict(random, avoid: coffeeVerdicts[0]);
    expect(identical(result, coffeeVerdicts[1]), isTrue);
  });
}
