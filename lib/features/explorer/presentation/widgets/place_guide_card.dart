import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';
import 'place_cover_image.dart';
import 'place_display_helpers.dart';

/// Carte lieu premium — image dominante, infos scannables.
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
    final mediaHeight = compact ? 140.0 : 180.0;
    final duration = PlaceDisplayHelpers.visitDuration(place);
    final rating = PlaceDisplayHelpers.ratingLabel(place);

    return Semantics(
      button: true,
      label: '${place.name}, ${place.categoryLabel}, ${place.cityName}',
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
                  height: mediaHeight,
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
              padding: const EdgeInsets.all(AtlasSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    '${place.categoryLabel} · ${place.cityName}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    place.summary,
                    maxLines: compact ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AtlasTextStyles.helper(theme.colorScheme),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.md),
                  Wrap(
                    spacing: AtlasSpacing.md,
                    runSpacing: AtlasSpacing.xs,
                    children: [
                      _ChipMeta(
                        icon: Icons.payments_outlined,
                        label: place.priceLevel,
                      ),
                      _ChipMeta(
                        icon: Icons.schedule_outlined,
                        label: duration,
                      ),
                      _ChipMeta(
                        icon: Icons.star_rounded,
                        label: rating,
                        iconColor: AtlasColors.subtleGold,
                      ),
                      _ChipMeta(
                        icon: Icons.near_me_outlined,
                        label: PlaceDisplayHelpers.distanceLabel(place),
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

class _ChipMeta extends StatelessWidget {
  const _ChipMeta({
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
          size: 14,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AtlasSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
