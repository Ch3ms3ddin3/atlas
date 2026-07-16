import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';

/// Carte de lieu recommandé — découverte locale curatée.
class RecommendedPlacesCard extends StatelessWidget {
  const RecommendedPlacesCard({
    super.key,
    required this.place,
    this.onTap,
  });

  final RecommendedPlaceData place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardWidth = 220.0;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
          side: const BorderSide(color: AtlasColors.sandMuted),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 112,
                    width: double.infinity,
                    color: place.imageColor.withValues(alpha: 0.85),
                    child: Icon(
                      _categoryIcon(place.category),
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.45),
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
                      '${place.category} · ${place.priceLevel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.xs),
                    Text(
                      place.distanceLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'café' => Icons.coffee_outlined,
      'restaurant' => Icons.restaurant_outlined,
      'musée' => Icons.museum_outlined,
      'jardin' => Icons.park_outlined,
      'monument' => Icons.account_balance_outlined,
      'hammam' => Icons.spa_outlined,
      _ => Icons.place_outlined,
    };
  }
}

/// Liste horizontale de lieux recommandés.
class RecommendedPlacesSection extends StatelessWidget {
  const RecommendedPlacesSection({
    super.key,
    required this.places,
    this.onPlaceTap,
  });

  final List<RecommendedPlaceData> places;
  final ValueChanged<RecommendedPlaceData>? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(width: AtlasSpacing.lg),
        itemBuilder: (context, index) {
          final place = places[index];
          return RecommendedPlacesCard(
            place: place,
            onTap: () => onPlaceTap?.call(place),
          );
        },
      ),
    );
  }
}
