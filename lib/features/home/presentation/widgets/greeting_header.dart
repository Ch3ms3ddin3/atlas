import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/home_models.dart';

/// En-tête d'accueil — salutation premium, ancrée au Maroc, lisible en un regard.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.data,
  });

  final GreetingData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceMuted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent discret — terre cuite, ancrage visuel marocain sans bruit.
        Container(
          width: 32,
          height: 2,
          color: AtlasColors.terracotta.withValues(alpha: 0.9),
        ),
        const SizedBox(height: AtlasSpacing.xl),
        Text(
          'Bonjour ${data.userName}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -1.2,
            height: 1.08,
            color: onSurface,
          ),
        ),
        const SizedBox(height: AtlasSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              data.city,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: 1.6,
                height: 1.4,
                fontFeatures: const [FontFeature.enable('smcp')],
                color: onSurfaceMuted.withValues(alpha: 0.82),
              ),
            ),
            Text(
              ' · Maroc',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0.8,
                height: 1.4,
                color: onSurfaceMuted.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          data.dateLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
            height: 1.35,
            color: onSurfaceMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
