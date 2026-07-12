import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';
import '../theme/atlas_spacing.dart';

/// Niveau visuel d'une carte — hiérarchie sans ombre ni gradient.
enum AtlasCardEmphasis {
  /// Carte héro — météo, contenu principal du briefing.
  primary,

  /// Carte standard — contenu secondaire.
  standard,

  /// Carte compacte — informations tertiaires discrètes.
  compact,
}

/// Carte de base Atlas — bordure fine, coins arrondis, sans ombre.
class AtlasCard extends StatelessWidget {
  const AtlasCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.emphasis = AtlasCardEmphasis.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AtlasCardEmphasis emphasis;

  EdgeInsetsGeometry get _defaultPadding => switch (emphasis) {
        AtlasCardEmphasis.primary =>
          const EdgeInsets.all(AtlasSpacing.cardPaddingPrimary),
        AtlasCardEmphasis.standard =>
          const EdgeInsets.all(AtlasSpacing.cardPadding),
        AtlasCardEmphasis.compact =>
          const EdgeInsets.all(AtlasSpacing.cardPaddingCompact),
      };

  @override
  Widget build(BuildContext context) {
    final borderColor = emphasis == AtlasCardEmphasis.primary
        ? AtlasColors.sand
        : AtlasColors.sandMuted;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        side: BorderSide(
          color: borderColor,
          width: emphasis == AtlasCardEmphasis.primary ? 1 : 1,
        ),
      ),
      child: Padding(
        padding: padding ?? _defaultPadding,
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        child: card,
      ),
    );
  }
}
