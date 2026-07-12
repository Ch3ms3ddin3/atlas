import 'package:flutter/material.dart';

/// Palette Marrakech / désert — source unique des couleurs Atlas.
abstract final class AtlasColors {
  /// Fond principal chaud, proche du blanc cassé.
  static const Color warmOffWhite = Color(0xFFFAF7F2);

  /// Accent principal terracotta.
  static const Color terracotta = Color(0xFFC4654A);

  /// Accent secondaire sable.
  static const Color sand = Color(0xFFD9CDB8);

  /// Texte et éléments importants — bleu nuit profond.
  static const Color midnightBlue = Color(0xFF1A2332);

  /// Or réservé aux touches premium très discrètes.
  static const Color subtleGold = Color(0xFFC4A35A);

  /// Variantes utiles pour les états et séparateurs.
  static const Color sandMuted = Color(0xFFE8E0D4);
  static const Color terracottaMuted = Color(0xFFE8B5A5);
  static const Color midnightBlueMuted = Color(0xFF5A6472);
}
