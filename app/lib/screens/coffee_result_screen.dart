import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class CoffeeResultScreen extends StatelessWidget {
  const CoffeeResultScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.coffeeResult!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Αρχική',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Η ανάγνωση',
                  style: TextStyle(
                      fontFamily: kHeadingFontFamily, fontVariations: kHeadingWeight, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Σύμβολα στο φλιτζάνι'),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final symbol in result.symbols)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.accent2_100,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: Text(symbol,
                          style: const TextStyle(fontSize: 11, color: AppTokens.accent2_800)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CardBody('"${result.quote}"', italic: true, fontSize: 16),
              CardMeta('— η Γιαγιά, ${controller.revealedAt}'),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          SecondaryButton(label: 'Διάβασε άλλο φλιτζάνι', onPressed: controller.goCoffeeForm),
        ],
      ),
    );
  }
}
