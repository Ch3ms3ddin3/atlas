import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Utilitaires de contraste WCAG pour valider la palette Atlas.
abstract final class AtlasContrast {
  /// Ratio de contraste entre deux couleurs (1:1 à 21:1).
  static double ratio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double channel(double value) {
      // [Color.r]/[Color.g]/[Color.b] sont normalisés entre 0 et 1.
      if (value <= 0.03928) {
        return value / 12.92;
      }
      return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }
}
