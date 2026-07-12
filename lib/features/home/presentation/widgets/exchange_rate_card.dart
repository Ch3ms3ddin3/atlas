import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte de taux de change — information tertiaire du briefing.
class ExchangeRateCard extends StatelessWidget {
  const ExchangeRateCard({
    super.key,
    required this.data,
    this.onTap,
    this.compact = false,
  });

  final ExchangeRateData data;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = data.isTrendingUp
        ? const Color(0xFF2E7D4F)
        : AtlasColors.midnightBlueMuted;

    return AtlasCard(
      onTap: onTap,
      emphasis: compact ? AtlasCardEmphasis.compact : AtlasCardEmphasis.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: compact ? AtlasSpacing.md : AtlasSpacing.lg),
          Text(
            '1 ${data.fromCurrency}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            '${data.rate.toStringAsFixed(2)} ${data.toCurrency}',
            style: (compact
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: compact ? AtlasSpacing.sm : AtlasSpacing.md),
          Row(
            children: [
              Icon(
                data.isTrendingUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: trendColor,
              ),
              const SizedBox(width: AtlasSpacing.xs),
              Flexible(
                child: Text(
                  data.trendLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: trendColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
