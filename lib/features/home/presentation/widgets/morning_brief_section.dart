import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_fade_switcher.dart';
import '../../../../design_system/widgets/atlas_skeleton.dart';
import '../../data/morning_brief/morning_brief_builder.dart';

/// Briefing compact « Aujourd'hui à… » — une composition scannable.
class MorningBriefSection extends StatelessWidget {
  const MorningBriefSection({super.key, required this.data, this.onEventsTap});

  final MorningBriefData data;

  /// Ouvre l'agenda lorsque la ligne événements est touchée.
  final VoidCallback? onEventsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasFadeSwitcher(
      child: KeyedSubtree(
        key: ValueKey(data.isLoading),
        child: data.isLoading
            ? _LoadingBody(title: data.title)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AtlasColors.surfaceWhite.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(
                        AtlasSpacing.cardRadius,
                      ),
                      border: Border.all(
                        color: AtlasColors.sandMuted.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AtlasSpacing.lg,
                        AtlasSpacing.md,
                        AtlasSpacing.lg,
                        AtlasSpacing.md,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < data.lines.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _BriefLine(
                              line: data.lines[i],
                              onTap:
                                  data.lines[i].action ==
                                      MorningBriefAction.events
                                  ? onEventsTap
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BriefLine extends StatelessWidget {
  const _BriefLine({required this.line, this.onTap});

  final MorningBriefLine line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              line.emoji,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1),
            ),
          ),
        ),
        const SizedBox(width: AtlasSpacing.sm),
        Expanded(
          child: Text(
            line.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              height: 1.2,
              color: theme.colorScheme.onSurface,
              decoration: onTap == null ? null : TextDecoration.underline,
              decorationColor: AtlasColors.midnightBlueMuted.withValues(
                alpha: 0.35,
              ),
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AtlasTextStyles.helper(theme.colorScheme),
          ),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AtlasSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AtlasColors.surfaceWhite.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
            border: Border.all(
              color: AtlasColors.sandMuted.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AtlasSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  Row(
                    children: [
                      const AtlasSkeleton(height: 14, width: 18),
                      const SizedBox(width: AtlasSpacing.sm),
                      Expanded(
                        child: AtlasSkeleton(
                          height: 12,
                          width: i.isEven ? double.infinity : 140,
                        ),
                      ),
                    ],
                  ),
                  if (i < 4) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AtlasSpacing.xs),
        Text(
          'Préparation du briefing…',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AtlasTextStyles.metadata(theme.colorScheme),
          ),
        ),
      ],
    );
  }
}
