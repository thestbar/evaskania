import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

/// Deterministic stand-in for dart:math's Random so tests always land on
/// the first affliction / coffee verdict in the list.
class FixedRandom implements Random {
  const FixedRandom();
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  testWidgets('goXemForm clears any previous photo and switches screen', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.setXemPhoto('/tmp/a.jpg');
    controller.goHome();
    controller.goXemForm();
    expect(controller.screen, AppScreen.xemForm);
    expect(controller.xemPhotoPath, isNull);
  });

  testWidgets('submitXem transitions loading -> removing -> result over time', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(controller.screen, AppScreen.xemRemoving);
    expect(controller.dropsCleared, 0);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(controller.dropsCleared, 3);
    expect(controller.xemPct, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.screen, AppScreen.xemResult);
    expect(controller.revealedAt, isNotEmpty);
  });

  testWidgets('displayName falls back to Κάποιον when name is blank', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    expect(controller.displayName, 'Κάποιον');
    controller.setName('  Μαρία  ');
    expect(controller.displayName, 'Μαρία');
  });

  testWidgets('submitCoffee transitions loading -> result over time', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.goCoffeeForm();
    controller.setCoffeePhoto('/tmp/cup.jpg');

    unawaited(controller.submitCoffee());
    expect(controller.screen, AppScreen.coffeeLoading);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(controller.screen, AppScreen.coffeeResult);
    expect(controller.coffeeResult, isNotNull);
  });

  testWidgets('navigating home during the reveal delay does not snap back to xemResult',
      (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 1800)); // periodic timer completes, reveal scheduled

    controller.goHome(); // navigate away during the 400ms reveal window
    await tester.pump(const Duration(milliseconds: 400)); // let any stray timer fire

    expect(controller.screen, AppScreen.home);
  });
}

void unawaited(Future<void> future) {}
