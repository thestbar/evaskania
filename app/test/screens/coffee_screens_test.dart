import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/coffee_form_screen.dart';
import 'package:evaskania/screens/coffee_loading_screen.dart';
import 'package:evaskania/screens/coffee_result_screen.dart';
import 'package:evaskania/data/coffee_verdicts.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('CoffeeFormScreen shows the photo slot and a disabled button with no photo', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeFormScreen(controller: controller)));
    expect(find.text('Ο Καφές'), findsOneWidget);
    expect(find.text('Ανέβασε το γυρισμένο φλιτζάνι'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('CoffeeFormScreen enables submit once a photo path is set', (tester) async {
    final controller = AppStateController()..setCoffeePhoto('/tmp/cup.jpg');
    await tester.pumpWidget(MaterialApp(home: CoffeeFormScreen(controller: controller)));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('CoffeeLoadingScreen shows the waiting copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CoffeeLoadingScreen()));
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);
  });

  testWidgets('CoffeeResultScreen shows the verdict symbols and quote', (tester) async {
    // Sets coffeeResult directly rather than driving it through
    // submitCoffee() — this screen only reads current state, and this keeps
    // the test decoupled from Task C2's later change to submitCoffee (which
    // starts awaiting a real detection check before this point).
    const verdict = CoffeeVerdict(symbols: ['Πουλί', 'Κουκκίδες'], quote: 'Δοκιμαστικό απόσπασμα.');
    final controller = AppStateController()
      ..coffeeResult = verdict
      ..revealedAt = '11:26 μ.μ.';

    await tester.pumpWidget(MaterialApp(home: CoffeeResultScreen(controller: controller)));
    for (final symbol in verdict.symbols) {
      expect(find.text(symbol), findsOneWidget);
    }
    expect(find.textContaining(verdict.quote), findsOneWidget);
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);
  });
}
