import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/screens/app_shell.dart';
import 'package:evaskania/state/app_state_controller.dart';

Future<String?> _fakePick(ImageSource source) async => '/tmp/fake.jpg';

void main() {
  // HomeScreen reads controller.today, which formats via DateFormat('d MMM',
  // 'el'); that throws LocaleDataException unless the 'el' locale data has
  // been loaded first (see app_state_controller_test.dart for the same
  // pattern). main.dart does this in main() before runApp(), but these
  // tests pump AppShell directly, so it must be done here too.
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  testWidgets('home shows the masthead and both ritual cards', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Ο Καφές'), findsOneWidget);
  });

  testWidgets('full Ξεμάτιασμα flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ξεμάτιασμα'));
    await tester.pumpAndSettle();
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ξεκίνα το ξεμάτιασμα'));
    await tester.pump();
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    // CardKicker uppercases its text (see xem_screens_test.dart), so the
    // rendered kicker is 'ΒΡΈΘΗΚΕ', not 'Βρέθηκε'.
    expect(find.text('ΒΡΈΘΗΚΕ'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });

  testWidgets('full Ο Καφές flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ο Καφές'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ανέβασε το γυρισμένο φλιτζάνι'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Δωσ' μου το φλιτζάνι"));
    await tester.pump();
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });
}
