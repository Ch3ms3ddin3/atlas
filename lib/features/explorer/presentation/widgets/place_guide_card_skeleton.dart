import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';

/// Skeleton carte lieu — image + texte, sans saut de layout.
class PlaceGuideCardSkeleton extends StatelessWidget {
  const PlaceGuideCardSkeleton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageHeight = compact ? 140.0 : 180.0;

    return AtlasCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasSkeleton(
            height: imageHeight,
            borderRadius: AtlasSpacing.cardRadius,
          ),
          Padding(
            padding: const EdgeInsets.all(AtlasSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AtlasSkeleton(height: 18, width: 200),
                const SizedBox(height: AtlasSpacing.sm),
                const AtlasSkeleton(height: 12, width: 120),
                const SizedBox(height: AtlasSpacing.md),
                const AtlasSkeleton(height: 12),
                const SizedBox(height: AtlasSpacing.xs),
                const AtlasSkeleton(height: 12, width: 240),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
