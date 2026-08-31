import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';

class XemRemovingScreen extends StatelessWidget {
  const XemRemovingScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ξεμάτιασμα',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Βρέθηκε'),
              CardTitle(controller.xemFound, fontSize: 22),
              CardBody(controller.xemNote),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      '${controller.xemPct}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: kHeadingFontFamily,
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.accent700,
                      ),
                    ),
                    Text(
                      'δείκτης βασκανίας — φεύγει',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: AppTokens.colorText.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final cleared = controller.dropsCleared > i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: AnimatedOpacity(
                      opacity: cleared ? 0.15 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: cleared ? 0.4 : 1,
                        duration: const Duration(milliseconds: 500),
                        child: Transform.rotate(
                          angle: 0.785398, // 45deg — matches the CSS drop shape
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTokens.accent700,
                              borderRadius: BorderRadius.circular(10)
                                  .copyWith(bottomLeft: const Radius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
