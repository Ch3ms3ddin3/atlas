import 'package:flutter/material.dart';

import '../motion/atlas_haptics.dart';
import '../theme/atlas_motion.dart';

/// Puce de filtre Atlas — sélection animée + haptic.
class AtlasFilterChip extends StatelessWidget {
  const AtlasFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: isSelected ? 1.03 : 1,
      duration: AtlasMotion.navAnimationDuration,
      curve: AtlasMotion.curveDefault,
      child: FilterChip(
        label: AnimatedDefaultTextStyle(
          duration: AtlasMotion.navAnimationDuration,
          curve: AtlasMotion.curveDefault,
          style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          child: Text(label),
        ),
        selected: isSelected,
        onSelected: (_) {
          AtlasHaptics.selection();
          onTap();
        },
        showCheckmark: false,
        selectedColor: theme.colorScheme.primaryContainer,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
