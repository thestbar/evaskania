import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.children, this.onTap});

  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: AppTokens.colorSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: content,
    );
  }
}

class CardKicker extends StatelessWidget {
  const CardKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: AppTokens.colorAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.fontSize = 17});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kHeadingFontFamily,
          fontVariations: kHeadingWeight,
          fontSize: fontSize,
          height: 1.2,
          color: AppTokens.colorText,
        ),
      ),
    );
  }
}

class CardBody extends StatelessWidget {
  const CardBody(this.text, {super.key, this.italic = false, this.fontSize = 13});
  final String text;
  final bool italic;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.8,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.4,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: AppTokens.colorText,
          ),
        ),
      ),
    );
  }
}

class CardMeta extends StatelessWidget {
  const CardMeta(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, color: AppTokens.colorText.withValues(alpha: 0.5));
    if (icon == null) return Text(text, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTokens.colorText.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(text, style: style),
      ],
    );
  }
}
