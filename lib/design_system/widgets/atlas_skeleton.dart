import 'package:flutter/material.dart';

import '../theme/atlas_colors.dart';
import '../theme/atlas_motion.dart';
import '../theme/atlas_spacing.dart';

/// Placeholder de chargement — pulse discret sans dépendance shimmer.
class AtlasSkeleton extends StatefulWidget {
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
  State<AtlasSkeleton> createState() => _AtlasSkeletonState();
}

class _AtlasSkeletonState extends State<AtlasSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _opacity = Tween<double>(begin: 0.45, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: AtlasMotion.curveDefault),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AtlasMotion.reduceMotionOf(context)) {
      _controller.stop();
      _controller.value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.75);
    final box = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
    if (AtlasMotion.reduceMotionOf(context)) {
      return Opacity(opacity: 0.7, child: box);
    }
    return FadeTransition(opacity: _opacity, child: box);
  }
}

/// Carte skeleton pour listes (explorer, prix, démarches).
class AtlasSkeletonCard extends StatelessWidget {
  const AtlasSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AtlasSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

/// Fond skeleton coloré (images).
class AtlasSkeletonBlock extends StatelessWidget {
  const AtlasSkeletonBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AtlasColors.sandMuted,
      child: Center(
        child: SizedBox(
          width: 96,
          child: AtlasSkeleton(height: 10),
        ),
      ),
    );
  }
}
