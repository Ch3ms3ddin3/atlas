import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/price_mapper.dart';
import '../../domain/models/price_models.dart';

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
                    '${guide.categoryLabel} · ${guide.cityName}',
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
              PriceMapper.formatAmount(guide.averageAmountMad),
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
            const SizedBox(height: AtlasSpacing.lg),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Fourchette observée',
              value: guide.rangeLabel,
            ),
            const SizedBox(height: AtlasSpacing.xl),
            Text(
              guide.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sectionLarge),
            Text(
              'Conseils pratiques',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            for (final tip in guide.practicalTips) ...[
              _BulletItem(text: tip),
              const SizedBox(height: AtlasSpacing.sm),
            ],
            const SizedBox(height: AtlasSpacing.section),
            Text(
              'Estimation indicative Atlas — les prix varient selon le quartier '
              'et la saison.',
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
