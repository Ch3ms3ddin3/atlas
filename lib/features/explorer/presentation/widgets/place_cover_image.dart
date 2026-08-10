import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_network_image.dart';
import '../../data/place_cover_assets.dart';
import '../../domain/models/place_models.dart';
import 'place_category_icon.dart';

/// Visuel principal d'un lieu — asset vérifié, URL distante, ou fallback honnête.
///
/// Priorité : cover bundle vérifié → `imageUrls` remote → fallback catégorie.
/// Les covers locaux expédiés (ex. Jemaa / YSL / hammam) gagnent toujours sur
/// une URL Storage distante, pour éviter d'afficher d'anciennes photos cloud.
/// Jamais d'image géographiquement ou thématiquement non liée.
class PlaceCoverImage extends StatelessWidget {
  const PlaceCoverImage({
    super.key,
    required this.place,
    required this.height,
    this.borderRadius,
    this.fallbackColorOpacity = 0.92,
    this.fallbackIconOpacity = 0.40,
    this.fallbackIconSize,
  });

  final PlaceGuide place;
  final double height;
  final BorderRadius? borderRadius;

  /// Opacité du fond couleur en fallback (cartes : 0.92, hero : 1.0).
  final double fallbackColorOpacity;

  /// Opacité de l'icône catégorie en fallback.
  final double fallbackIconOpacity;

  /// Taille d'icône forcée — sinon dérivée de [height].
  final double? fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ??
        const BorderRadius.vertical(
          top: Radius.circular(AtlasSpacing.cardRadius),
        );

    final fallback = PlaceImageFallback(
      place: place,
      height: height,
      borderRadius: radius,
      colorOpacity: fallbackColorOpacity,
      iconOpacity: fallbackIconOpacity,
      iconSize: fallbackIconSize,
    );

    final assetPath = PlaceCoverAssets.assetPathFor(place.id);
    if (assetPath != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ],
          ),
        ),
      );
    }

    final primaryUrl = place.primaryImageUrl;
    if (primaryUrl != null) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final cacheHeight = (height * dpr).round().clamp(1, 2048);

      return SizedBox(
        height: height,
        width: double.infinity,
        child: AtlasNetworkImage(
          url: primaryUrl,
          borderRadius: radius,
          placeholder: fallback,
          errorWidget: fallback,
          memCacheHeight: cacheHeight,
        ),
      );
    }

    return fallback;
  }
}

/// Fallback éditorial intentionnel — couleur lieu + icône catégorie.
///
/// Utilisé quand aucune photo vérifiée (remote ou bundle) n'est disponible.
class PlaceImageFallback extends StatelessWidget {
  const PlaceImageFallback({
    super.key,
    required this.place,
    required this.height,
    this.borderRadius,
    this.colorOpacity = 0.92,
    this.iconOpacity = 0.40,
    this.iconSize,
  });

  final PlaceGuide place;
  final double height;
  final BorderRadius? borderRadius;
  final double colorOpacity;
  final double iconOpacity;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ??
        const BorderRadius.vertical(
          top: Radius.circular(AtlasSpacing.cardRadius),
        );
    final resolvedIconSize = iconSize ?? (height * 0.34).clamp(40.0, 64.0);

    return Semantics(
      label: 'Photo non disponible pour ${place.name}',
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: place.imageColor.withValues(alpha: colorOpacity),
          borderRadius: radius,
        ),
        child: Center(
          child: Icon(
            placeCategoryIcon(place.category),
            size: resolvedIconSize,
            color: Colors.white.withValues(alpha: iconOpacity),
          ),
        ),
      ),
    );
  }
}
