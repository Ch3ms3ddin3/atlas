import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/prayer_times_snapshot.dart';

/// Carte des horaires de prière — prochaine prière mise en avant.
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
          SizedBox(height: AtlasSpacing.lg),
          AtlasSkeleton(height: 40, width: 180),
          SizedBox(height: AtlasSpacing.md),
          AtlasSkeleton(height: 12, width: double.infinity),
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
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
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
          'Tirez pour actualiser lorsque vous êtes en ligne.',
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
          'Prochaine prière',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AtlasTextStyles.cardLabel(theme.colorScheme),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AtlasSpacing.md),
        Text(
          data.nextPrayerName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.35,
            height: 1.05,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        AnimatedSwitcher(
          duration: AtlasMotion.contentSwapDuration,
          switchInCurve: AtlasMotion.curveDefault,
          switchOutCurve: AtlasMotion.curveExit,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Text(
            data.nextPrayerCountdown,
            key: ValueKey<String>(data.nextPrayerCountdown),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w300,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: AtlasSpacing.lg),
        Text(
          'Horaires du jour',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        _PrayerScheduleRow(schedule: data.schedule),
        const SizedBox(height: AtlasSpacing.sm),
        Text(
          statusLabel.isEmpty ? 'Source · horaires locaux' : statusLabel,
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
    final isNext = item.isNext;

    return AnimatedContainer(
      duration: AtlasMotion.contentSwapDuration,
      curve: AtlasMotion.curveDefault,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: AtlasSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isNext
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isNext
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              )
            : null,
      ),
      child: Column(
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isNext
                  ? theme.colorScheme.primary
                  : AtlasTextStyles.helper(theme.colorScheme),
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
              color: isNext
                  ? theme.colorScheme.onSurface
                  : AtlasTextStyles.helper(theme.colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}
