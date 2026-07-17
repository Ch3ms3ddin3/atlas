import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/weather_snapshot.dart';

/// Carte météo — carte principale du briefing, température mise en avant.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.snapshot,
    this.animateEntrance = false,
    this.entranceDelay = Duration.zero,
  });

  final WeatherSnapshot snapshot;
  final bool animateEntrance;
  final Duration entranceDelay;

  @override
  Widget build(BuildContext context) {
    return AtlasCard(
      emphasis: AtlasCardEmphasis.primary,
      animateEntrance: animateEntrance,
      entranceDelay: entranceDelay,
      child: AtlasFadeSwitcher(
        child: KeyedSubtree(
          key: ValueKey(snapshot.state),
          child: switch (snapshot.state) {
            WeatherLoadState.loading => const _LoadingBody(),
            WeatherLoadState.unavailable => const _UnavailableBody(),
            WeatherLoadState.success ||
            WeatherLoadState.stale =>
              _ReadyBody(
                data: snapshot.data!,
                statusLabel: snapshot.statusLabel,
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement de la météo…',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasSkeleton(height: 14, width: 90),
          SizedBox(height: AtlasSpacing.md),
          AtlasSkeleton(height: 36, width: 120),
          SizedBox(height: AtlasSpacing.sm),
          AtlasSkeleton(height: 12, width: 160),
        ],
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Météo',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AtlasTextStyles.cardLabel(theme.colorScheme),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AtlasSpacing.lg),
        Icon(
          Icons.cloud_off_outlined,
          size: 36,
          color: AtlasColors.midnightBlueFaint,
        ),
        const SizedBox(height: AtlasSpacing.md),
        Text(
          'Météo indisponible',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          'Météo indisponible pour cette ville. '
          'Tirez pour actualiser lorsque vous êtes en ligne.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
            height: 1.4,
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
  });

  final WeatherData data;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Météo',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AtlasTextStyles.cardLabel(theme.colorScheme),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AtlasSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.temperature}°',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.md),
                  Text(
                    data.condition,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    'Ressenti ${data.feelsLike}°',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AtlasTextStyles.helper(theme.colorScheme),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AtlasSpacing.md),
            Icon(
              data.icon,
              size: 70,
              color: theme.colorScheme.primary.withValues(alpha: 0.75),
            ),
          ],
        ),
        if (data.hasWind || data.hasUv || data.hasRainProbability) ...[
          const SizedBox(height: AtlasSpacing.lg),
          Wrap(
            spacing: AtlasSpacing.md,
            runSpacing: AtlasSpacing.sm,
            children: [
              if (data.hasWind)
                _MetricChip(
                  icon: Icons.air,
                  label: '${data.windKmh!.round()} km/h',
                ),
              if (data.hasUv)
                _MetricChip(
                  icon: Icons.wb_sunny_outlined,
                  label: 'UV ${data.uvIndex!.round()}',
                ),
              if (data.hasRainProbability)
                _MetricChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Pluie ${data.rainProbabilityPercent}%',
                ),
            ],
          ),
        ],
        const SizedBox(height: AtlasSpacing.lg),
        Text(
          statusLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          data.lastUpdatedLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AtlasTextStyles.helper(theme.colorScheme),
        ),
        const SizedBox(width: AtlasSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
          ),
        ),
      ],
    );
  }
}
