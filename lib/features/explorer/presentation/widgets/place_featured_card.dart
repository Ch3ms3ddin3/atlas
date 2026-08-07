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
    final rating = PlaceDisplayHelpers.ratingLabel(place);

    return Semantics(
      button: true,
      label: 'Sélection Atlas, ${place.name}',
      child: AtlasCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PlaceCoverImage(
                  place: place,
                  height: 220,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AtlasSpacing.cardRadius),
                  ),
                ),
                Positioned(
                  top: AtlasSpacing.md,
                  left: AtlasSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.md,
                      vertical: AtlasSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AtlasColors.midnightBlue.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sélection Atlas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
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
                        icon: Icons.star_rounded,
                        label: rating,
                        iconColor: AtlasColors.subtleGold,
                      ),
                      _MetaItem(
                        icon: Icons.payments_outlined,
                        label: place.priceLevel,
                      ),
                    ],
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: AtlasSpacing.md),
                      Material(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FavoriteToggleButton(
                          entityType: FavoriteEntityType.place,
                          entitySlug: place.id,
                        ),
                      ),
                    ],
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
  const _MetaItem({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AtlasSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
