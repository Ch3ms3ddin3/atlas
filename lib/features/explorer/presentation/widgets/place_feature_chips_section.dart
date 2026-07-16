import 'package:flutter/material.dart';

import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import 'place_detail_section.dart';

/// Liste de puces (accessibilité ou équipements) — masquée si vide.
class PlaceFeatureChipsSection extends StatelessWidget {
  const PlaceFeatureChipsSection({
    super.key,
    required this.title,
    required this.features,
  });

  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlaceDetailSectionHeader(title: title),
        Wrap(
          spacing: AtlasSpacing.sm,
          runSpacing: AtlasSpacing.sm,
          children: [
            for (final feature in features)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.md,
                  vertical: AtlasSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AtlasColors.sandMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  feature,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AtlasColors.midnightBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
