import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../motion/atlas_haptics.dart';
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

/// Carte de base Atlas — papier premium, hover web, press elevation.
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

  /// Fade + scale à l'apparition — une seule fois au montage.
  final bool animateEntrance;
  final Duration entranceDelay;

  @override
  State<AtlasCard> createState() => _AtlasCardState();
}

class _AtlasCardState extends State<AtlasCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _entranceController;
  Animation<double>? _entranceOpacity;
  Animation<double>? _entranceScale;
  Timer? _entranceDelayTimer;
  bool _hovered = false;
  bool _pressed = false;

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
      _entranceScale = Tween<double>(
        begin: AtlasMotion.cardEnterScale,
        end: 1,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animateEntrance &&
        _entranceController != null &&
        AtlasMotion.reduceMotionOf(context)) {
      _entranceDelayTimer?.cancel();
      _entranceController!.value = 1;
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

  List<BoxShadow> get _shadows {
    if (_pressed) {
      return const [
        BoxShadow(
          color: Color(0x141A2332),
          blurRadius: 6,
          offset: Offset(0, 1),
        ),
      ];
    }
    if (_hovered) {
      return const [
        BoxShadow(
          color: Color(0x141A2332),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x0C1A2332),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (widget.emphasis) {
      AtlasCardEmphasis.primary => AtlasColors.sand.withValues(alpha: 0.55),
      _ => AtlasColors.sandMuted.withValues(alpha: 0.65),
    };

    Widget card = MouseRegion(
      onEnter: (_) {
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && widget.onTap != null ? AtlasMotion.pressScale : 1,
          duration: AtlasMotion.pressDuration,
          curve: AtlasMotion.curveDefault,
          child: AnimatedContainer(
            duration: AtlasMotion.hoverDuration,
            curve: AtlasMotion.curveDefault,
            decoration: BoxDecoration(
              color: AtlasColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: _shadows,
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
                        onTap: () {
                          AtlasHaptics.selection();
                          widget.onTap!();
                        },
                        child: Padding(
                          padding: widget.padding ?? _defaultPadding,
                          child: widget.child,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.animateEntrance &&
        _entranceOpacity != null &&
        _entranceScale != null &&
        !AtlasMotion.reduceMotionOf(context)) {
      card = FadeTransition(
        opacity: _entranceOpacity!,
        child: ScaleTransition(scale: _entranceScale!, child: card),
      );
    }

    return card;
  }
}
