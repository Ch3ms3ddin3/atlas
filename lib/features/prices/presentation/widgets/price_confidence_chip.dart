import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/price_observation.dart';

/// Pastille de confiance agrégée.
class PriceConfidenceChip extends StatelessWidget {
  const PriceConfidenceChip({
    super.key,
    required this.confidence,
  });

  final PriceConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (confidence) {
      PriceConfidence.high => AtlasColors.success,
      PriceConfidence.medium => AtlasColors.warning,
      PriceConfidence.low => AtlasColors.info,
    };

    return Semantics(
      label: confidence.labelFr,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.md,
          vertical: AtlasSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          confidence.labelFr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
