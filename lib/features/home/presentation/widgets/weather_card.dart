import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte météo — carte principale du briefing, température mise en avant.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final WeatherData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      '${data.temperature}°',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w200,
                        letterSpacing: -2,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),
                    Text(
                      data.condition,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.xs),
                    Text(
                      'Ressenti ${data.feelsLike}°',
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
                color: theme.colorScheme.primary.withValues(alpha: 0.75),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Text(
            'Mis à jour ${data.updatedAt}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
