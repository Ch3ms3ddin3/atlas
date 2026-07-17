import 'package:flutter/material.dart';

import '../motion/atlas_haptics.dart';
import '../theme/atlas_motion.dart';

/// Bouton primaire Atlas — filled + press scale + haptic.
class AtlasPrimaryButton extends StatelessWidget {
  const AtlasPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final button = icon != null && !isLoading
        ? FilledButton.icon(
            onPressed: enabled
                ? () {
                    AtlasHaptics.primaryAction();
                    onPressed!();
                  }
                : null,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : FilledButton(
            onPressed: enabled
                ? () {
                    AtlasHaptics.primaryAction();
                    onPressed!();
                  }
                : null,
            child: child,
          );

    return _PressScale(enabled: enabled, child: button);
  }
}

/// Bouton secondaire Atlas — outlined.
class AtlasSecondaryButton extends StatelessWidget {
  const AtlasSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: enabled
                ? () {
                    AtlasHaptics.selection();
                    onPressed!();
                  }
                : null,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton(
            onPressed: enabled
                ? () {
                    AtlasHaptics.selection();
                    onPressed!();
                  }
                : null,
            child: Text(label),
          );

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.55,
      duration: AtlasMotion.pressDuration,
      child: _PressScale(enabled: enabled, child: button),
    );
  }
}

/// Bouton tertiaire Atlas — text only.
class AtlasTertiaryButton extends StatelessWidget {
  const AtlasTertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = icon != null
        ? TextButton.icon(
            onPressed: enabled
                ? () {
                    AtlasHaptics.selection();
                    onPressed!();
                  }
                : null,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : TextButton(
            onPressed: enabled
                ? () {
                    AtlasHaptics.selection();
                    onPressed!();
                  }
                : null,
            child: Text(label),
          );

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.55,
      duration: AtlasMotion.pressDuration,
      child: _PressScale(enabled: enabled, child: button),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AtlasMotion.pressScale : 1,
        duration: AtlasMotion.pressDuration,
        curve: AtlasMotion.curveDefault,
        child: widget.child,
      ),
    );
  }
}
