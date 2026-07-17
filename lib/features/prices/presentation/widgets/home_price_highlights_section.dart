import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../domain/models/price_observation.dart';
import 'price_observation_card.dart';

/// Section Accueil « Prix à la une » — masquée si vide (via HomeOptionalSection).
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
    return Column(
      children: [
        for (var i = 0; i < observations.length; i++) ...[
          PriceObservationCard(
            observation: observations[i],
            compact: true,
            onTap: () => onObservationTap(observations[i]),
          ),
          if (i < observations.length - 1)
            const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}
