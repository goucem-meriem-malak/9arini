import 'dart:ui' show FontVariation;
import 'package:flutter/material.dart';
import 'tokens.dart';

FontWeight _fw(int w) => FontWeight.values[(w ~/ 100) - 1];

ThemeData buildTheme(Brightness b, Locale locale) {
  final c = b == Brightness.dark ? AppColors.dark : AppColors.light;
  final ar = locale.languageCode == 'ar';
  final family = ar ? 'Cairo' : 'PlusJakartaSans';
  final fallback = [ar ? 'PlusJakartaSans' : 'Cairo'];

  TextStyle ts(double size, int w, {double track = 0, double h = 1.4, Color? color}) => TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: _fw(w),
        fontVariations: [FontVariation('wght', w.toDouble())],
        // Tracking is only applied to Latin text; it breaks Arabic letter joining.
        letterSpacing: ar ? 0 : size * track,
        height: ar ? h + 0.1 : h,
        color: color ?? c.text,
      );

  final text = TextTheme(
    headlineLarge: ts(28, 700, track: -0.03, h: 1.15),
    headlineMedium: ts(22, 700, track: -0.025, h: 1.2),
    titleLarge: ts(18, 600, track: -0.02, h: 1.25),
    titleMedium: ts(16, 600, track: -0.01),
    bodyLarge: ts(16, 400, h: 1.5),
    bodyMedium: ts(14, 400, h: 1.45),
    bodySmall: ts(12, 400, color: c.muted),
    labelLarge: ts(14, 600),
    labelMedium: ts(12, 600),
  );

  final scheme = ColorScheme.fromSeed(seedColor: c.primary, brightness: b).copyWith(
    primary: c.primary,
    onPrimary: c.isDark ? const Color(0xFF0A1022) : Colors.white,
    surface: c.surface,
    onSurface: c.text,
    error: c.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: family,
    fontFamilyFallback: fallback,
    textTheme: text,
    dividerColor: c.hairline,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: c.text,
      titleTextStyle: text.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.isDark ? c.surfaceAlt : c.text,
      contentTextStyle: ts(14, 500, color: c.isDark ? c.text : c.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rd.m)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rd.xl))),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rd.l)),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary),
  );
}

/// Digits that line up in prices, counters and dates.
const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];
