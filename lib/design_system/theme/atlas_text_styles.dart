import 'package:flutter/material.dart';

import 'atlas_colors.dart';

/// Couleurs de texte secondaire — contrastes solides (sans alpha dilué).
abstract final class AtlasTextStyles {
  /// Sous-titres, labels de section.
  static Color subtitle(ColorScheme scheme) => AtlasColors.midnightBlueMuted;

  /// Texte d'aide, descriptions courtes.
  static Color helper(ColorScheme scheme) => AtlasColors.midnightBlueMuted;

  /// Métadonnées, timestamps, notes de bas de carte.
  static Color metadata(ColorScheme scheme) => AtlasColors.midnightBlueFaint;

  /// Labels de carte (Météo, Prière…).
  static Color cardLabel(ColorScheme scheme) => AtlasColors.midnightBlueMuted;
}
