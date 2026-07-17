import 'package:flutter/widgets.dart';

/// Durées et courbes de mouvement Atlas — calme, premium, sans rebond excessif.
abstract final class AtlasMotion {
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationStandard = Duration(milliseconds: 250);
  static const Duration durationEmphasis = Duration(milliseconds: 400);
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Respecte « Réduire les animations » (OS / accessibilité).
  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Renvoie [Duration.zero] si les animations sont désactivées.
  static Duration resolve(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }

  /// Transitions d'onglet et de page (220–260ms).
  static const Duration pageTransitionDuration = Duration(milliseconds: 240);

  /// Barre de navigation — sélection et pill.
  static const Duration navAnimationDuration = Duration(milliseconds: 240);

  /// Entrée des sections et cartes.
  static const Duration revealDuration = Duration(milliseconds: 240);
  static const double revealOffset = 8;

  /// Dialogues — fade + scale.
  static const Duration dialogDuration = Duration(milliseconds: 220);

  /// Bottom sheets — entrée type ressort adouci.
  static const Duration sheetDuration = Duration(milliseconds: 320);
  static const Duration sheetReverseDuration = Duration(milliseconds: 240);

  /// Survol / press micro-interactions.
  static const Duration pressDuration = Duration(milliseconds: 120);
  static const Duration hoverDuration = Duration(milliseconds: 180);

  /// Fade loading → contenu.
  static const Duration contentSwapDuration = Duration(milliseconds: 220);

  /// Images — fade-in après chargement.
  static const Duration imageFadeDuration = Duration(milliseconds: 280);

  /// Micro-scale de l'icône active dans la barre de navigation.
  static const double navIconActiveScale = 1.08;

  /// Press boutons / cartes.
  static const double pressScale = 0.98;

  /// Entrée carte (fade + scale).
  static const double cardEnterScale = 0.97;

  /// Décélération douce — `cubic-bezier(0, 0, 0.2, 1)`.
  static const Curve curveDefault = Curves.easeOutCubic;

  static const Curve curveEnter = Curves.easeOutCubic;

  /// Accélération à la sortie — `cubic-bezier(0.4, 0, 1, 1)`.
  static const Curve curveExit = Curves.easeInCubic;

  /// Ressort adouci pour sheets (léger overshoot).
  static const Curve curveSpring = Curves.easeOutBack;
}
