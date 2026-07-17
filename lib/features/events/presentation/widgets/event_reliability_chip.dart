import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/atlas_event.dart';

/// Pastille de fiabilité — ne jamais confondre Estimé / Provisoire / Confirmé.
class EventReliabilityChip extends StatelessWidget {
  const EventReliabilityChip({
    super.key,
    required this.reliability,
  });

  final EventReliability reliability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (reliability) {
      EventReliability.confirmed => AtlasColors.success,
      EventReliability.provisional => AtlasColors.warning,
      EventReliability.estimated => AtlasColors.info,
    };

    return Semantics(
      label: 'Statut ${reliability.labelFr}',
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
          reliability.labelFr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
