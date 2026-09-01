import 'package:flutter/material.dart';
import '../state/app_screen.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class XemRejectedScreen extends StatelessWidget {
  const XemRejectedScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final isMultiple = controller.xemRejectionReason == XemRejectionReason.multipleFaces;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(icon: Icons.arrow_back, semanticLabel: 'Πίσω', onPressed: controller.goHome),
              const SizedBox(width: AppTokens.space2),
              const Text('Ξεμάτιασμα', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              CardTitle(
                isMultiple ? 'Ένας-ένας, παρακαλώ' : 'Δεν βλέπω πρόσωπο εδώ',
                fontSize: 20,
              ),
              CardBody(
                isMultiple
                    ? 'Η γιαγιά ξεματιάζει έναν άνθρωπο τη φορά — ανέβασε φωτογραφία με '
                        'ένα μόνο πρόσωπο.'
                    : 'Η γιαγιά χρειάζεται να δει ένα πρόσωπο για να διώξει το μάτι — '
                        'δοκίμασε μια φωτογραφία που να φαίνεται καθαρά κάποιος.',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          PrimaryButton(label: 'Δοκίμασε ξανά', onPressed: controller.goXemForm),
        ],
      ),
    );
  }
}
