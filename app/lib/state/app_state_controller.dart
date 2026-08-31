import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/afflictions.dart';
import '../data/coffee_verdicts.dart';
import 'app_screen.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({Random? random}) : _random = random ?? Random();

  final Random _random;
  Timer? _xemTimer;

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
    screen = AppScreen.home;
    notifyListeners();
  }

  void goXemForm() {
    _xemTimer?.cancel();
    xemPhotoPath = null;
    xemRejectionReason = null;
    screen = AppScreen.xemForm;
    notifyListeners();
  }

  void goCoffeeForm() {
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
    screen = AppScreen.xemLoading;
    notifyListeners();

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
    var ticks = 0;
    _xemTimer?.cancel();
    _xemTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      ticks += 1;
      final elapsedMs = ticks * tickMs;
      final frac = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
      xemPct = (total * (1 - frac)).round();
      dropsCleared = frac >= 0.999 ? 3 : (frac * 3).floor();
      notifyListeners();
      if (frac >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
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
    super.dispose();
  }
}
