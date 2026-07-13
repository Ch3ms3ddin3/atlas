import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/price_mapper.dart';
import '../../domain/models/price_models.dart';
import '../widgets/price_detail_section.dart';
import '../widgets/price_disclaimer_banner.dart';
import '../widgets/price_tourist_trap_banner.dart';

/// Détail d'un prix moyen — fourchette, contexte et conseils.
class PriceDetailPage extends StatelessWidget {
  const PriceDetailPage({
    super.key,
    required this.guide,
  });

  final PriceGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(guide.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtlasSpacing.pageHorizontal,
            AtlasSpacing.section,
            AtlasSpacing.pageHorizontal,
            AtlasSpacing.sectionLarge,
          ),
          children: [
            if (guide.isTouristTrap) ...[
              const PriceTouristTrapBanner(),
              const SizedBox(height: AtlasSpacing.lg),
            ],
            Row(
              children: [
                Icon(
                  guide.icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AtlasSpacing.md),
                Expanded(
                  child: Text(
                    _locationLabel(guide),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Text(
              PriceMapper.formatRange(guide),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xs),
            Text(
              guide.unitLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            Text(
              'Repère : ${PriceMapper.formatAmount(guide.averageAmountMad)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Text(
              'Fourchette normale',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              guide.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sectionLarge),
            PriceDetailSection(
              title: 'Ce qui fait varier le prix',
              items: guide.priceFactors,
            ),
            const SizedBox(height: AtlasSpacing.section),
            PriceDetailSection(
              title: 'Signaux d\'alerte',
              items: guide.warningSigns,
            ),
            const SizedBox(height: AtlasSpacing.section),
            PriceDetailSection(
              title: 'Conseils de négociation',
              items: guide.negotiationTips,
            ),
            const SizedBox(height: AtlasSpacing.sectionLarge),
            Text(
              PriceMapper.formatLastUpdated(guide.lastUpdatedAt),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (guide.sourceNote != null) ...[
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                'Source : ${guide.sourceNote}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AtlasSpacing.section),
            Text(
              PriceDisclaimerBanner.text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ],
        ),
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
