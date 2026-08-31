import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/xem_form_screen.dart';
import 'package:evaskania/screens/xem_loading_screen.dart';
import 'package:evaskania/screens/xem_removing_screen.dart';
import 'package:evaskania/screens/xem_result_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('XemFormScreen shows fields and a disabled button with no photo', (tester) async {
    final controller = AppStateController();
    // Scaffold is required here (not just MaterialApp): TextField asserts an
    // ambient Material ancestor at build time, unlike the Material buttons
    // (which build their own Material internally) — see A3/A4's own tests,
    // which wrap widget-under-test content in Scaffold(body: ...) for the
    // same reason.
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: XemFormScreen(controller: controller))));
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Όνομα'), findsOneWidget);
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('XemFormScreen enables submit once a photo path is set', (tester) async {
    final controller = AppStateController()..setXemPhoto('/tmp/a.jpg');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: XemFormScreen(controller: controller))));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('XemFormScreen name field updates the controller', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: XemFormScreen(controller: controller))));
    await tester.enterText(find.byType(TextField), 'Μαρία');
    expect(controller.name, 'Μαρία');
  });

  testWidgets('XemLoadingScreen shows the waiting copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: XemLoadingScreen()));
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);
  });

  testWidgets('XemRemovingScreen shows the affliction and percentage', (tester) async {
    // Sets controller fields directly rather than driving them through
    // submitXem()/a timer — this screen only reads current state, and this
    // keeps the test decoupled from Tasks B2/C2's later changes to submitXem
    // (which start awaiting a real detection check before this point).
    final controller = AppStateController()
      ..xemFound = 'Ελαφρύ ματάκι από ζήλια'
      ..xemNote = 'Κάποιος ζήλεψε κάτι μικρό — τα μαλλιά σου, μάλλον.'
      ..xemPct = 23;

    await tester.pumpWidget(MaterialApp(home: XemRemovingScreen(controller: controller)));
    expect(find.text('ΒΡΈΘΗΚΕ'), findsOneWidget); // kicker uppercases, per A3's CardKicker
    expect(find.text('Ελαφρύ ματάκι από ζήλια'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
  });

  testWidgets('XemResultScreen shows the display name and a retry button', (tester) async {
    // Same rationale as above: set state directly instead of calling
    // submitXem(), so this test stays valid after Tasks B2/C2.
    final controller = AppStateController()
      ..setName('Μαρία')
      ..xemFound = 'Βαρύ μάτι από σχόλιο'
      ..xemStartPct = 78
      ..revealedAt = '11:26 μ.μ.';

    await tester.pumpWidget(MaterialApp(home: XemResultScreen(controller: controller)));
    expect(find.textContaining('Μαρία, είσαι καθαρός/ή πια!'), findsOneWidget);
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);
  });
}
