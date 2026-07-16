import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../prices/domain/models/price_models.dart';
import '../../../prices/presentation/widgets/price_guide_card.dart';

/// Repères de prix utiles sur l'accueil.
class HomePriceIndicatorsSection extends StatelessWidget {
  const HomePriceIndicatorsSection({
    super.key,
    required this.guides,
    required this.onGuideTap,
  });

  final List<PriceGuide> guides;
  final ValueChanged<PriceGuide> onGuideTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < guides.length; i++) ...[
          PriceGuideCard(
            guide: guides[i],
            onTap: () => onGuideTap(guides[i]),
          ),
          if (i < guides.length - 1) const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}
