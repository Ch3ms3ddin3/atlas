import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_network_image.dart';
import 'place_detail_section.dart';

/// Galerie d'images — uniquement si des URLs réelles sont fournies.
class PlaceGallerySection extends StatelessWidget {
  const PlaceGallerySection({
    super.key,
    required this.imageUrls,
  });

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceDetailSectionHeader(title: 'Galerie'),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: AtlasSpacing.md),
            itemBuilder: (context, index) {
              final url = imageUrls[index];
              return AspectRatio(
                aspectRatio: 4 / 3,
                child: AtlasNetworkImage(url: url),
              );
            },
          ),
        ),
      ],
    );
  }
}
