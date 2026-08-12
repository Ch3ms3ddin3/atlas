import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../data/price_observation_mapper.dart';
import '../../domain/models/price_observation.dart';

/// Aperçu Accueil « Prix utiles » — lignes compactes, pas les cartes Prix.
class HomePriceHighlightsSection extends StatelessWidget {
  const HomePriceHighlightsSection({
    super.key,
    required this.observations,
    required this.onObservationTap,
  });

  final List<PriceObservation> observations;
  final ValueChanged<PriceObservation> onObservationTap;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AtlasColors.surfaceWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        border: Border.all(
          color: AtlasColors.sandMuted.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < observations.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AtlasColors.sandMuted.withValues(alpha: 0.45),
              ),
            _HomePricePreviewRow(
              observation: observations[i],
              onTap: () => onObservationTap(observations[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomePricePreviewRow extends StatelessWidget {
  const _HomePricePreviewRow({required this.observation, required this.onTap});

  final PriceObservation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = PriceObservationMapper.formatAmount(
      observation.currentAmountMad,
      currency: observation.currency,
    );
    final verified =
        observation.verificationStatus == PriceVerificationStatus.verified;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.lg,
            vertical: AtlasSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                observation.category.icon,
                size: 20,
                color: AtlasColors.midnightBlue.withValues(alpha: 0.72),
              ),
              const SizedBox(width: AtlasSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verified
                          ? 'Vérifié · ${observation.category.labelFr}'
                          : observation.category.labelFr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: verified
                            ? AtlasColors.success
                            : AtlasTextStyles.helper(theme.colorScheme),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AtlasTextStyles.helper(theme.colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
