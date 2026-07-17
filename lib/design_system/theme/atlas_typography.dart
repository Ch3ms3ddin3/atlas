import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'atlas_colors.dart';

/// Échelle typographique Inter — alignée sur docs/BRAND.md.
abstract final class AtlasTypography {
  static TextTheme textTheme({Color? color}) {
    final base = color ?? AtlasColors.midnightBlue;

    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      double letterSpacing = 0,
    }) {
      return GoogleFonts.inter(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: base,
      );
    }

    return TextTheme(
      displayLarge: style(size: 40, height: 44, weight: FontWeight.w300, letterSpacing: -1.5),
      displayMedium: style(size: 32, height: 36, weight: FontWeight.w300, letterSpacing: -1.2),
      displaySmall: style(size: 32, height: 36, weight: FontWeight.w300, letterSpacing: -1.2),
      headlineLarge: style(size: 24, height: 28, weight: FontWeight.w600, letterSpacing: -0.3),
      headlineMedium: style(size: 20, height: 24, weight: FontWeight.w600, letterSpacing: -0.2),
      headlineSmall: style(size: 18, height: 22, weight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: style(size: 18, height: 22, weight: FontWeight.w600),
      titleMedium: style(size: 16, height: 20, weight: FontWeight.w500),
      titleSmall: style(size: 14, height: 18, weight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: style(size: 16, height: 22, weight: FontWeight.w400),
      bodyMedium: style(size: 14, height: 19, weight: FontWeight.w400),
      bodySmall: style(size: 12, height: 16, weight: FontWeight.w400, letterSpacing: 0.1),
      labelLarge: style(size: 14, height: 18, weight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: style(size: 12, height: 16, weight: FontWeight.w500, letterSpacing: 0.3),
      labelSmall: style(size: 11, height: 14, weight: FontWeight.w400, letterSpacing: 0.2),
    );
  }
}
