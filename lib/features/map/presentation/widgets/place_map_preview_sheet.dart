import 'package:flutter/material.dart';

import '../../../../core/platform/atlas_external_links.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../explorer/domain/models/place_models.dart';
import '../../../explorer/presentation/pages/place_detail_page.dart';
import '../../../explorer/presentation/widgets/place_cover_image.dart';
import '../../../explorer/presentation/widgets/place_display_helpers.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';

/// Aperçu compact d'un lieu Atlas depuis un marqueur — reste sous la carte.
Future<void> showPlaceMapPreviewSheet(
  BuildContext context, {
  required PlaceGuide place,
}) {
  return showAtlasBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
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

  Future<void> _openItinerary(BuildContext context) async {
    final uri = place.hasCoordinates
        ? AtlasExternalLinks.mapsUri(
            latitude: place.latitude!,
            longitude: place.longitude!,
          )
        : (place.mapsUrl != null ? Uri.tryParse(place.mapsUrl!) : null);
    if (uri == null) {
      _showItineraryFailed(context);
      return;
    }
    final ok = await AtlasExternalLinks.open(uri);
    if (!ok && context.mounted) {
      _showItineraryFailed(context);
    }
  }

  void _showItineraryFailed(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'itinéraire pour ce lieu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openFullDetail(BuildContext context) {
    final favorites = FavoritesScope.read(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      AtlasPageRoute<void>(
        page: PlaceDetailPage(place: place, placeId: place.id),
        wrapPage: (child) => FavoritesScope(
          repository: favorites,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final district = PlaceDisplayHelpers.neighborhoodLabel(place);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AtlasSpacing.xl,
          AtlasSpacing.sm,
          AtlasSpacing.xl,
          AtlasSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
              child: PlaceCoverImage(
                place: place,
                height: 132,
                borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.25,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AtlasSpacing.xs),
                      Text(
                        '${place.categoryLabel} · $district · ${place.priceLevel}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FavoriteToggleButton(
                  entityType: FavoriteEntityType.place,
                  entitySlug: place.id,
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              place.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AtlasTextStyles.helper(theme.colorScheme),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openItinerary(context),
                    icon: const Icon(Icons.near_me_outlined, size: 18),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: AtlasSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openFullDetail(context),
                    child: const Text('Voir la fiche'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
