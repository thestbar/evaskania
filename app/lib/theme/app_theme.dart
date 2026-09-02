import 'package:flutter/material.dart';
import 'app_tokens.dart';

const String kHeadingFontFamily = 'Source Serif 4';

/// The semibold weight the CSS's `--font-heading-weight: 600` used —
/// applied via `fontVariations` since Source Serif 4 is bundled as a
/// single variable font, not separate per-weight files.
const List<FontVariation> kHeadingWeight = [FontVariation('wght', 600)];

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: kHeadingFontFamily,
      scaffoldBackgroundColor: AppTokens.colorBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.colorAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppTokens.colorAccent,
        secondary: AppTokens.colorAccent2,
        surface: AppTokens.colorSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.colorSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: AppTokens.colorDivider),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppTokens.colorText,
        displayColor: AppTokens.colorText,
        fontFamily: kHeadingFontFamily,
      ),
    );
  }
}
