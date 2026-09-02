import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders its children and responds to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppCard(
          onTap: () => tapped = true,
          children: const [
            CardKicker('Τελετουργία Ι'),
            CardTitle('Ξεμάτιασμα'),
            CardBody('Περιγραφή'),
            CardMeta('~30 δευτ.', icon: Icons.visibility_outlined),
          ],
        ),
      ),
    ));

    expect(find.text('ΤΕΛΕΤΟΥΡΓΊΑ Ι'), findsOneWidget); // kicker uppercases
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Περιγραφή'), findsOneWidget);
    expect(find.text('~30 δευτ.'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byType(AppCard));
    expect(tapped, isTrue);
  });

  testWidgets('AppCard without onTap is not tappable', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppCard(children: [CardTitle('Τίτλος')])),
    ));
    expect(find.byType(InkWell), findsNothing);
  });
}
