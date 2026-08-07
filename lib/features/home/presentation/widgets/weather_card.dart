import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/weather_snapshot.dart';

/// Carte météo — température dominante et icône animée discrètement.
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
          SizedBox(height: AtlasSpacing.lg),
          AtlasSkeleton(height: 52, width: 140),
          SizedBox(height: AtlasSpacing.md),
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
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
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
        const SizedBox(height: AtlasSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.temperature}°',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w200,
                      letterSpacing: -3.2,
                      height: 0.88,
                      fontSize: 64,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    data.condition,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ressenti ${data.feelsLike}°',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AtlasTextStyles.helper(theme.colorScheme),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AtlasSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: AtlasSpacing.xs),
              child: _AnimatedWeatherIcon(icon: data.icon),
            ),
          ],
        ),
        if (data.hasWind || data.hasUv || data.hasRainProbability) ...[
          const SizedBox(height: AtlasSpacing.md),
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
        const SizedBox(height: AtlasSpacing.md),
        Text(
          data.lastUpdatedLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Source · $statusLabel',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme).withValues(
                  alpha: 0.85,
                ),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _AnimatedWeatherIcon extends StatefulWidget {
  const _AnimatedWeatherIcon({required this.icon});

  final IconData icon;

  @override
  State<_AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.78, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (AtlasMotion.reduceMotionOf(context)) {
      return Icon(
        widget.icon,
        size: 64,
        color: theme.colorScheme.primary.withValues(alpha: 0.8),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Icon(
        widget.icon,
        size: 64,
        color: theme.colorScheme.primary.withValues(alpha: 0.85),
      ),
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
