import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/afflictions.dart';
import '../data/coffee_verdicts.dart';
import '../detection/cup_checker.dart';
import '../detection/face_checker.dart';
import 'app_screen.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({Random? random, FaceChecker? faceChecker, CupChecker? cupChecker})
      : _random = random ?? Random(),
        _faceChecker = faceChecker ?? FaceChecker(),
        _cupChecker = cupChecker ?? CupChecker();

  final Random _random;
  final FaceChecker _faceChecker;
  final CupChecker _cupChecker;
  Timer? _xemTimer;
  Timer? _revealTimer;

  AppScreen screen = AppScreen.home;
  String name = '';
  String? xemPhotoPath;
  String? coffeePhotoPath;
  XemRejectionReason? xemRejectionReason;

  String xemFound = '';
  String xemNote = '';
  int xemStartPct = 0;
  int xemPct = 0;
  int dropsCleared = 0;
  String revealedAt = '';
  CoffeeVerdict? coffeeResult;

  String get displayName => name.trim().isEmpty ? 'Κάποιον' : name.trim();

  String get today => DateFormat('d MMM', 'el').format(DateTime.now());

  void goHome() {
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    screen = AppScreen.home;
    notifyListeners();
  }

  void goXemForm() {
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    xemPhotoPath = null;
    xemRejectionReason = null;
    screen = AppScreen.xemForm;
    notifyListeners();
  }

  void goCoffeeForm() {
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    coffeePhotoPath = null;
    screen = AppScreen.coffeeForm;
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setXemPhoto(String path) {
    xemPhotoPath = path;
    notifyListeners();
  }

  void setCoffeePhoto(String path) {
    coffeePhotoPath = path;
    notifyListeners();
  }

  Future<void> submitXem() async {
    if (xemPhotoPath == null) return;
    // A second submitXem() call while a first is still animating must not
    // let the first call's orphaned timers resurrect its (stale) result
    // over this call's state later — cancel them before proceeding.
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    screen = AppScreen.xemLoading;
    notifyListeners();

    FaceCheckResult result;
    try {
      result = await _faceChecker.check(xemPhotoPath!);
    } catch (_) {
      result = FaceCheckResult.noFace;
    }
    if (result != FaceCheckResult.ok) {
      xemRejectionReason = result == FaceCheckResult.noFace
          ? XemRejectionReason.noFace
          : XemRejectionReason.multipleFaces;
      screen = AppScreen.xemRejected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    final affliction = xemAfflictions[_random.nextInt(xemAfflictions.length)];
    _startRemoval(affliction);
  }

  void _startRemoval(Affliction affliction) {
    xemFound = affliction.name;
    xemNote = affliction.note;
    xemStartPct = affliction.startPct;
    xemPct = affliction.startPct;
    dropsCleared = 0;
    screen = AppScreen.xemRemoving;
    notifyListeners();

    final total = affliction.startPct;
    const totalDurationMs = 1800;
    const tickMs = 60;
    // Progress is driven by counting periodic-timer ticks rather than reading
    // DateTime.now(): flutter_test's FakeAsync zone fakes Timer/Future but has
    // no hook to fake the wall clock, so a DateTime.now()-based elapsed-time
    // calculation never advances under tester.pump() (see the A5 report for
    // the bug this replaced). The trade-off: progress now tracks how many
    // times the periodic timer actually fires, not true wall-clock elapsed
    // time, so OS timer throttling/coalescing (e.g. app backgrounded then
    // resumed) could stretch this past 1800ms of real time, unlike a
    // wall-clock approach which would self-correct. Acceptable here since
    // this is a decorative, low-stakes loading animation — don't revert to
    // DateTime.now() without understanding why it was changed.
    var ticks = 0;
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    _xemTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      ticks += 1;
      final elapsedMs = ticks * tickMs;
      final frac = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
      xemPct = (total * (1 - frac)).round();
      dropsCleared = frac >= 0.999 ? 3 : (frac * 3).floor();
      notifyListeners();
      if (frac >= 1.0) {
        timer.cancel();
        _revealTimer = Timer(const Duration(milliseconds: 400), () {
          revealedAt = _formatNow();
          screen = AppScreen.xemResult;
          notifyListeners();
        });
      }
    });
  }

  Future<void> submitCoffee() async {
    if (coffeePhotoPath == null) return;
    screen = AppScreen.coffeeLoading;
    notifyListeners();

    CupCheckResult result;
    try {
      result = await _cupChecker.check(coffeePhotoPath!);
    } catch (_) {
      result = CupCheckResult.notACup;
    }
    if (result != CupCheckResult.ok) {
      screen = AppScreen.coffeeRejected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2200));
    coffeeResult = coffeeVerdicts[_random.nextInt(coffeeVerdicts.length)];
    revealedAt = _formatNow();
    screen = AppScreen.coffeeResult;
    notifyListeners();
  }

  String _formatNow() => DateFormat('h:mm a', 'el').format(DateTime.now());

  @override
  void dispose() {
    _xemTimer?.cancel();
    _revealTimer?.cancel();
    _faceChecker.dispose();
    _cupChecker.dispose();
    super.dispose();
  }
}
