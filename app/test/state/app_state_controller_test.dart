import 'dart:math';
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

  testWidgets("a second submitXem call cancels a still-animating first call's timers",
      (tester) async {
    // Regression test: without cancelling _xemTimer/_revealTimer at the top
    // of submitXem(), a first call's orphaned reveal timer could still fire
    // later and resurrect its stale xemResult over a second, still-loading
    // call's state.
    final controller = AppStateController(random: const FixedRandom());
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem()); // call A
    await tester.pump(const Duration(milliseconds: 1500)); // A reaches xemRemoving
    await tester.pump(const Duration(milliseconds: 800)); // A is midway through removal

    unawaited(controller.submitXem()); // call B, re-submits while A is still animating
    expect(controller.screen, AppScreen.xemLoading);

    // Advance past when A's now-cancelled reveal would have fired (had it
    // not been cancelled) but before B's own 1500ms loading delay elapses.
    await tester.pump(const Duration(milliseconds: 1450));
    expect(controller.screen, AppScreen.xemLoading);

    // Drain B's own remaining timers (the rest of its loading delay, its
    // full removal animation, and its reveal delay) so no fake timers are
    // left pending when the test body returns — AutomatedTestWidgetsFlutter
    // Binding asserts !timersPending after every testWidgets body, and a
    // bare, unreferenced Future.delayed's Timer stays registered in the
    // FakeAsync zone until it actually fires.
    await tester.pump(const Duration(milliseconds: 2300));
  });
}

void unawaited(Future<void> future) {}
