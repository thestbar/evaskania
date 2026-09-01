import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/xem_rejected_screen.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('shows the no-face message when rejected for no face', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.noFace;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    expect(find.text('Δεν βλέπω πρόσωπο εδώ'), findsOneWidget);
  });

  testWidgets('shows the multiple-faces message when rejected for multiple faces', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.multipleFaces;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    expect(find.text('Ένας-ένας, παρακαλώ'), findsOneWidget);
  });

  testWidgets('retry button returns to the xem form', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.noFace;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    await tester.tap(find.text('Δοκίμασε ξανά'));
    expect(controller.screen, AppScreen.xemForm);
  });
}
