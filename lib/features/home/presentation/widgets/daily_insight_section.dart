import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/daily_insight/daily_insight_builder.dart';

/// Conseil unique « Bon à savoir » — masqué si [data] est null.
class DailyInsightSection extends StatelessWidget {
  const DailyInsightSection({super.key, required this.data});

  final DailyInsightData? data;

  @override
  Widget build(BuildContext context) {
    final tip = data;
    if (tip == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final detail = tip.detail;

    return Semantics(
      label: 'Bon à savoir : ${tip.message}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bon à savoir',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              height: 1.2,
              color: AtlasColors.subtleGold,
            ),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AtlasColors.subtleGoldMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  tip.icon,
                  size: 16,
                  color: AtlasColors.midnightBlue.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: AtlasTextStyles.helper(theme.colorScheme),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
