import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';
import 'place_cover_image.dart';

/// Hero immersif d'une fiche lieu — image primaire, retour, favori, meta.
class PlaceDetailHero extends StatelessWidget {
  const PlaceDetailHero({
    super.key,
    required this.place,
    required this.onReport,
    this.onBack,
  });

  final PlaceGuide place;
  final VoidCallback onReport;
  final VoidCallback? onBack;

  static const double _height = 300;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = onBack != null || Navigator.of(context).canPop();

    return SizedBox(
      height: _height + topInset,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PlaceCoverImage(
              place: place,
              height: _height + topInset,
              borderRadius: BorderRadius.zero,
              fallbackColorOpacity: 1,
              fallbackIconOpacity: 0.28,
              fallbackIconSize: 64,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x14000000),
                  Color(0x99000000),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            top: topInset + AtlasSpacing.sm,
            left: AtlasSpacing.md,
            right: AtlasSpacing.md,
            child: Row(
              children: [
                if (canPop)
                  _HeroActionChip(
                    child: IconButton(
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      tooltip: 'Retour',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                  ),
                const Spacer(),
                _HeroActionChip(
                  child: FavoriteToggleButton(
                    entityType: FavoriteEntityType.place,
                    entitySlug: place.id,
                  ),
                ),
                const SizedBox(width: AtlasSpacing.xs),
                _HeroActionChip(
                  child: IconButton(
                    onPressed: onReport,
                    tooltip: 'Signaler un problème',
                    icon: const Icon(Icons.flag_outlined),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AtlasSpacing.lg,
            right: AtlasSpacing.lg,
            bottom: AtlasSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AtlasSpacing.sm,
                  runSpacing: AtlasSpacing.xs,
                  children: [
                    _HeroChip(label: place.categoryLabel),
                    if (place.isEditorsPick)
                      const _HeroChip(
                        label: 'Sélection Atlas',
                        emphasized: true,
                      ),
                  ],
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  place.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  '${place.neighborhood} · ${place.cityName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.90),
                  ),
                ),
                if (place.priceLevel.trim().isNotEmpty) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    place.priceLevel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.sm,
        vertical: AtlasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? AtlasColors.terracotta.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconTheme(
        data: const IconThemeData(color: Colors.white, size: 22),
        child: child,
      ),
    );
  }
}
