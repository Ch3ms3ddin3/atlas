import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/daily_insight/daily_insight_builder.dart';

/// Pied de page éditorial — une seule phrase utile.
class DailyInsightSection extends StatelessWidget {
  const DailyInsightSection({
    super.key,
    required this.data,
  });

  final DailyInsightData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Bon à savoir : ${data.message}',
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
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            data.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              letterSpacing: -0.05,
              color: AtlasTextStyles.helper(theme.colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}
