import 'package:flutter/material.dart';

/// Design tokens ported from the Broadsheet design system used by the
/// original web mockup (`_ds/broadsheet-.../styles.css` at the repo root).
/// Keep both in sync if the mockup's tokens ever change.
class AppTokens {
  AppTokens._();

  // Colors
  static const Color colorBg = Color(0xFFF3F2F2);
  static const Color colorSurface = Color(0xFFEAE9E9);
  static const Color colorText = Color(0xFF201E1D);
  static const Color colorAccent = Color(0xFF0088B0);
  static const Color colorAccent2 = Color(0xFFD6006C);
  static Color get colorDivider => colorText.withValues(alpha: 0.16);

  static const Color accent100 = Color(0xFFE9F8FF);
  static const Color accent700 = Color(0xFF006786);

  static const Color accent2_100 = Color(0xFFFFF1F4);
  static const Color accent2_700 = Color(0xFFAA0B56);
  static const Color accent2_800 = Color(0xFF790E3D);

  // Spacing (space-1..space-8 from the CSS scale, in logical pixels)
  static const double space1 = 5;
  static const double space2 = 10;
  static const double space3 = 15;
  static const double space4 = 20;
  static const double space6 = 30;
  static const double space8 = 40;

  // Radius
  static const double radiusSm = 1;
  static const double radiusMd = 2;
  static const double radiusLg = 4;
}
