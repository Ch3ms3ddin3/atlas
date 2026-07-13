import 'package:flutter/animation.dart';

/// Durées et courbes de mouvement Atlas — calme, sans rebond.
abstract final class AtlasMotion {
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationStandard = Duration(milliseconds: 250);
  static const Duration durationEmphasis = Duration(milliseconds: 400);
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Transitions d'onglet et de page (220–260ms).
  static const Duration pageTransitionDuration = Duration(milliseconds: 240);

  /// Barre de navigation — sélection et pill.
  static const Duration navAnimationDuration = Duration(milliseconds: 240);

  /// Entrée des sections et cartes.
  static const Duration revealDuration = Duration(milliseconds: 240);
  static const double revealOffset = 8;

  /// Micro-scale de l'icône active dans la barre de navigation.
  static const double navIconActiveScale = 1.08;

  /// Décélération douce — `cubic-bezier(0, 0, 0.2, 1)`.
  static const Curve curveDefault = Curves.easeOutCubic;

  static const Curve curveEnter = Curves.easeOutCubic;

  /// Accélération à la sortie — `cubic-bezier(0.4, 0, 1, 1)`.
  static const Curve curveExit = Curves.easeInCubic;
}
