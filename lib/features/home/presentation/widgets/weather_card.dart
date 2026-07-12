import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte météo — carte principale du briefing, température mise en avant.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.data,
    this.isLoading = false,
    this.onTap,
  });

  final WeatherData data;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temperatureLabel = isLoading ? '—°' : '${data.temperature}°';
    final conditionLabel = isLoading ? 'Chargement…' : data.condition;
    final feelsLikeLabel =
        isLoading ? 'Ressenti —°' : 'Ressenti ${data.feelsLike}°';
    final updatedAtLabel =
        isLoading ? 'Mise à jour en cours' : 'Mis à jour ${data.updatedAt}';

    return AtlasCard(
      onTap: onTap,
      emphasis: AtlasCardEmphasis.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Météo',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temperatureLabel,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w200,
                        letterSpacing: -2,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    Text(
                      conditionLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.xs),
                    Text(
                      feelsLikeLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                data.icon,
                size: 56,
                color: theme.colorScheme.primary
                    .withValues(alpha: isLoading ? 0.35 : 0.75),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Text(
            updatedAtLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
