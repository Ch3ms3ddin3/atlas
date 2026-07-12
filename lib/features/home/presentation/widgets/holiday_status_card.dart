import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte statut jour férié — information tertiaire du briefing.
class HolidayStatusCard extends StatelessWidget {
  const HolidayStatusCard({
    super.key,
    required this.data,
    this.onTap,
    this.compact = false,
  });

  final HolidayStatusData data;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = data.isHoliday
        ? AtlasColors.subtleGold
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65);

    return AtlasCard(
      onTap: onTap,
      emphasis: compact ? AtlasCardEmphasis.compact : AtlasCardEmphasis.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 16, color: accent),
              const SizedBox(width: AtlasSpacing.sm),
              Text(
                'Jour férié',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AtlasSpacing.md : AtlasSpacing.lg),
          Text(
            data.label,
            style: (compact
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            data.detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );
  }
}
