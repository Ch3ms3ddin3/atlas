import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';
import '../theme/atlas_motion.dart';
import '../theme/atlas_spacing.dart';

/// Niveau visuel d'une carte — hiérarchie avec relief papier discret.
enum AtlasCardEmphasis {
  /// Carte héro — météo, contenu principal du briefing.
  primary,

  /// Carte standard — contenu secondaire.
  standard,

  /// Carte compacte — informations tertiaires discrètes.
  compact,
}

/// Carte de base Atlas — papier premium, ombre légère, bordure adoucie.
class AtlasCard extends StatefulWidget {
  const AtlasCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.emphasis = AtlasCardEmphasis.standard,
    this.animateEntrance = false,
    this.entranceDelay = Duration.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final AtlasCardEmphasis emphasis;

  /// Fade + translateY à l'apparition — une seule fois au montage.
  final bool animateEntrance;
  final Duration entranceDelay;

  @override
  State<AtlasCard> createState() => _AtlasCardState();
}

class _AtlasCardState extends State<AtlasCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _entranceController;
  Animation<double>? _entranceOpacity;
  Animation<Offset>? _entranceSlide;
  Timer? _entranceDelayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.animateEntrance) {
      _entranceController = AnimationController(
        vsync: this,
        duration: AtlasMotion.revealDuration,
      );
      final curve = CurvedAnimation(
        parent: _entranceController!,
        curve: AtlasMotion.curveDefault,
      );
      _entranceOpacity = curve;
      _entranceSlide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curve);

      if (widget.entranceDelay == Duration.zero) {
        _entranceController!.forward();
      } else {
        _entranceDelayTimer = Timer(widget.entranceDelay, () {
          if (mounted) _entranceController!.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _entranceDelayTimer?.cancel();
    _entranceController?.dispose();
    super.dispose();
  }

  EdgeInsetsGeometry get _defaultPadding => switch (widget.emphasis) {
        AtlasCardEmphasis.primary =>
          const EdgeInsets.all(AtlasSpacing.cardPaddingPrimary),
        AtlasCardEmphasis.standard =>
          const EdgeInsets.all(AtlasSpacing.cardPadding),
        AtlasCardEmphasis.compact =>
          const EdgeInsets.all(AtlasSpacing.cardPaddingCompact),
      };

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (widget.emphasis) {
      AtlasCardEmphasis.primary => AtlasColors.sand.withValues(alpha: 0.55),
      _ => AtlasColors.sandMuted.withValues(alpha: 0.65),
    };

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: AtlasColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A2332),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x051A2332),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        child: Material(
          color: Colors.transparent,
          child: widget.onTap == null
              ? Padding(
                  padding: widget.padding ?? _defaultPadding,
                  child: widget.child,
                )
              : InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: widget.padding ?? _defaultPadding,
                    child: widget.child,
                  ),
                ),
        ),
      ),
    );

    if (widget.animateEntrance &&
        _entranceOpacity != null &&
        _entranceSlide != null) {
      card = FadeTransition(
        opacity: _entranceOpacity!,
        child: SlideTransition(position: _entranceSlide!, child: card),
      );
    }

    return card;
  }
}
