import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_network_image.dart';
import '../../domain/models/place_models.dart';
import 'place_category_icon.dart';

/// Visuel principal d'un lieu — image primaire (`imageUrls.first`) ou fallback.
///
/// Utilisé par les cartes Explorer et le hero détail pour un comportement unique
/// (chargement, erreur, absence d'URL).
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

    final primaryUrl = place.primaryImageUrl;
    if (primaryUrl == null) {
      return fallback;
    }

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
}

/// Fallback éditorial — couleur lieu + icône catégorie.
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

    return Container(
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
    );
  }
}
