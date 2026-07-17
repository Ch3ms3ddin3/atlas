import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/prayer_times_snapshot.dart';

/// Carte des horaires de prière — seconde carte du briefing.
class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.snapshot,
    this.onTap,
    this.animateEntrance = false,
    this.entranceDelay = Duration.zero,
  });

  final PrayerTimesSnapshot snapshot;
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
      child: AtlasFadeSwitcher(
        child: KeyedSubtree(
          key: ValueKey(snapshot.state),
          child: switch (snapshot.state) {
            PrayerLoadState.loading => const _LoadingBody(),
            PrayerLoadState.unavailable => _UnavailableBody(theme: theme),
            PrayerLoadState.success ||
            PrayerLoadState.stale =>
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
      label: 'Chargement des horaires…',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasSkeleton(height: 12, width: 72),
          SizedBox(height: AtlasSpacing.md),
          AtlasSkeleton(height: 16, width: 140),
          SizedBox(height: AtlasSpacing.sm),
          AtlasSkeleton(height: 12, width: 100),
        ],
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Icon(
          Icons.cloud_off_outlined,
          size: 28,
          color: AtlasColors.midnightBlueFaint,
        ),
        const SizedBox(height: AtlasSpacing.md),
        Text(
          'Horaires indisponibles',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          'Impossible de charger les horaires pour cette ville. '
          'Réessayez avec une connexion ou tirez pour actualiser.',
          style: theme.textTheme.bodySmall?.copyWith(
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

  final PrayerTimeData data;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
          statusLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
        ),
      ],
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
        color: isCurrent ? AtlasColors.terracottaGhost : Colors.transparent,
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
