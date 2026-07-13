import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../data/price_mapper.dart';
import '../../domain/models/price_models.dart';
import 'price_tourist_trap_banner.dart';

/// Carte résumé d'un prix moyen dans la liste.
class PriceGuideCard extends StatelessWidget {
  const PriceGuideCard({
    super.key,
    required this.guide,
    required this.onTap,
  });

  final PriceGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            guide.icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (guide.isTouristTrap) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  const PriceTouristTrapBanner(),
                ],
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  _locationLabel(guide),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  guide.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  '${PriceMapper.formatRange(guide)} · ${guide.unitLabel}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  PriceMapper.formatLastUpdated(guide.lastUpdatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtlasSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PriceMapper.formatAmount(guide.averageAmountMad),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _locationLabel(PriceGuide guide) {
    if (guide.isNational) {
      return '${guide.categoryLabel} · National';
    }
    return '${guide.categoryLabel} · ${guide.cityName}';
  }
}
