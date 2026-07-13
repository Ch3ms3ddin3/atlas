import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';

/// Bannière discrète pour les entrées identifiées comme pièges touristiques.
class PriceTouristTrapBanner extends StatelessWidget {
  const PriceTouristTrapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: AtlasSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 16,
            color: theme.colorScheme.error.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Text(
            'Piège touristique',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
