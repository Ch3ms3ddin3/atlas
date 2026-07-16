import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';

/// Carte lieu premium — découverte scannable, favori intégré.
class PlaceGuideCard extends StatelessWidget {
  const PlaceGuideCard({
    super.key,
    required this.place,
    required this.onTap,
    this.compact = false,
  });

  final PlaceGuide place;
  final VoidCallback onTap;

  /// Variante grille (web / tablette).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaHeight = compact ? 96.0 : 112.0;

    return Semantics(
      button: true,
      label: '${place.name}, ${place.categoryLabel}, ${place.neighborhood}',
      child: AtlasCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: mediaHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: place.imageColor.withValues(alpha: 0.88),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AtlasSpacing.cardRadius),
                    ),
                  ),
                  child: Icon(
                    _categoryIcon(place.category),
                    size: compact ? 32 : 40,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
                if (place.isEditorsPick)
                  Positioned(
                    top: AtlasSpacing.md,
                    left: AtlasSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AtlasSpacing.sm,
                        vertical: AtlasSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AtlasColors.midnightBlue.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sélection',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: AtlasSpacing.xs,
                  right: AtlasSpacing.xs,
                  child: Material(
                    color: AtlasColors.surfaceWhite.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: FavoriteToggleButton(
                      entityType: FavoriteEntityType.place,
                      entitySlug: place.id,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AtlasSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    maxLines: compact ? 2 : 2,
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
          ],
        ),
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
