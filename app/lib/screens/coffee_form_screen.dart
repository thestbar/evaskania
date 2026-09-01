import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';

class CoffeeFormScreen extends StatelessWidget {
  const CoffeeFormScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Πίσω',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Ο Καφές', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Φλιτζάνι', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          ImageSlot(
            placeholder: 'Ανέβασε το γυρισμένο φλιτζάνι',
            imagePath: controller.coffeePhotoPath,
            onImagePicked: controller.setCoffeePhoto,
            height: 260,
          ),
          const SizedBox(height: AppTokens.space6),
          PrimaryButton(
            label: "Δωσ' μου το φλιτζάνι",
            onPressed: controller.coffeePhotoPath == null ? null : controller.submitCoffee,
          ),
        ],
      ),
    );
  }
}
