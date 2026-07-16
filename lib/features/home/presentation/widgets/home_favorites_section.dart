import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../favorites/domain/favorite_entity_type.dart';

/// Entrée unifiée d'un favori résolu pour l'accueil.
class HomeFavoriteEntry {
  const HomeFavoriteEntry({
    required this.entityType,
    required this.entitySlug,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final FavoriteEntityType entityType;
  final String entitySlug;
  final String title;
  final String subtitle;
  final IconData icon;

  String get typeLabel => switch (entityType) {
        FavoriteEntityType.place => 'Lieu',
        FavoriteEntityType.procedure => 'Démarche',
        FavoriteEntityType.price => 'Prix',
      };
}

/// Liste compacte des favoris (lieux, démarches, prix).
class HomeFavoritesSection extends StatelessWidget {
  const HomeFavoritesSection({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  final List<HomeFavoriteEntry> entries;
  final ValueChanged<HomeFavoriteEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _FavoriteTile(
            entry: entries[i],
            onTap: () => onEntryTap(entries[i]),
          ),
          if (i < entries.length - 1) const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.entry,
    required this.onTap,
  });

  final HomeFavoriteEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: theme.colorScheme.primary),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  entry.typeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  entry.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Icon(
            Icons.chevron_right,
            color: AtlasColors.midnightBlueMuted.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
