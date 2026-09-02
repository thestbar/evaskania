import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/widgets/app_buttons.dart';

void main() {
  testWidgets('PrimaryButton fires onPressed and disables when null', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrimaryButton(label: 'Ξεκίνα', onPressed: () => pressed = true),
      ),
    ));
    await tester.tap(find.text('Ξεκίνα'));
    expect(pressed, isTrue);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Ξεκίνα', onPressed: null)),
    ));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('SecondaryButton fires onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SecondaryButton(label: 'Άλλον', onPressed: () => pressed = true),
      ),
    ));
    await tester.tap(find.text('Άλλον'));
    expect(pressed, isTrue);
  });

  testWidgets('GhostIconButton exposes its semantic label', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GhostIconButton(
          icon: Icons.arrow_back,
          semanticLabel: 'Πίσω',
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(pressed, isTrue);
    expect(find.bySemanticsLabel('Πίσω'), findsOneWidget);
  });
}
