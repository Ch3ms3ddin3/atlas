import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../domain/models/home_models.dart';

/// Carte des horaires de prière — seconde carte du briefing.
class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.data,
    this.onTap,
    this.animateEntrance = false,
    this.entranceDelay = Duration.zero,
  });

  final PrayerTimeData data;
  final VoidCallback? onTap;
  final bool animateEntrance;
  final Duration entranceDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      emphasis: AtlasCardEmphasis.standard,
      animateEntrance: animateEntrance,
      entranceDelay: entranceDelay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prière',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AtlasTextStyles.cardLabel(theme.colorScheme),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.nextPrayerName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
                child: AnimatedSwitcher(
                  duration: AtlasMotion.durationStandard,
                  switchInCurve: AtlasMotion.curveDefault,
                  switchOutCurve: AtlasMotion.curveExit,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Text(
                    data.nextPrayerCountdown,
                    key: ValueKey<String>(data.nextPrayerCountdown),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.lg),
          _PrayerScheduleRow(schedule: data.schedule),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            data.calculationMethod,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AtlasTextStyles.metadata(theme.colorScheme),
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
          if (i > 0) const SizedBox(width: AtlasSpacing.xs),
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
    final isCurrent = item.isCurrent;
    final isNext = item.isNext;
    final isHighlighted = isCurrent || isNext;

    return AnimatedContainer(
      duration: AtlasMotion.navAnimationDuration,
      curve: AtlasMotion.curveDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.xs,
        vertical: AtlasSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isCurrent
            ? AtlasColors.terracottaGhost
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(
                color: AtlasColors.terracottaMuted.withValues(alpha: 0.65),
              )
            : null,
      ),
      child: Column(
        children: [
          Text(
            item.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : AtlasTextStyles.helper(theme.colorScheme),
              fontWeight: isCurrent
                  ? FontWeight.w600
                  : isNext
                      ? FontWeight.w600
                      : FontWeight.w400,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            item.time,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isCurrent
                  ? FontWeight.w700
                  : isNext
                      ? FontWeight.w600
                      : FontWeight.w400,
              color: isCurrent
                  ? AtlasColors.midnightBlue
                  : isNext
                      ? AtlasColors.midnightBlue
                      : AtlasTextStyles.helper(theme.colorScheme),
            ),
          ),
          SizedBox(
            height: AtlasSpacing.sm,
            child: isNext
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
      ),
    );
  }
}
