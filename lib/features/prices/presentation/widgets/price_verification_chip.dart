import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/price_observation.dart';

/// Statut de vérification — distinct de la confiance.
class PriceVerificationChip extends StatelessWidget {
  const PriceVerificationChip({
    super.key,
    required this.status,
  });

  final PriceVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      PriceVerificationStatus.verified => AtlasColors.success,
      PriceVerificationStatus.pending => AtlasColors.warning,
      PriceVerificationStatus.unverified => AtlasColors.info,
    };

    return Semantics(
      label: 'Vérification ${status.labelFr}',
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
          status.labelFr,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
