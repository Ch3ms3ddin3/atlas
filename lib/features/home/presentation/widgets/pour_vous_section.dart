import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/pour_vous/pour_vous_builder.dart';
import 'home_section_header.dart';

/// Section « Pour vous » — max 2 recommandations contextuelles légères.
class PourVousSection extends StatelessWidget {
  const PourVousSection({
    super.key,
    required this.recommendations,
  });

  final List<PourVousRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final visible = recommendations.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'Pour vous'),
        const SizedBox(height: AtlasSpacing.sm),
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: AtlasSpacing.sm),
          _PourVousItem(recommendation: visible[i]),
        ],
      ],
    );
  }
}

class _PourVousItem extends StatelessWidget {
  const _PourVousItem({required this.recommendation});

  final PourVousRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = recommendation.detail;

    return Row(
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
            recommendation.icon,
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
                recommendation.title,
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
    );
  }
}
