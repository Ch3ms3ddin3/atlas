import 'package:flutter/material.dart';

/// Bouton primaire Atlas — hauteur et padding cohérents.
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
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (icon != null && !isLoading) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}

/// Bouton secondaire Atlas.
class AtlasSecondaryButton extends StatelessWidget {
  const AtlasSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
