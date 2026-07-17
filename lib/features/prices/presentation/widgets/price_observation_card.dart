import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../data/price_observation_mapper.dart';
import '../../domain/models/price_observation.dart';
import 'price_confidence_chip.dart';
import 'price_verification_chip.dart';

/// Carte liste — prix courant mis en avant.
class PriceObservationCard extends StatelessWidget {
  const PriceObservationCard({
    super.key,
    required this.observation,
    required this.onTap,
    this.compact = false,
  });

  final PriceObservation observation;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      emphasis: compact ? AtlasCardEmphasis.compact : AtlasCardEmphasis.standard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            observation.category.icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AtlasSpacing.lg),
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
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  observation.locationLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  PriceObservationMapper.formatAmount(
                    observation.currentAmountMad,
                    currency: observation.currency,
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'par ${observation.unitLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Wrap(
                  spacing: AtlasSpacing.sm,
                  runSpacing: AtlasSpacing.xs,
                  children: [
                    PriceConfidenceChip(confidence: observation.confidence),
                    PriceVerificationChip(
                      status: observation.verificationStatus,
                    ),
                    if (observation.userReportsCount > 0)
                      Text(
                        '${observation.userReportsCount} signalement'
                        '${observation.userReportsCount > 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    PriceObservationMapper.formatLastUpdated(
                      observation.lastUpdatedAt,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
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
