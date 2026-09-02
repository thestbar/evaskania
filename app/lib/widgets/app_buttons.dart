import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

const TextStyle _buttonTextStyle = TextStyle(
  fontFamily: kHeadingFontFamily,
  fontVariations: kHeadingWeight,
  fontSize: 14,
);

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.colorAccent,
          foregroundColor: AppTokens.colorBg,
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Text(label, style: _buttonTextStyle),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.colorText,
          side: BorderSide(color: AppTokens.colorDivider),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Text(label, style: _buttonTextStyle),
      ),
    );
  }
}

class GhostIconButton extends StatelessWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon),
        color: AppTokens.colorAccent,
        tooltip: semanticLabel,
        onPressed: onPressed,
      ),
    );
  }
}
