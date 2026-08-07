import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_network_image.dart';
import '../../domain/models/place_models.dart';
import 'place_category_icon.dart';

/// Visuel principal d'un lieu — image réseau ou placeholder coloré.
class PlaceCoverImage extends StatelessWidget {
  const PlaceCoverImage({
    super.key,
    required this.place,
    required this.height,
    this.borderRadius,
  });

  final PlaceGuide place;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        const BorderRadius.vertical(
          top: Radius.circular(AtlasSpacing.cardRadius),
        );

    if (place.imageUrls.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: AtlasNetworkImage(
          url: place.imageUrls.first,
          borderRadius: radius,
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: place.imageColor.withValues(alpha: 0.92),
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          placeCategoryIcon(place.category),
          size: height * 0.28,
          color: Colors.white.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
