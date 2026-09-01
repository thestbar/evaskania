import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class CoffeeLoadingScreen extends StatelessWidget {
  const CoffeeLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppTokens.accent2_100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_outlined, size: 34, color: AppTokens.accent2_700),
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Η γιαγιά διαβάζει…',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 15)),
          const SizedBox(height: 6),
          Text('γύρνα το, μη βιάζεσαι',
              style: TextStyle(fontSize: 12, color: AppTokens.colorText.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
