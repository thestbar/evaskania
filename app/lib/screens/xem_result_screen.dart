import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class XemResultScreen extends StatelessWidget {
  const XemResultScreen({super.key, required this.controller});
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
                semanticLabel: 'Αρχική',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Έγινε',
                  style: TextStyle(
                      fontFamily: kHeadingFontFamily, fontVariations: kHeadingWeight, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Ξεματιάστηκε'),
              CardTitle('${controller.displayName}, είσαι καθαρός/ή πια!', fontSize: 24),
              CardBody('Το «${controller.xemFound}» έφυγε μαζί με τις σταγόνες. '
                  'Αν ξανανιώσεις παράξενα, ξανάρθε.'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${controller.xemStartPct}%',
                    style: TextStyle(
                      fontFamily: kHeadingFontFamily,
                      fontSize: 15,
                      decoration: TextDecoration.lineThrough,
                      color: AppTokens.colorText.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '0%',
                    style: TextStyle(
                      fontFamily: kHeadingFontFamily,
                      fontSize: 38,
                      fontVariations: kHeadingWeight,
                      color: AppTokens.accent700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('τωρινός δείκτης'.toUpperCase(),
                      style: TextStyle(fontSize: 11, color: AppTokens.colorText.withValues(alpha: 0.55))),
                ],
              ),
              const SizedBox(height: 4),
              CardMeta('Για ${controller.displayName} · ξεματιάστηκε στις ${controller.revealedAt}'),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          SecondaryButton(label: 'Ξεμάτιασε άλλον', onPressed: controller.goXemForm),
        ],
      ),
    );
  }
}
