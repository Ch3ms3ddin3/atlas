import 'package:flutter/material.dart';

/// Couleurs de texte secondaire — lisibilité renforcée sans assombrir la palette.
abstract final class AtlasTextStyles {
  /// Sous-titres, labels de section.
  static Color subtitle(ColorScheme scheme) =>
      scheme.onSurfaceVariant.withValues(alpha: 0.78);

  /// Texte d'aide, descriptions courtes.
  static Color helper(ColorScheme scheme) =>
      scheme.onSurfaceVariant.withValues(alpha: 0.72);

  /// Métadonnées, timestamps, notes de bas de carte.
  static Color metadata(ColorScheme scheme) =>
      scheme.onSurfaceVariant.withValues(alpha: 0.68);

  /// Labels de carte (Météo, Prière…).
  static Color cardLabel(ColorScheme scheme) =>
      scheme.onSurfaceVariant.withValues(alpha: 0.74);
}
