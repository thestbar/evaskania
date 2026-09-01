import 'dart:math';
import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/detection/face_checker.dart';
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

class _OneFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async =>
      [const Rect.fromLTWH(0, 0, 400, 400)];
}

class _NoFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => const [];
}

class _TwoFaces implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => [
        const Rect.fromLTWH(0, 0, 400, 400),
        const Rect.fromLTWH(500, 500, 400, 400),
      ];
}

class _FixedSize implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async => const Size(1000, 1000);
}

FaceChecker _faceCheckerWith(FaceDetectionSource source) =>
    FaceChecker(detectionSource: source, sizeReader: _FixedSize());

void unawaited(Future<void> future) {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  testWidgets('goXemForm clears any previous photo and rejection, and switches screen',
      (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.setXemPhoto('/tmp/a.jpg');
    controller.goHome();
    controller.goXemForm();
    expect(controller.screen, AppScreen.xemForm);
    expect(controller.xemPhotoPath, isNull);
    expect(controller.xemRejectionReason, isNull);
  });

  testWidgets('submitXem transitions loading -> removing -> result when a face is found',
      (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

    await tester.pump(); // the face check itself resolves on a microtask
    expect(controller.screen, AppScreen.xemLoading); // still in the 1500ms simulated wait

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

  testWidgets('submitXem rejects with noFace when the checker finds no face', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_NoFace()));
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.noFace);
  });

  testWidgets('submitXem rejects with multipleFaces when the checker finds two', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_TwoFaces()));
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.multipleFaces);
  });

  testWidgets('displayName falls back to Κάποιον when name is blank', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    expect(controller.displayName, 'Κάποιον');
    controller.setName('  Μαρία  ');
    expect(controller.displayName, 'Μαρία');
  });

  testWidgets('submitCoffee transitions loading -> result over time', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
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
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 1800));

    controller.goHome();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.screen, AppScreen.home);
  });

  testWidgets("a second submitXem call cancels a still-animating first call's timers",
      (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 800));

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

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
