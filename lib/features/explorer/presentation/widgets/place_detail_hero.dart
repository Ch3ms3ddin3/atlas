import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';
import 'place_category_icon.dart';

/// Hero premium d'une fiche lieu — couleur éditoriale, meta et actions.
class PlaceDetailHero extends StatelessWidget {
  const PlaceDetailHero({
    super.key,
    required this.place,
    required this.onReport,
  });

  final PlaceGuide place;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: place.imageColor),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                placeCategoryIcon(place.category),
                size: 64,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            Positioned(
              top: AtlasSpacing.sm,
              right: AtlasSpacing.sm,
              child: Row(
                children: [
                  _HeroActionChip(
                    child: FavoriteToggleButton(
                      entityType: FavoriteEntityType.place,
                      entitySlug: place.id,
                    ),
                  ),
                  const SizedBox(width: AtlasSpacing.xs),
                  _HeroActionChip(
                    child: IconButton(
                      onPressed: onReport,
                      tooltip: 'Signaler un problème',
                      icon: const Icon(Icons.flag_outlined),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AtlasSpacing.lg,
              right: AtlasSpacing.lg,
              bottom: AtlasSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AtlasSpacing.sm,
                    runSpacing: AtlasSpacing.xs,
                    children: [
                      _HeroChip(label: place.categoryLabel),
                      _HeroChip(label: place.cityName),
                      if (place.isEditorsPick)
                        const _HeroChip(
                          label: 'Sélection Atlas',
                          emphasized: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    place.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    '${place.neighborhood} · ${place.priceLevel}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
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
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    this.emphasized = false,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.sm,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? AtlasColors.terracotta.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconTheme(
        data: const IconThemeData(color: Colors.white, size: 22),
        child: child,
      ),
    );
  }
}
