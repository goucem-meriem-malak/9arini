import 'package:flutter/material.dart';

/// Spacing scale (multiples of 4).
abstract final class Sp {
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32, xxxl = 48;
}

/// Radius scale: soft and very round, matching the glass reference.
abstract final class Rd {
  static const double s = 12, m = 16, l = 24, xl = 28, pill = 999;
}

abstract final class Mo {
  static const Duration tap = Duration(milliseconds: 150);
  static const Duration screen = Duration(milliseconds: 320);
  static const Curve curve = Cubic(0.16, 1, 0.3, 1);
}

extension ColorX on Color {
  Color o(double a) => withAlpha((a * 255).round());
}

class AppColors {
  const AppColors({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.primary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.hairline,
    required this.glass,
    required this.glassBorder,
    required this.hero,
    required this.button,
    required this.shadow,
  });

  final bool isDark;
  final Color bg, surface, surfaceAlt, text, muted, primary, accent, success, warning, error, hairline, glass, glassBorder;
  final List<Color> hero;
  final List<Color> button;
  final List<BoxShadow> shadow;

  static const Color onHero = Colors.white;

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFF2F8FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE6F0FD),
    text: Color(0xFF0F1B3D),
    muted: Color(0xFF58637F),
    primary: Color(0xFF2B55F0),
    accent: Color(0xFF05BAFF),
    success: Color(0xFF0B8A5F),
    warning: Color(0xFF9A5B00),
    error: Color(0xFFD92D20),
    hairline: Color(0x14000000),
    glass: Color(0xA3FFFFFF),
    glassBorder: Color(0xCCFFFFFF),
    hero: [Color(0xFF3A4DEB), Color(0xFF1B7CF0), Color(0xFF12A88A)],
    button: [Color(0xFF2B55F0), Color(0xFF1A6BEA)],
    shadow: [
      BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F0F1B3D), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8)),
    ],
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF0A1022),
    surface: Color(0xFF131B33),
    surfaceAlt: Color(0xFF1B2547),
    text: Color(0xFFEAF0FF),
    muted: Color(0xFF9AA6C7),
    primary: Color(0xFF7C9BFF),
    accent: Color(0xFF3CCBFF),
    success: Color(0xFF3DD6A0),
    warning: Color(0xFFF5B64A),
    error: Color(0xFFFF7A70),
    hairline: Color(0x14FFFFFF),
    glass: Color(0x8C131B33),
    glassBorder: Color(0x1FFFFFFF),
    hero: [Color(0xFF2A39B8), Color(0xFF1558B8), Color(0xFF0E7C69)],
    button: [Color(0xFF2B55F0), Color(0xFF1A6BEA)],
    shadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8)),
    ],
  );
}
