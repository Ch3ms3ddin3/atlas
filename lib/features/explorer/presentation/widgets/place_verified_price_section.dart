import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../prices/data/place_verified_price_links.dart';
import '../../../prices/data/price_observation_mapper.dart';
import '../../../prices/domain/models/price_observation.dart';
import '../../../prices/domain/price_intelligence_repository.dart';
import '../../../prices/presentation/pages/prices_page.dart';
import 'place_detail_section.dart';

/// Section calme « Tarif vérifié » — réutilise Price Intelligence (pas de copie).
class PlaceVerifiedPriceSection extends StatelessWidget {
  const PlaceVerifiedPriceSection({
    super.key,
    required this.placeId,
    this.repository,
  });

  final String placeId;
  final PriceIntelligenceRepository? repository;

  @override
  Widget build(BuildContext context) {
    final slugs = PlaceVerifiedPriceLinks.slugsForPlace(placeId);
    if (slugs.isEmpty) return const SizedBox.shrink();

    final PriceIntelligenceRepository? repo;
    try {
      repo = repository ?? PriceIntelligenceRepository();
    } on StateError {
      // Tests / early boot without Intelligence factory — hide section.
      return const SizedBox.shrink();
    }

    final observations = <PriceObservation>[
      for (final slug in slugs)
        if (repo.findById(slug) case final PriceObservation obs) obs,
    ];
    if (observations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceDetailSectionHeader(title: 'Tarif vérifié'),
        const SizedBox(height: AtlasSpacing.md),
        Text(
          'Montants issus de Price Intelligence — source officielle, '
          'aucune estimation Atlas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AtlasSpacing.md),
        for (var i = 0; i < observations.length; i++) ...[
          if (i > 0) const SizedBox(height: AtlasSpacing.sm),
          _VerifiedPriceRow(
            observation: observations[i],
            onTap: () => openPriceObservation(context, observations[i]),
          ),
        ],
      ],
    );
  }
}

class _VerifiedPriceRow extends StatelessWidget {
  const _VerifiedPriceRow({required this.observation, required this.onTap});

  final PriceObservation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = PriceObservationMapper.formatAmount(
      observation.currentAmountMad,
      currency: observation.currency,
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.lg,
            vertical: AtlasSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                observation.category.icon,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AtlasSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.itemName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${observation.unitLabel} · ${observation.verificationStatus.labelFr}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AtlasSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
