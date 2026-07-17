import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_reveal.dart';
import '../../../explorer/domain/models/place_models.dart';
import '../../../explorer/presentation/pages/place_detail_page.dart';
import '../../../favorites/presentation/favorites_page_wrapper.dart';

/// Aperçu compact — ouvre le Place Details existant.
Future<void> showPlaceMapPreviewSheet(
  BuildContext context, {
  required PlaceGuide place,
}) {
  return showAtlasBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return PlaceMapPreviewSheet(place: place);
    },
  );
}

class PlaceMapPreviewSheet extends StatelessWidget {
  const PlaceMapPreviewSheet({
    super.key,
    required this.place,
  });

  final PlaceGuide place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.xl,
          AtlasSpacing.sm,
          AtlasSpacing.xl,
          AtlasSpacing.xxl,
        ),
        child: AtlasReveal(
          child: AtlasCard(
            animateEntrance: true,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                AtlasPageRoute<void>(
                  page: PlaceDetailPage(place: place, placeId: place.id),
                  wrapPage: (child) => wrapWithFavoritesScope(context, child),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: place.imageColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.sm),
                    Expanded(
                      child: Text(
                        place.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  '${place.categoryLabel} · ${place.neighborhood} · ${place.cityName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.md),
                Text(
                  place.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: AtlasSpacing.md),
                Text(
                  'Voir la fiche complète',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
