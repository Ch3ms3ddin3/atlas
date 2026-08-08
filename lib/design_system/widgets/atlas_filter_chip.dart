import 'package:flutter/material.dart';

import '../motion/atlas_haptics.dart';
import '../theme/atlas_motion.dart';
import '../theme/atlas_spacing.dart';

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

    return FilterChip(
      label: AnimatedDefaultTextStyle(
        duration: AtlasMotion.contentSwapDuration,
        curve: AtlasMotion.curveDefault,
        style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: -0.1,
          height: 1.1,
        ),
        child: Text(label, softWrap: false, overflow: TextOverflow.visible),
      ),
      selected: isSelected,
      onSelected: (_) {
        AtlasHaptics.selection();
        onTap();
      },
      showCheckmark: false,
      // Empêche Material d’ellipser le libellé dans une rangée scrollable.
      labelPadding: const EdgeInsets.symmetric(horizontal: AtlasSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.sm,
        vertical: AtlasSpacing.sm,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      selectedColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.4)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.85),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
