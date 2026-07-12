import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte des horaires de prière — seconde carte du briefing.
class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final PrayerTimeData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      emphasis: AtlasCardEmphasis.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prière',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.nextPrayerName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
                child: Text(
                  data.nextPrayerCountdown,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.xl),
          _PrayerScheduleRow(schedule: data.schedule),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            data.calculationMethod,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerScheduleRow extends StatelessWidget {
  const _PrayerScheduleRow({required this.schedule});

  final List<PrayerScheduleItem> schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (var i = 0; i < schedule.length; i++) ...[
          if (i > 0) const SizedBox(width: AtlasSpacing.sm),
          Expanded(
            child: _PrayerScheduleCell(
              item: schedule[i],
              theme: theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _PrayerScheduleCell extends StatelessWidget {
  const _PrayerScheduleCell({
    required this.item,
    required this.theme,
  });

  final PrayerScheduleItem item;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = item.isNext || item.isCurrent;

    return Column(
      children: [
        Text(
          item.name,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontWeight: item.isNext ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          item.time,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: item.isNext ? FontWeight.w600 : FontWeight.w400,
            color: item.isNext
                ? AtlasColors.midnightBlue
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(
          height: AtlasSpacing.sm,
          child: item.isNext
              ? Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
