import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: AppTokens.colorText),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.only(top: AppTokens.space2),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTokens.colorText))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ΤΕΎΧΟΣ ΤΣΈΠΗΣ',
                    style: TextStyle(
                        fontSize: 10, letterSpacing: 1.4, color: AppTokens.colorText.withValues(alpha: 0.6))),
                Text(controller.today,
                    style: TextStyle(fontSize: 10, color: AppTokens.colorText.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          const Text('e-ΒΑΣΚΑΝΙΑ',
              style: TextStyle(
                  fontFamily: kHeadingFontFamily, fontSize: 40, height: 0.95, color: AppTokens.colorText)),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Δύο τελετουργίες τσέπης: διώξε το μάτι, διάβασε τον καφέ. '
            'Για πλάκα, με τους φίλους σου.',
            style: TextStyle(fontSize: 14, height: 1.5, color: AppTokens.colorText.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: AppTokens.space4),
          AppCard(
            onTap: controller.goXemForm,
            children: const [
              CardKicker('Τελετουργία Ι'),
              CardTitle('Ξεμάτιασμα'),
              CardBody('Φωτογραφία, όνομα, και σε ξεματιάζουμε επιτόπου — τρεις '
                  'σταγόνες λάδι το επισφραγίζουν.'),
              CardMeta('~30 δευτ.', icon: Icons.visibility_outlined),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          AppCard(
            onTap: controller.goCoffeeForm,
            children: const [
              CardKicker('Τελετουργία ΙΙ'),
              CardTitle('Ο Καφές'),
              CardBody('Γύρνα το φλιτζάνι, ανέβασε το κατακάθι, άσε τη γιαγιά '
                  'να διαβάσει την εβδομάδα σου.'),
              CardMeta('~20 δευτ.', icon: Icons.coffee_outlined),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Η προσευχή δεν λέγεται πάνω από τρεις φορές στη ζωή μας — μετά '
            'χάνει τη δύναμή της.',
            style: TextStyle(
                fontSize: 11, fontStyle: FontStyle.italic, color: AppTokens.colorText.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
