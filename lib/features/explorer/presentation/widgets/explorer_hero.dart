import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';

/// En-tête Explorer V2 — titre élégant et accroche éditoriale.
class ExplorerHero extends StatelessWidget {
  const ExplorerHero({super.key, this.onMapTap});

  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explorer',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.9,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                'Lieux utiles à Marrakech, Casablanca et Rabat — '
                'sélectionnés par Atlas.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AtlasTextStyles.helper(theme.colorScheme),
                  height: 1.4,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        if (onMapTap != null) ...[
          const SizedBox(width: AtlasSpacing.sm),
          IconButton(
            tooltip: 'Ouvrir la carte',
            onPressed: onMapTap,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ],
    );
  }
}
