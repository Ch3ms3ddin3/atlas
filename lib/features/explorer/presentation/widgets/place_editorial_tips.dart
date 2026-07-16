import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_spacing.dart';
import 'place_detail_section.dart';

/// Conseils pratiques éditoriaux.
class PlaceEditorialTips extends StatelessWidget {
  const PlaceEditorialTips({
    super.key,
    required this.tips,
  });

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlaceDetailSectionHeader(title: 'Conseils pratiques'),
        for (var i = 0; i < tips.length; i++) ...[
          if (i > 0) const SizedBox(height: AtlasSpacing.sm),
          PlaceBulletItem(text: tips[i]),
        ],
      ],
    );
  }
}
