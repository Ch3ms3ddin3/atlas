import 'package:flutter/material.dart';

/// Palette Architectural — source unique des couleurs Atlas.
///
/// Contrastes vérifiés dans `test/design_system/atlas_contrast_test.dart` :
/// - `midnightBlue` sur `warmOffWhite` ≥ 7:1 (corps de texte)
/// - `midnightBlueMuted` sur `warmOffWhite` ≥ 4.5:1 (texte secondaire)
/// - `warmOffWhite` sur `terracotta` ≥ 3:1 (labels de bouton, texte large)
abstract final class AtlasColors {
  // --- Core ---

  /// Fond principal chaud — limestone plaster.
  static const Color warmOffWhite = Color(0xFFFAF7F2);

  /// Surfaces élevées — cartes sur le scaffold.
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Texte et structure — cedar shadow.
  static const Color midnightBlue = Color(0xFF1A2332);

  /// Accent principal — fired clay (max 2 éléments par écran).
  static const Color terracotta = Color(0xFFC4654A);

  /// Structure secondaire — bordures de cartes primaires.
  static const Color sand = Color(0xFFD9CDB8);

  /// Touches premium très discrètes.
  static const Color subtleGold = Color(0xFFC4A35A);

  // --- Structural ---

  static const Color sandMuted = Color(0xFFE8E0D4);
  static const Color terracottaMuted = Color(0xFFE8B5A5);
  /// Texte secondaire — légèrement renforcé pour la lisibilité WCAG AA.
  static const Color midnightBlueMuted = Color(0xFF4A5568);
  static const Color midnightBlueFaint = Color(0xFF6B7585);
  static const Color terracottaDeep = Color(0xFFA8503A);
  static const Color terracottaGhost = Color(0xFFF5E8E4);
  static const Color subtleGoldMuted = Color(0xFFF0E6CE);

  // --- Functional ---

  static const Color success = Color(0xFF3D6B5E);
  static const Color successMuted = Color(0xFFE8F0ED);
  static const Color warning = Color(0xFF9A7B2F);
  static const Color warningMuted = Color(0xFFF5F0E4);
  static const Color error = Color(0xFFB3261E);
  static const Color errorMuted = Color(0xFFF9DEDC);
  static const Color errorOnContainer = Color(0xFF410E0B);
  static const Color info = Color(0xFF4A6FA5);
  static const Color infoMuted = Color(0xFFE8EEF5);
}
