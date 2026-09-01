import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/app_shell.dart';
import 'state/app_state_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('el', null);
  runApp(EVaskaniaApp(controller: AppStateController()));
}

class EVaskaniaApp extends StatelessWidget {
  const EVaskaniaApp({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-Vaskania',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(controller: controller),
    );
  }
}
