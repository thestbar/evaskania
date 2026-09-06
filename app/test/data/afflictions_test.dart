import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/data/afflictions.dart';

/// A Random test double whose nextDouble()/nextInt() calls are scripted in
/// advance. Running past the end of a script throws (RangeError), which is
/// used deliberately below to prove a code path did NOT draw extra values
/// (e.g. that rollXemAffliction only rerolls when it actually needs to).
class _ScriptedRandom implements Random {
  _ScriptedRandom({List<double> doubles = const [], List<int> ints = const []})
      : _doubles = List.of(doubles),
        _ints = List.of(ints);
  final List<double> _doubles;
  final List<int> _ints;
  int _di = 0;
  int _ii = 0;

  @override
  double nextDouble() => _doubles[_di++];

  @override
  int nextInt(int max) => _ints[_ii++];

  @override
  bool nextBool() => false;
}

void main() {
  group('rollXemAffliction', () {
    test('a low roll (<0.05) lands on 0% from the clean pool', () {
      final random = _ScriptedRandom(doubles: [0.01], ints: [0]);
      final result = rollXemAffliction(random);
      expect(result.pct, 0);
      expect(result.affliction.name, 'Τίποτα το αξιοσημείωτο');
    });

    test('a roll in [0.05, 0.10) lands on a critical >100% from the critical pool', () {
      // r=0.06 selects the critical branch; ints[0]=42 -> pct = 101+42=143;
      // ints[1]=0 picks the first critical-pool entry.
      final random = _ScriptedRandom(doubles: [0.06], ints: [42, 0]);
      final result = rollXemAffliction(random);
      expect(result.pct, 143);
      expect(result.affliction.name, 'ΚΡΙΣΙΜΟ ΜΑΤΙ — θρύλος βασκανίας');
    });

    test('pct 25 draws from the mild pool, pct 26 from the moderate pool', () {
      final mildRandom = _ScriptedRandom(doubles: [0.5], ints: [24, 0]);
      expect(rollXemAffliction(mildRandom).pct, 25);

      final moderateRandom = _ScriptedRandom(doubles: [0.5], ints: [25, 0]);
      expect(rollXemAffliction(moderateRandom).pct, 26);
    });

    test('pct 75 draws from the heavy pool, pct 76 from the severe pool', () {
      final heavyRandom = _ScriptedRandom(doubles: [0.5], ints: [74, 0]);
      expect(rollXemAffliction(heavyRandom).pct, 75);

      final severeRandom = _ScriptedRandom(doubles: [0.5], ints: [75, 0]);
      expect(rollXemAffliction(severeRandom).pct, 76);
    });

    test('rerolls once when the first roll repeats avoidName', () {
      // First roll: r=0.01 -> pct 0, clean pool index 0 ("Τίποτα το
      // αξιοσημείωτο") -> matches avoidName, so it must reroll.
      // Second roll: r=0.5 -> normal branch, ints[1]=10 -> pct 11 (mild),
      // ints[2]=3 -> mild pool index 3.
      final random = _ScriptedRandom(doubles: [0.01, 0.5], ints: [0, 10, 3]);
      final result = rollXemAffliction(random, avoidName: 'Τίποτα το αξιοσημείωτο');
      expect(result.pct, 11);
      expect(result.affliction.name, 'Ελαφρύ κακό μάτι από selfie');
    });

    test('does not reroll when the first roll does not repeat avoidName', () {
      // Only enough scripted values for ONE roll — a second draw would throw.
      final random = _ScriptedRandom(doubles: [0.01], ints: [0]);
      final result = rollXemAffliction(random, avoidName: 'κάτι εντελώς άλλο');
      expect(result.pct, 0);
      expect(result.affliction.name, 'Τίποτα το αξιοσημείωτο');
    });
  });
}
