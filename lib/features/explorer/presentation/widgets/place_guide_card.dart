import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/place_models.dart';

/// Carte pleine largeur d'un lieu dans la liste Explorer.
class PlaceGuideCard extends StatelessWidget {
  const PlaceGuideCard({
    super.key,
    required this.place,
    required this.onTap,
  });

  final PlaceGuide place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: place.imageColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(place.category),
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  '${place.categoryLabel} · ${place.priceLevel}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  place.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  place.neighborhood,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(PlaceCategory category) {
    return switch (category) {
      PlaceCategory.jardin => Icons.park_outlined,
      PlaceCategory.monument => Icons.account_balance_outlined,
      PlaceCategory.restaurant => Icons.restaurant_outlined,
      PlaceCategory.cafe => Icons.coffee_outlined,
      PlaceCategory.musee => Icons.museum_outlined,
      PlaceCategory.hammam => Icons.spa_outlined,
      PlaceCategory.plage => Icons.beach_access_outlined,
      PlaceCategory.souk => Icons.storefront_outlined,
    };
  }
}
