import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/models/place_models.dart';

/// Détail d'un lieu — description, conseils et lien cartographique.
class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({
    super.key,
    required this.place,
  });

  final PlaceGuide place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          FavoriteToggleButton(
            entityType: FavoriteEntityType.place,
            entitySlug: place.id,
          ),
        ],
      ),
      body: SafeArea(
        child: AtlasContentContainer(
          child: ListView(
            padding: const EdgeInsets.only(
              top: AtlasSpacing.section,
              bottom: AtlasSpacing.sectionLarge,
            ),
            children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: place.imageColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
              ),
              child: Icon(
                _categoryIcon(place.category),
                size: 48,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${place.categoryLabel} · ${place.priceLevel}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (place.isEditorsPick)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.sm,
                      vertical: AtlasSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sélection Atlas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              '${place.neighborhood} · ${place.cityName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Text(
              place.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (place.bestTimeToVisit != null) ...[
              const SizedBox(height: AtlasSpacing.section),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Meilleur moment',
                value: place.bestTimeToVisit!,
              ),
            ],
            const SizedBox(height: AtlasSpacing.sectionLarge),
            Text(
              'Conseils pratiques',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            for (final tip in place.practicalTips) ...[
              _BulletItem(text: tip),
              const SizedBox(height: AtlasSpacing.sm),
            ],
            if (place.mapsUrl != null) ...[
              const SizedBox(height: AtlasSpacing.section),
              Text(
                'Voir sur Google Maps',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              SelectableText(
                place.mapsUrl!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(PlaceCategory category) {
    return switch (category) {
      PlaceCategory.jardin => Icons.park_outlined,
      PlaceCategory.monument => Icons.account_balance_outlined,
      PlaceCategory.restaurant => Icons.restaurant_outlined,
      PlaceCategory.cafe => Icons.coffee_outlined,
      PlaceCategory.musee => Icons.museum_outlined,
      PlaceCategory.hammam => Icons.spa_outlined,
      PlaceCategory.plage => Icons.beach_access_outlined,
      PlaceCategory.souk => Icons.storefront_outlined,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AtlasSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AtlasSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
