import 'package:flutter/material.dart';
import '../state/app_screen.dart';
import '../state/app_state_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';
import 'coffee_form_screen.dart';
import 'coffee_loading_screen.dart';
import 'coffee_result_screen.dart';
import 'home_screen.dart';
import 'xem_form_screen.dart';
import 'xem_loading_screen.dart';
import 'xem_removing_screen.dart';
import 'xem_result_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller, this.pickImage = defaultPickImage});

  final AppStateController controller;
  final ImagePickFn pickImage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: switch (controller.screen) {
              AppScreen.home => HomeScreen(controller: controller),
              AppScreen.xemForm => XemFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.xemLoading => const XemLoadingScreen(),
              AppScreen.xemRemoving => XemRemovingScreen(controller: controller),
              AppScreen.xemResult => XemResultScreen(controller: controller),
              AppScreen.xemRejected || AppScreen.coffeeRejected =>
                _RejectedFallback(controller: controller),
              AppScreen.coffeeForm => CoffeeFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.coffeeLoading => const CoffeeLoadingScreen(),
              AppScreen.coffeeResult => CoffeeResultScreen(controller: controller),
            },
          ),
        );
      },
    );
  }
}

/// Temporary stand-in for [AppScreen.xemRejected] / [AppScreen.coffeeRejected].
/// Both states are unreachable until Tasks B2 and C2 wire the real detection
/// checks into [AppStateController]; those tasks replace this switch arm
/// with the real `XemRejectedScreen` / `CoffeeRejectedScreen` and delete
/// this class once both are in place.
class _RejectedFallback extends StatelessWidget {
  const _RejectedFallback({required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SecondaryButton(label: 'Αρχική', onPressed: controller.goHome),
    );
  }
}
