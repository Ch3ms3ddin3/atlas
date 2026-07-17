import 'package:flutter/material.dart';

import '../theme/atlas_spacing.dart';

/// Placeholder de chargement — skeleton léger sans dépendance shimmer.
class AtlasSkeleton extends StatelessWidget {
  const AtlasSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = AtlasSpacing.sm,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.7);
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Carte skeleton pour listes (explorer, prix, démarches).
class AtlasSkeletonCard extends StatelessWidget {
  const AtlasSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AtlasSkeleton(height: 18, width: 180),
          SizedBox(height: AtlasSpacing.sm),
          AtlasSkeleton(height: 12),
          SizedBox(height: AtlasSpacing.xs),
          AtlasSkeleton(height: 12, width: 220),
        ],
      ),
    );
  }
}
