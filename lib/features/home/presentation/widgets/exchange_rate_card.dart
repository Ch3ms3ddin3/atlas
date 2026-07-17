import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/home_models.dart';

/// Carte de taux de change — information tertiaire du briefing.
class ExchangeRateCard extends StatelessWidget {
  const ExchangeRateCard({
    super.key,
    required this.snapshot,
    this.compact = false,
  });

  final ExchangeRateSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      emphasis: compact ? AtlasCardEmphasis.compact : AtlasCardEmphasis.standard,
      child: AtlasFadeSwitcher(
        child: KeyedSubtree(
          key: ValueKey(snapshot.state),
          child: switch (snapshot.state) {
            ExchangeRateLoadState.loading => _LoadingBody(compact: compact),
            ExchangeRateLoadState.unavailable =>
              _UnavailableBody(compact: compact),
            ExchangeRateLoadState.success ||
            ExchangeRateLoadState.stale =>
              _ReadyBody(
                data: snapshot.data!,
                statusLabel: snapshot.statusLabel,
                compact: compact,
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement du taux…',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AtlasSkeleton(height: 12, width: 64),
          SizedBox(height: compact ? AtlasSpacing.md : AtlasSpacing.lg),
          const AtlasSkeleton(height: 18, width: 120),
          const SizedBox(height: AtlasSpacing.sm),
          const AtlasSkeleton(height: 12, width: 80),
        ],
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        Icon(
          Icons.cloud_off_outlined,
          size: 22,
          color: AtlasColors.midnightBlueFaint,
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          'Taux indisponible',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          'Tirez pour actualiser lorsque vous êtes en ligne.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.data,
    required this.statusLabel,
    required this.compact,
  });

  final ExchangeRateData data;
  final String statusLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reverse = data.madToEur;

    return Column(
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
        Text(
          '1 ${data.toCurrency} ≈ ${reverse.toStringAsFixed(4)} ${data.fromCurrency}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
          ),
        ),
        SizedBox(height: compact ? AtlasSpacing.sm : AtlasSpacing.md),
        Text(
          statusLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          data.lastUpdatedLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
