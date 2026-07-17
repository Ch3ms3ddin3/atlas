import 'package:flutter/material.dart';

import '../motion/atlas_haptics.dart';
import '../theme/atlas_motion.dart';

/// Enveloppe pressable — scale 0.98 + haptic optionnel.
class AtlasPressable extends StatefulWidget {
  const AtlasPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.haptic = true,
    this.scale = AtlasMotion.pressScale,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool haptic;
  final double scale;

  @override
  State<AtlasPressable> createState() => _AtlasPressableState();
}

class _AtlasPressableState extends State<AtlasPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled && widget.onTap != null
          ? (_) => _setPressed(true)
          : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled && widget.onTap != null
            ? () {
                if (widget.haptic) {
                  AtlasHaptics.primaryAction();
                }
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: AtlasMotion.pressDuration,
          curve: AtlasMotion.curveDefault,
          child: widget.child,
        ),
      ),
    );
  }
}
