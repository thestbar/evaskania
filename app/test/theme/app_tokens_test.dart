import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/theme/app_tokens.dart';

void main() {
  test('colors match the Broadsheet design tokens', () {
    expect(AppTokens.colorBg, const Color(0xFFF3F2F2));
    expect(AppTokens.colorText, const Color(0xFF201E1D));
    expect(AppTokens.colorAccent, const Color(0xFF0088B0));
    expect(AppTokens.colorAccent2, const Color(0xFFD6006C));
  });

  test('spacing scale matches the CSS --space-* values', () {
    expect(AppTokens.space1, 5);
    expect(AppTokens.space2, 10);
    expect(AppTokens.space3, 15);
    expect(AppTokens.space4, 20);
    expect(AppTokens.space8, 40);
  });

  test('colorDivider is the text color at 16% opacity', () {
    final divider = AppTokens.colorDivider;
    expect(divider.toARGB32() & 0x00FFFFFF, 0x00201E1D);
    expect((divider.a * 255).round(), 41); // 16% of 255, rounded
  });
}
