import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/coffee_rejected_screen.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('shows the not-a-cup message', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeRejectedScreen(controller: controller)));
    expect(find.text('Αυτό δεν είναι φλιτζάνι'), findsOneWidget);
  });

  testWidgets('retry button returns to the coffee form', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeRejectedScreen(controller: controller)));
    await tester.tap(find.text('Δοκίμασε ξανά'));
    expect(controller.screen, AppScreen.coffeeForm);
  });
}
