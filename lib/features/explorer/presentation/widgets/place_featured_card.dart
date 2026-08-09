import 'package:flutter/material.dart';

import '../../../../core/platform/atlas_external_links.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';
import 'place_cover_image.dart';
import 'place_display_helpers.dart';

/// Carte mise en avant — sélection éditoriale Atlas.
class PlaceFeaturedCard extends StatelessWidget {
  const PlaceFeaturedCard({
    super.key,
    required this.place,
    required this.onTap,
    this.onDirectionsFailed,
  });

  final PlaceGuide place;
  final VoidCallback onTap;
  final VoidCallback? onDirectionsFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = PlaceDisplayHelpers.visitDuration(place);

    return Semantics(
      button: true,
      label: 'Sélection Atlas, ${place.name}',
      child: AtlasCard(
        onTap: onTap,
        emphasis: AtlasCardEmphasis.primary,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PlaceCoverImage(
                  place: place,
                  height: 228,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AtlasSpacing.cardRadius),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AtlasColors.midnightBlue.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AtlasSpacing.md,
                  left: AtlasSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.md,
                      vertical: AtlasSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AtlasColors.midnightBlue.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Sélection Atlas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AtlasSpacing.sm,
                  right: AtlasSpacing.sm,
                  child: Material(
                    color: AtlasColors.surfaceWhite.withValues(alpha: 0.94),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              padding: const EdgeInsets.fromLTRB(
                AtlasSpacing.lg,
                AtlasSpacing.lg,
                AtlasSpacing.lg,
                AtlasSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.45,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    '${place.categoryLabel} · ${place.neighborhood} · ${place.cityName}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AtlasSpacing.md),
                  Text(
                    place.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AtlasTextStyles.helper(theme.colorScheme),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  Wrap(
                    spacing: AtlasSpacing.lg,
                    runSpacing: AtlasSpacing.sm,
                    children: [
                      if (duration != null)
                        _MetaItem(
                          icon: Icons.schedule_outlined,
                          label: duration,
                        ),
                      if (place.hasBestTimeToVisit)
                        _MetaItem(
                          icon: Icons.wb_sunny_outlined,
                          label: place.bestTimeToVisit!,
                        ),
                      _MetaItem(
                        icon: Icons.payments_outlined,
                        label: place.priceLevel,
                      ),
                      _MetaItem(
                        icon: Icons.place_outlined,
                        label: PlaceDisplayHelpers.neighborhoodLabel(place),
                      ),
                    ],
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = place.hasCoordinates
                            ? AtlasExternalLinks.mapsUri(
                                latitude: place.latitude!,
                                longitude: place.longitude!,
                              )
                            : (place.mapsUrl != null
                                  ? Uri.tryParse(place.mapsUrl!)
                                  : null);
                        if (uri == null) {
                          onDirectionsFailed?.call();
                          return;
                        }
                        final ok = await AtlasExternalLinks.open(uri);
                        if (!ok) onDirectionsFailed?.call();
                      },
                      icon: const Icon(Icons.near_me_outlined, size: 18),
                      label: const Text('Itinéraire'),
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AtlasSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}
