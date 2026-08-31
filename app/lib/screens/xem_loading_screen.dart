import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class XemLoadingScreen extends StatelessWidget {
  const XemLoadingScreen({super.key});

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
              color: AppTokens.accent100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined, size: 40, color: AppTokens.accent700),
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Η γιαγιά συγκεντρώνεται…',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 15)),
          const SizedBox(height: 6),
          Text('τρεις σταγόνες λάδι στο νερό',
              style: TextStyle(fontSize: 12, color: AppTokens.colorText.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
