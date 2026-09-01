import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class CoffeeRejectedScreen extends StatelessWidget {
  const CoffeeRejectedScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(icon: Icons.arrow_back, semanticLabel: 'Πίσω', onPressed: controller.goHome),
              const SizedBox(width: AppTokens.space2),
              const Text('Ο Καφές', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          const AppCard(
            children: [
              CardTitle('Αυτό δεν είναι φλιτζάνι', fontSize: 20),
              CardBody(
                'Η γιαγιά διαβάζει μόνο καφέ — ανέβασε μια φωτογραφία του φλιτζανιού, '
                'γυρισμένο, με το κατακάθι στα τοιχώματα.',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          PrimaryButton(label: 'Δοκίμασε ξανά', onPressed: controller.goCoffeeForm),
        ],
      ),
    );
  }
}
