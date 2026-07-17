import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';
import '../theme/atlas_motion.dart';
import '../theme/atlas_spacing.dart';
import 'atlas_skeleton.dart';

/// Image réseau avec placeholder skeleton + fade-in.
class AtlasNetworkImage extends StatelessWidget {
  const AtlasNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(AtlasSpacing.cardRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return AnimatedOpacity(
              opacity: 1,
              duration: AtlasMotion.imageFadeDuration,
              curve: AtlasMotion.curveDefault,
              child: child,
            );
          }
          return const ColoredBox(
            color: AtlasColors.sandMuted,
            child: Center(
              child: AtlasSkeleton(height: double.infinity),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(
            color: AtlasColors.sandMuted,
            child: Center(
              child: SizedBox(
                width: 120,
                child: AtlasSkeleton(height: 12),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => ColoredBox(
          color: AtlasColors.sandMuted,
          child: Icon(
            Icons.broken_image_outlined,
            color: AtlasColors.midnightBlueFaint,
          ),
        ),
      ),
    );
  }
}
