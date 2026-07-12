import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte admission temporaire — suivi du document véhicule importé.
class AdmissionTemporaireCard extends StatelessWidget {
  const AdmissionTemporaireCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final AdmissionTemporaireData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = data.daysRemaining / data.totalDays;

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administratif',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Text(
            data.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.daysRemaining}',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
                child: Text(
                  'jours restants',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AtlasColors.sandMuted.withValues(alpha: 0.6),
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            data.expiryLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
