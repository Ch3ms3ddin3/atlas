import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../data/price_observation_mapper.dart';
import '../../domain/models/price_observation.dart';
import '../widgets/price_confidence_chip.dart';
import '../widgets/price_verification_chip.dart';

/// Détail d'une observation vérifiée — prix courant dominant.
class PriceObservationDetailPage extends StatelessWidget {
  const PriceObservationDetailPage({
    super.key,
    required this.observation,
  });

  final PriceObservation observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(observation.itemName),
        actions: [
          FavoriteToggleButton(
            entityType: FavoriteEntityType.price,
            entitySlug: observation.id,
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
              Row(
                children: [
                  Icon(
                    observation.category.icon,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AtlasSpacing.md),
                  Expanded(
                    child: Text(
                      '${observation.category.labelFr} · ${observation.locationLabel}',
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
                PriceObservationMapper.formatAmount(
                  observation.currentAmountMad,
                  currency: observation.currency,
                ),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                'Prix actuel · ${observation.unitLabel}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (observation.hasRange) ...[
                const SizedBox(height: AtlasSpacing.xl),
                Text(
                  'Fourchette',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                _RangeRow(
                  label: 'Minimum',
                  amount: observation.minAmountMad,
                  currency: observation.currency,
                ),
                _RangeRow(
                  label: 'Moyenne',
                  amount: observation.avgAmountMad,
                  currency: observation.currency,
                ),
                _RangeRow(
                  label: 'Maximum',
                  amount: observation.maxAmountMad,
                  currency: observation.currency,
                ),
              ],
              const SizedBox(height: AtlasSpacing.xl),
              Wrap(
                spacing: AtlasSpacing.sm,
                runSpacing: AtlasSpacing.sm,
                children: [
                  PriceConfidenceChip(confidence: observation.confidence),
                  PriceVerificationChip(
                    status: observation.verificationStatus,
                  ),
                ],
              ),
              if (observation.userReportsCount > 0) ...[
                const SizedBox(height: AtlasSpacing.md),
                Text(
                  '${observation.userReportsCount} signalement'
                  '${observation.userReportsCount > 1 ? 's' : ''} '
                  'communautaire${observation.userReportsCount > 1 ? 's' : ''} '
                  '(agrégé, sans détail individuel).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AtlasSpacing.xl),
              Text(
                PriceObservationMapper.formatLastUpdated(
                  observation.lastUpdatedAt,
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                'Source : ${observation.source}',
                style: theme.textTheme.bodyMedium,
              ),
              if (observation.sourceUrl != null) ...[
                const SizedBox(height: AtlasSpacing.sm),
                TextButton.icon(
                  onPressed: () => _openSource(observation.sourceUrl!),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Voir la source'),
                ),
              ],
              const SizedBox(height: AtlasSpacing.section),
              Text(
                'Ces montants sont des observations vérifiées. '
                'Ils ne remplacent pas un devis ou un tarif officiel.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.label,
    required this.amount,
    required this.currency,
  });

  final String label;
  final double? amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = amount == null
        ? '—'
        : PriceObservationMapper.formatAmount(amount!, currency: currency);

    return Padding(
      padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
